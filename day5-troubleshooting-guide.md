# Day 5 — Troubleshooting Guide
## What Went Wrong and How We Fixed It

---

## Overview

Day 5 was the most challenging day — but also the most valuable. Every problem we hit is something that happens in real production environments. Working through these issues gives you real war stories for interviews.

---

## Issue 1 — Terraform Extension Missing in Pipeline

### What happened
Pipeline failed at the Terraform stage with:
```
A task is missing. The pipeline references a task called 'TerraformInstaller'.
This usually indicates the task isn't installed.
```

### Why it happened
The `TerraformInstaller@1` task in the YAML pipeline requires a marketplace extension that is not installed by default in Azure DevOps.

### How we fixed it
Installed the Terraform extension from Azure DevOps Marketplace:
```
https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks
```
```
Get it free → Select your Azure DevOps organisation → Install
```

### Lesson
Azure DevOps has built-in tasks and marketplace tasks. Marketplace tasks must be installed before they can be used in pipelines. Always check the marketplace when you see a "task is missing" error.

---

## Issue 2 — flake8 Lint Failures in Pipeline

### What happened
Stage 1 (Lint) failed with 20+ errors:
```
app/src/__init__.py:9:1: E302 expected 2 blank lines, found 1
app/src/models/hobby.py:11:7: E221 multiple spaces before operator
app/src/routes/hobbies.py:20:13: E251 unexpected spaces around keyword
```

### Why it happened
The code was written with aligned spacing for readability (e.g., `name        = value`) which flake8 flags as style violations. Also missing blank lines between functions and classes.

### How we fixed it
Fixed all files one by one:
- Added 2 blank lines before every class and function definition
- Removed extra spaces around `=` in function arguments
- Removed trailing whitespace using VS Code `Ctrl+Shift+P → Trim Trailing Whitespace`
- Added exactly one newline at the end of every file

### flake8 Error Codes Reference

| Code | Meaning | Fix |
|---|---|---|
| `E302` | Need 2 blank lines before class/function | Add 2 blank lines |
| `E221` | Multiple spaces before operator | Use single space |
| `E251` | Spaces around `=` in function args | `name=value` not `name = value` |
| `W292` | No newline at end of file | Press Enter on last line once |
| `W293` | Blank line contains whitespace | Trim Trailing Whitespace in VS Code |
| `W391` | Extra blank line at end of file | Remove extra blank lines at end |

### Key lesson
**Always test flake8 locally before pushing:**
```powershell
cd app
flake8 src --max-line-length=120
```
Empty output = no errors. Push only when clean.

---

## Issue 3 — GitHub Push Protection Blocked (Security Alert)

### What happened
```
remote: - GITHUB PUSH PROTECTION
remote: Push cannot contain secrets
remote: - commit: 107e8ed542b19cdfd905d65e8ae95e981010f2cb
remote:   path: project_notes.txt:492
remote: — GitHub Personal Access Token
```

### Why it happened
A Personal Access Token was stored in `project_notes.txt` and accidentally included in a Git commit. GitHub's Push Protection detected the secret and blocked the push.

### How we fixed it

**Step 1 — Revoke the token immediately**
```
GitHub → Settings → Developer Settings → Personal Access Tokens → Delete the token
```

**Step 2 — Remove file from .gitignore**
Added `project_notes.txt` to `.gitignore`

**Step 3 — Remove from Git history** (deleting the file is not enough — it still exists in old commits)
```powershell
pip install git-filter-repo
git filter-repo --path project_notes.txt --invert-paths --force
git remote add origin https://github.com/aravinch/track-your-hobbies.git
git push origin main --force
```

### Why force push was needed
Normal `git push` only adds new commits. Since we rewrote the history to remove the secret from all commits, we had to force GitHub to accept the rewritten version.

### The golden rule
```
NEVER store tokens, passwords, API keys, or credentials
in any file inside a Git repository.

Use a password manager for tokens.
Use .gitignore for .env and .tfvars files.
Use Azure Key Vault for production secrets.
```

---

## Issue 4 — pytest Tests Failing

### Problem 1 — Module not found
```
ModuleNotFoundError: No module named 'src'
```

**Fix:** Created `app/conftest.py` with:
```python
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
```

### Problem 2 — Tests reading real database instead of test database
```
AssertionError: assert [{'category': 'Creative'...}] == []
test_get_hobbies_empty expected empty list but got real data
```

**Fix:** Set `DATABASE_URL` environment variable in `conftest.py` before the app loads. This forces Flask to use an in-memory SQLite database for tests instead of the real `hobbies.db`.

```python
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
```

### Problem 3 — `id` column renamed to `d`
```
sqlite3.OperationalError: no such column: hobbies.d
```

During flake8 fixes, the `id` column in `hobby.py` was accidentally renamed to `d`:
```python
# Wrong ❌
d = db.Column(db.Integer, primary_key=True)

# Correct ✅
id = db.Column(db.Integer, primary_key=True)
```

### Lesson
Always run tests locally after making code changes — even small formatting fixes can break things:
```powershell
pytest tests/ -v
```

---

## Issue 5 — Terraform State Lock

### What happened
```
Error: Error acquiring the state lock
Error message: state blob is already locked
Lock Info:
  ID: 22f08ca2-be98-d364-b145-673b7a12693a
  Operation: OperationTypePlan
```

### Why it happened
A previous pipeline run was cancelled or timed out without releasing the state lock. The lock remained in Azure Blob Storage, blocking all future Terraform operations.

### How we fixed it
```powershell
terraform force-unlock 22f08ca2-be98-d364-b145-673b7a12693a
```
Type `yes` when prompted.

### When does this happen?
- Pipeline cancelled mid-run
- Pipeline timed out
- Network disconnection during terraform apply
- Two people running terraform simultaneously

### Interview answer
> "State locking prevents concurrent modifications to infrastructure. If a lock is left behind by a crashed process, `terraform force-unlock` with the lock ID releases it. You should verify no other process is actually running before force-unlocking."

---

## Issue 6 — Service Principal Missing RBAC Permissions

### What happened
```
Error: retrieving Storage Account
unexpected status 403 (403 Forbidden)
AuthorizationFailed: The client does not have authorization to perform action
'Microsoft.Storage/storageAccounts/read'
```

### Why it happened
The Azure DevOps Service Principal (the robot account that runs the pipeline) didn't have permission to access the storage account containing the Terraform statefile.

### How we fixed it
```powershell
az role assignment create `
  --assignee "cc717d84-c4bf-4860-8884-2b0f5088a10e" `
  --role "Contributor" `
  --scope "/subscriptions/b226224d.../resourceGroups/rg-tfstate"

az role assignment create `
  --assignee "cc717d84-c4bf-4860-8884-2b0f5088a10e" `
  --role "Contributor" `
  --scope "/subscriptions/b226224d..."
```

### Interview answer
> "A Service Principal is a robot user account in Azure AD used by automated processes like pipelines. Just like a human user needs RBAC roles to access resources, the Service Principal needs Contributor role assigned before it can read or write Azure resources."

---

## Issue 7 — Azure App Service Quota Error

### What happened
```
Error: creating App Service Plan
401 Unauthorized
Current Limit (Total VMs): 0
Amount required for this deployment: 1
```

### Why it happened
The Azure subscription had a quota of 0 for App Service VMs. This is common on new or free trial subscriptions.

### How we fixed it
```
portal.azure.com → Search "Quotas" → App Service →
New Quota Request → Request limit of 10 for East US
```
Quota was approved within a few hours.

### Additional issue — F1 tier doesn't support Docker containers
Even after quota was approved, the Free (F1) tier doesn't support Docker containers. Minimum tier for containers is Basic (B1).

**Fix:** Changed SKU from F1 to B1:
```hcl
# infra/modules/app_service/main.tf
sku_name = "B1"
```

---

## Issue 8 — Docker Image Path Duplicated

### What happened
```
Failed to pull image: acrhobbiesdev.azurecr.io/acrhobbiesdev.azurecr.io/hobbies-tracker:latest
```

The ACR login server was duplicated in the image path.

### Why it happened
In Terraform, the `docker_image` variable was set to the full image path including the ACR server URL:
```hcl
# Wrong ❌
docker_image = "${module.container_registry.login_server}/hobbies-tracker"
# Result: acrhobbiesdev.azurecr.io/hobbies-tracker
# Combined with docker_registry_url = acrhobbiesdev.azurecr.io
# Final: acrhobbiesdev.azurecr.io/acrhobbiesdev.azurecr.io/hobbies-tracker
```

### How we fixed it
```hcl
# Correct ✅
docker_image = "hobbies-tracker"
# docker_registry_url already provides: acrhobbiesdev.azurecr.io
# Final: acrhobbiesdev.azurecr.io/hobbies-tracker ✅
```

---

## Issue 9 — ACR Credentials Not Being Set

### What happened
```
DOCKER_REGISTRY_SERVER_PASSWORD  False    (empty)
ImagePullUnauthorizedFailure
```

The App Service couldn't pull the Docker image because the ACR password was not being stored correctly.

### Why it happened
Multiple factors:
1. Managed Identity was conflicting with password credentials
2. PowerShell was not passing the password variable correctly
3. The `always_on` setting was causing issues with F1 tier

### How we fixed it
Destroyed and recreated the App Service cleanly via Terraform with credentials explicitly set in `app_settings`:

```hcl
app_settings = {
  "WEBSITES_PORT"                    = "5000"
  "DOCKER_REGISTRY_SERVER_URL"      = "https://${var.acr_login_server}"
  "DOCKER_REGISTRY_SERVER_USERNAME" = var.acr_username
  "DOCKER_REGISTRY_SERVER_PASSWORD" = var.acr_password
  "DOCKER_ENABLE_CI"                = "false"
}
```

---

## Issue 10 — Missing `latest` Tag in ACR

### What happened
```
Failed to pull image: acrhobbiesdev.azurecr.io/hobbies-tracker:latest
```

Even with correct credentials, the pull failed because the `latest` tag simply didn't exist in ACR.

### Why it happened
The pipeline was pushing images with version tags (`v1`, `v2`, `7`, `8`, `11`, `12`) but never tagging any image as `latest`. The App Service was configured to pull `latest`.

```powershell
# This showed the available tags
az acr repository show-tags `
  --name acrhobbiesdev `
  --repository hobbies-tracker `
  --output table

# Result:
# v1, v2, 7, 8, 11, 12  ← no 'latest' tag!
```

### How we fixed it

**Fix 1 — Tag existing image as latest:**
```powershell
az acr import `
  --name acrhobbiesdev `
  --source acrhobbiesdev.azurecr.io/hobbies-tracker:v2 `
  --image hobbies-tracker:latest
```

**Fix 2 — Update Terraform to use v2 tag:**
```hcl
docker_image_tag = "v2"
```

### The result
```
✅ App live at https://app-hobbies-dev.azurewebsites.net/hobbies
```

---

## Useful Debugging Commands Reference

### App Service logs
```powershell
# Stream live logs
az webapp log tail `
  --name app-hobbies-dev `
  --resource-group rg-hobbies-dev

# Check app status
az webapp show `
  --name app-hobbies-dev `
  --resource-group rg-hobbies-dev `
  --query "{State:state}" `
  --output table

# Check container settings
az webapp config container show `
  --name app-hobbies-dev `
  --resource-group rg-hobbies-dev `
  --output table

# Check app settings
az webapp config appsettings list `
  --name app-hobbies-dev `
  --resource-group rg-hobbies-dev `
  --output table
```

### ACR commands
```powershell
# List all tags for an image
az acr repository show-tags `
  --name acrhobbiesdev `
  --repository hobbies-tracker `
  --output table

# Show ACR credentials
az acr credential show `
  --name acrhobbiesdev `
  --output table

# Tag an existing image
az acr import `
  --name acrhobbiesdev `
  --source acrhobbiesdev.azurecr.io/hobbies-tracker:v2 `
  --image hobbies-tracker:latest
```

### Terraform commands
```powershell
# Release stuck state lock
terraform force-unlock <LOCK_ID>

# Check what's in state
terraform state list

# Refresh state without making changes
terraform plan -refresh-only
```

---

## Summary — What We Learned Today

| Issue | Root Cause | Fix |
|---|---|---|
| TerraformInstaller missing | Marketplace extension not installed | Install from marketplace |
| flake8 failures | Code style violations | Fix spacing, blank lines |
| GitHub Push Protection | Token stored in notes file | Remove from history with filter-repo |
| pytest failures | Wrong database, missing module | conftest.py + in-memory SQLite |
| State lock | Cancelled pipeline left lock | terraform force-unlock |
| 403 on Terraform | Service Principal missing RBAC | az role assignment create |
| App Service quota | Subscription limit = 0 | Request quota increase |
| F1 doesn't support Docker | Free tier limitation | Switch to B1 |
| Duplicate ACR URL | Wrong docker_image variable value | Use image name only, not full path |
| ImagePullUnauthorized | Credentials not set + latest tag missing | Recreate app service + tag image as latest |

---

## Interview Answer — Debugging a Failed Deployment

> "In production, I diagnosed an App Service container failure by reading live logs with `az webapp log tail`. I identified the root cause as a missing `latest` tag in ACR — the pipeline was pushing versioned tags like `v2` but the App Service was configured to pull `latest` which didn't exist. I also debugged a credential issue where the ACR password wasn't being passed correctly to the App Service. The fix was tagging `v2` as `latest` in ACR, recreating the App Service with credentials explicitly set in app_settings via Terraform, and aligning the docker_image_tag configuration. Throughout the process I used `terraform force-unlock` to clear a stuck state lock from a cancelled pipeline run, and assigned Contributor RBAC to the Service Principal so it could access the Terraform statefile in Azure Blob Storage."

---

*See you on 29th May for Day 6 — Azure SQL Database. 🎯*
