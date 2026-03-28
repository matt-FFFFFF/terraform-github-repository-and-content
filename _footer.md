## Examples

The [examples/complete](examples/complete) directory contains full working configurations covering:

| Example | Description |
|---------|-------------|
| Directory tree | Load a local directory into a repo using `fileset()` + `file()` |
| Inline content | Pass file content as literal strings or heredocs |
| Feature branch | Commit files to a non-default branch |
| Existing repo | Manage content without creating the repository |
| Template repo | Bootstrap from a GitHub template repository |

## Notes

- The GitHub provider must be configured with a token that has `repo` scope (or fine-grained equivalent). Set the `GITHUB_TOKEN` environment variable or configure the provider block directly.
- Each file managed by this module results in a separate commit via the GitHub API. This is a limitation of the `github_repository_file` resource.
- When `create_repository = false`, the repository must already exist and the default branch must be initialized.
