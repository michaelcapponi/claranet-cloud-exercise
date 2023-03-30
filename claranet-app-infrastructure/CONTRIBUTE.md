### Bug Reports & Feature Requests

Write to michaelcapponi96@gmail.com

### Release process
1. Start a new release: `git flow release start x.y.z`
2. Update version at *line 4* in `main.tf`
3. Update CHANGELOG.md with relevant changes
4. Rebuild the docs:
    The README.md is built with terraform-docs. To install follow the instruction [here](https://terraform-docs.io/user-guide/installation/).
    ```bash
    terraform-docs .
    ```
5. Check that only *.md* files have changed: `git status`
5. Commit
6. Finish the release: `git flow release finish x.y.z`
7. Push code and tags: `git push master; git push develop; git push --tags`
