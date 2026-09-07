# Releasing MouseDance

GitHub Actions builds every push to `main` and every pull request. The resulting
portable ZIP is available from the workflow run's **Artifacts** section.

## Publish a GitHub Release

1. Update both version values in `Info.plist`:
   - `CFBundleShortVersionString` is the public version, such as `2.1.0`.
   - `CFBundleVersion` is an integer build number and must increase.
2. Commit and push the changes to `main`.
3. Create and push a tag that exactly matches the public version:

   ```sh
   git tag -a v2.4.0 -m "MouseDance 2.4.0"
   git push origin v2.4.0
   ```

The **Release** workflow then builds and verifies the universal macOS app,
creates the portable ZIP and drag-to-Applications DMG, generates SHA-256
checksums, and publishes all four files in a GitHub Release with automatically
generated release notes.

After the first release is published, users can install the latest version with:

```sh
curl -fsSL https://raw.githubusercontent.com/wwwaiyan/MouseDance/main/install.sh | bash
```

If the tag and `CFBundleShortVersionString` do not match, the release stops
without publishing anything.
