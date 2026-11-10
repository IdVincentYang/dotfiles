FlClash personal Android release signing

android-release.jks and android-release.json are the private signing key and its local credentials. Keep them together for future updates; the key is not stored in the Git repository. android-release-cert.pem is the public certificate.

Package: com.follow.clash
Alias: flclash-personal
Certificate SHA-256: 5061a3b8a8b4eeb26e122da2d20255e2a274c7612c310c0ccceb4b49a28fabf3

Use the same key for subsequent updates. This personal signature differs from upstream FlClash releases, so it cannot directly replace an installed upstream-signed APK.
