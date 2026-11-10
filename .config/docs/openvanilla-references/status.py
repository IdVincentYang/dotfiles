#!/usr/bin/env python3
"""Read macOS Secure Input and optionally the existing input menu source IDs.

No configuration changes, input events, source selection, app termination or
network access. The optional private TIM query runs in a bounded subprocess.
TIM message 22 was inspected and used during diagnosis on macOS 27.0.1.
"""

import argparse
import ctypes as C
import datetime
import json
import platform
import re
import subprocess
import sys
from pathlib import Path


HITOOLBOX = (
    "/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/"
    "HIToolbox.framework/Versions/A/HIToolbox"
)
MENU_UI = "/System/Library/PrivateFrameworks/TextInputMenuUI.framework/TextInputMenuUI"
REVIEWED_MENU_VERSIONS = frozenset({"27.0.1"})


def unknown(reason):
    return {"status": "unknown", "reason": reason}


def load_hitoolbox():
    hit = C.CDLL(HITOOLBOX)
    hit.IsSecureEventInputEnabled.argtypes = []
    hit.IsSecureEventInputEnabled.restype = C.c_bool
    return hit


def query_menu():
    """Request existing non-disabled menu source IDs with read-only message 22."""
    if platform.mac_ver()[0] not in REVIEWED_MENU_VERSIONS:
        return unknown("private_menu_query_unreviewed_macos_version")
    ui = C.CDLL(MENU_UI)
    objc = C.CDLL("/usr/lib/libobjc.A.dylib")
    for name, args, result_type in [
        ("objc_getClass", [C.c_char_p], C.c_void_p),
        ("sel_registerName", [C.c_char_p], C.c_void_p),
        ("objc_allocateClassPair", [C.c_void_p, C.c_char_p, C.c_size_t], C.c_void_p),
        ("class_addMethod", [C.c_void_p, C.c_void_p, C.c_void_p, C.c_char_p], C.c_bool),
        ("objc_registerClassPair", [C.c_void_p], None),
        ("class_getClassMethod", [C.c_void_p, C.c_void_p], C.c_void_p),
        ("method_getTypeEncoding", [C.c_void_p], C.c_char_p),
    ]:
        function = getattr(objc, name)
        function.argtypes = args
        function.restype = result_type

    def sel(name):
        return objc.sel_registerName(name.encode())

    handler = objc.objc_getClass(b"TSMMessageHandler")
    pool_class = objc.objc_getClass(b"NSAutoreleasePool")
    base_class = objc.objc_getClass(b"NSObject")
    string_class = objc.objc_getClass(b"NSString")
    if not all((handler, pool_class, base_class, string_class)):
        return unknown("required_objc_class_missing")

    query_selector = sel("messageTIMCore:dictionary:withReply:")
    method = objc.class_getClassMethod(handler, query_selector)
    if not method:
        return unknown("menu_query_method_missing")
    encoding = objc.method_getTypeEncoding(method)
    signature = re.sub(r"\d+", "", encoding.decode()) if encoding else ""
    if signature not in ("B@:i@@", "c@:i@@"):
        return unknown("menu_query_signature_changed")

    address = C.cast(objc.objc_msgSend, C.c_void_p).value
    msg = C.CFUNCTYPE(C.c_void_p, C.c_void_p, C.c_void_p)(address)
    msg1 = C.CFUNCTYPE(C.c_void_p, C.c_void_p, C.c_void_p, C.c_void_p)(address)
    msgstr = C.CFUNCTYPE(C.c_void_p, C.c_void_p, C.c_void_p, C.c_char_p)(address)
    msgidx = C.CFUNCTYPE(C.c_void_p, C.c_void_p, C.c_void_p, C.c_ulong)(address)
    getcount = C.CFUNCTYPE(C.c_ulong, C.c_void_p, C.c_void_p)(address)
    getchars = C.CFUNCTYPE(C.c_char_p, C.c_void_p, C.c_void_p)(address)
    send_query = C.CFUNCTYPE(
        C.c_bool, C.c_void_p, C.c_void_p, C.c_int32, C.c_void_p, C.c_void_p
    )(address)

    def call(obj, name):
        return msg(obj, sel(name))

    class PSN(C.Structure):
        _fields_ = [("high", C.c_uint32), ("low", C.c_uint32)]

    hit = load_hitoolbox()
    hit.GetFrontProcess.argtypes = [C.POINTER(PSN)]
    hit.GetFrontProcess.restype = C.c_int32
    hit.GetProcessPID.argtypes = [C.POINTER(PSN), C.POINTER(C.c_int32)]
    hit.GetProcessPID.restype = C.c_int32

    def context():
        psn = PSN()
        front_status = hit.GetFrontProcess(C.byref(psn))
        pid = C.c_int32()
        pid_status = (
            hit.GetProcessPID(C.byref(psn), C.byref(pid))
            if front_status == 0
            else front_status
        )
        return {
            "utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "front_pid": pid.value if pid_status == 0 else None,
            "secure_event_input": bool(hit.IsSecureEventInputEnabled()),
        }

    result = {"status": "unknown", "reply_received": False, "source_ids": None}

    @C.CFUNCTYPE(None, C.c_void_p, C.c_void_p, C.c_int32, C.c_void_p)
    def receive(_self, _selector, message_id, dictionary):
        try:
            result["reply_received"] = True
            result["message_id"] = message_id
            if message_id != 22:
                result["reason"] = "unexpected_menu_reply_id"
                return
            key = msgstr(
                string_class, sel("stringWithUTF8String:"), b"tsmEnabledInputSourceIDs"
            )
            array = msg1(dictionary, sel("objectForKey:"), key) if dictionary else None
            if not array:
                result["reason"] = "menu_source_ids_missing"
                return
            ids = []
            for index in range(getcount(array, sel("count"))):
                value = msgidx(array, sel("objectAtIndex:"), index)
                chars = getchars(value, sel("UTF8String"))
                if not chars:
                    result["reason"] = "invalid_menu_source_id"
                    return
                ids.append(chars.decode())
            result["source_ids"] = ids
        except Exception as error:
            result["reason"] = type(error).__name__

    pool = call(pool_class, "new")
    receiver = None
    try:
        receiver_class = objc.objc_allocateClassPair(
            base_class, b"LocalReadOnlyTIMSourceIDsReply", 0
        )
        if not receiver_class:
            return unknown("reply_class_creation_failed")
        added = objc.class_addMethod(
            receiver_class,
            sel("replyReceiver:withInfo:"),
            C.cast(receive, C.c_void_p),
            b"v28@0:8i16@20",
        )
        if not added:
            return unknown("reply_method_creation_failed")
        objc.objc_registerClassPair(receiver_class)
        receiver = call(receiver_class, "new")
        result["query_before"] = context()
        result["transport_ok"] = bool(
            send_query(handler, query_selector, 22, None, receiver)
        )
        result["query_after"] = context()
        if (
            result["transport_ok"]
            and result["reply_received"]
            and result["source_ids"] is not None
        ):
            result["status"] = "ok"
        else:
            result.setdefault("reason", "menu_query_did_not_return_source_ids")
        return result
    finally:
        if receiver:
            call(receiver, "release")
        call(pool, "drain")


def menu_subprocess():
    if platform.mac_ver()[0] not in REVIEWED_MENU_VERSIONS:
        return unknown("private_menu_query_unreviewed_macos_version")
    try:
        completed = subprocess.run(
            [sys.executable, str(Path(__file__).resolve()), "--_menu-query"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        if completed.returncode != 0:
            return unknown("menu_query_process_failed")
        result = json.loads(completed.stdout)
        return result if isinstance(result, dict) else unknown("invalid_menu_response")
    except subprocess.TimeoutExpired:
        return unknown("menu_query_timeout")
    except (OSError, ValueError):
        return unknown("menu_query_unavailable")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--menu", action="store_true", help="query the existing menu using a private API"
    )
    parser.add_argument("--_menu-query", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if sys.platform != "darwin":
        print(json.dumps(unknown("macos_only")))
        return 2

    if args._menu_query:
        try:
            result = query_menu()
        except Exception as error:
            result = unknown(type(error).__name__)
        print(json.dumps(result, ensure_ascii=False))
        return 0

    result = {
        "status": "unknown",
        "utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "secure_event_input_before": None,
        "secure_event_input_after": None,
        "state_changed": None,
    }
    try:
        hit = load_hitoolbox()
        result["secure_event_input_before"] = bool(hit.IsSecureEventInputEnabled())
        if args.menu:
            result["menu"] = menu_subprocess()
        result["secure_event_input_after"] = bool(hit.IsSecureEventInputEnabled())
        result["state_changed"] = (
            result["secure_event_input_before"] != result["secure_event_input_after"]
        )
        result["status"] = "ok"
    except (OSError, AttributeError) as error:
        result["reason"] = type(error).__name__
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["status"] == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
