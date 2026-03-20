# AWS Authentication for TrustNet Ltd Website Deployment

**Date:** March 9, 2026  
**Purpose:** Documentation for AWS login and profile selection for terraform deployments

---

## Authentication Method

**Tool**: `awslogin` script (AWS SSO based)  
**Location**: `/home/jcgarcia/.scripts/awslogin`

---

## Account & Profile Information for trustnet-ltd.com

### Step 1: Select AWS Profile (First)

When you run `awslogin`, you will see available profiles:

```
Listing available AWS profiles...
1) GlobalAdmin-SocialRemits          3) jcgarcia-ingasti
2) foreman                           4) ConstructionManager-IngastiMedia
#?
```

**You MUST select: 2 (foreman)**

### Step 2: Select AWS Account (Second)

After selecting profile and authenticating via browser, you'll see available accounts:

```
Available accounts:
1) TrustNet (424858914547)       ← SELECT THIS ONE ✓
2) Ingasti Media (007041844937)
3) Ingasti (147997129378)
4) Factory (038462777168)
Select an account by number:
```

**You MUST select: 1 (TrustNet - 424858914547)**

### Step 3: Select Role (Third)

After selecting account, you'll see available roles:

```
Available roles:
1) ConstructionManager           ← SELECT THIS ONE ✓
Select a role by number:
```

**You MUST select: 1 (ConstructionManager)**

**Note**: ConstructionManager has cross-account Route53 permissions required for DNS management. GlobalAdministration does not.

---

## Complete Login Steps

```bash
# 1. Run the login script
awslogin

# 2. Follow prompts (IN THIS ORDER):
#    Step 1 - Select Profile: foreman (option 2)
#    Step 2 - Select Account: TrustNet (424858914547) (option 1)
#    Step 3 - Select Role: ConstructionManager (option 1)
#    Step 4 - Approve SSO login in your browser (opens automatically)

# 3. Verify successful login
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "...",
#     "Account": "424858914547",
#     "Arn": "arn:aws:iam::424858914547:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_ConstructionManager_..."
# }
```

---

## AWS Accounts Reference

| Account | ID | Purpose | For Website? |
|---------|-----|---------|------------|
| Ingasti (Management) | 147997129378 | Organization management | ❌ No |
| Ingasti Media | 007041844937 | Media production | ❌ No |
| **TrustNet** | **424858914547** | **Website hosting** | **✓ YES** |
| Name Servers (DNS) | 233245301865 | Cross-account DNS | ✓ (auto via terrafo ) |

---

## Role Details

### ConstructionManager (TrustNet Account)

**Purpose**: Infrastructure deployment with cross-account Route53 DNS access (required for trustnet-ltd.com)

**Permissions Included**:

- S3: Full access (create/upload/delete buckets & objects)
- CloudFront: Full access (distributions, functions, caching)
- ACM: Full access (certificates, validation)
- IAM: AssumeRole permissions
- Route53: Full read/write via cross-account assume_role to Name Servers Account
- STS: AssumeRole permissions for Route53ManagementRole in account 233245301865

**Role ARN**: `arn:aws:iam::424858914547:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_ConstructionManager_...`

**Why ConstructionManager?** GlobalAdministration lacks permission to assume the Route53ManagementRole in the Name Servers Account. Infrastructure deployments require ConstructionManager.

---

## Cross-Account Access (DNS)

The terraform configuration automatically assumes a role in the **Name Servers Account (233245301865)** to manage Route53 records.

**How it works**:

1. You authenticate with ConstructionManager role in TrustNet Account
2. Terraform uses `assume_role` to access Name Servers Account
3. Your ConstructionManager credentials have STS:AssumeRole permission for Route53ManagementRole
4. Role name: `Route53ManagementRole` (in Name Servers Account)
5. Session duration: 1 hour (auto-refreshes)
6. No credentials stored in files—all temporary and environment-based

---

## Quick Reference Card

```
┌──────────────────────────────────────────────────────────┐
│  AWS AUTHENTICATION FOR TRUSTNET-LTD.COM DEPLOYMENT      │
├──────────────────────────────────────────────────────────┤
│  1. Run:           awslogin                              │
│  2. Select Profile: foreman (option 2)                   │
│  3. Select Account: TrustNet (424858914547) (option 1)   │
│  4. Select Role:    ConstructionManager (option 1)       │
│  5. Approve:       Browser SSO login                     │
│                                                          │
│  Region:           eu-west-2                             │
│  Session Duration: 1 hour                                │
│  Cross-Account:    Route53 in Name Servers Account       │
│                                                          │
│  Verification:     aws sts get-caller-identity           │
│                    (should show ConstructionManager role)│
└──────────────────────────────────────────────────────────┘
```

---

## If Something Goes Wrong

### "Not authenticated to AWS"
Solution: Run `awslogin` and follow the steps in order:
1. Select profile: foreman
2. Select account: TrustNet
3. Select role: GlobalAdministration

### "InvalidClientTokenId" error
Solution: Your session has expired or credentials are invalid
- Run `awslogin` again to refresh credentials
- Session is valid for 1 hour

### "Wrong role selected"
Solution: Wrong role selected during awslogin
- Run `awslogin` again
- Make sure you select **GlobalAdministration** (option 1)

### "Still have the wrong account?"
Solution: Verify before proceeding
```bash
aws sts get-caller-identity --query Account --output text
# Should output: 424858914547
```

---

## Next Steps

Once authenticated (confirmed with `aws sts get-caller-identity`):

```bash
cd /home/jcgarcia/GitProjects/TrustNet/trustnet-wip/terraform/trustnet-ltd
terraform init
terraform plan
terraform apply
```

