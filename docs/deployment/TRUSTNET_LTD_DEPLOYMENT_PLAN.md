# TrustNet Ltd Website Deployment Plan

**Date:** March 9, 2026
**Status:** 📋 PLANNING PHASE (not yet implemented)
**Domain:** trustnet-ltd.com
**Reference Sites:** trustnet.services, trustnet.technology

---

## Current Deployment Architecture for trustnet.services & trustnet.technology

### Overview
Both sites use the same infrastructure pattern:

```
┌────────────────────────────────────────────────────────────────┐
│                         USERS (INTERNET)                        │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   Route53 DNS Records    │
                    │  (A + AAAA for domains) │
                    │ (Name Servers Account)  │
                    └────────────┬──────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   CloudFront CDN        │
                    │  (Global edge locations)│
                    │  (SSL/TLS termination)  │
                    │  (Cache optimization)   │
                    └────────────┬──────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   S3 Bucket (Private)    │
                    │  Static website content  │
                    │  (Accessed via OAC only) │
                    └─────────────────────────┘
```

### Key Components

#### 1. AWS Accounts
- **TrustNet Account** (Primary): 424858914547 (eu-west-2)
  - Hosts S3 buckets and CloudFront distributions
  - Runs Terraform deployments
  
- **Name Servers Account** (DNS): 233245301865 (us-east-1)
  - Manages Route53 hosted zones
  - Controls DNS records for all websites
  - Cross-account access via IAM role: `Route53ManagementRole`

#### 2. S3 Buckets (Private, non-public)
| Website | Bucket Name | Region | Access |
|---------|-------------|--------|--------|
| trustnet.technology | `trustnet-technology` | eu-west-2 | CloudFront only (via OAC) |
| trustnet.services | `trustnet-services` | eu-west-2 | CloudFront only (via OAC) |
| **trustnet-ltd.com** | `trustnet-ltd` | eu-west-2 | CloudFront only (via OAC) |

- All buckets are **completely private** (public access blocked)
- S3 bucket policy allows only CloudFront to access content
- Access controlled via **Origin Access Control (OAC)** with SigV4 signing

#### 3. CloudFront CDN Distribution
| Component | Configuration |
|-----------|----------------|
| **Purpose** | Global content delivery + SSL/TLS termination |
| **Origin** | S3 bucket (private, accessed via OAC) |
| **SSL Cert** | Auto-managed via ACM (us-east-1 only) |
| **Default Root** | index.html |
| **Price Class** | PriceClass_100 (US/EU/Asia only) |
| **Function** | CloudFront function for SPA routing |
| **Cache Policy** | Managed-CachingOptimized |
| **Domain Aliases** | `trustnet-ltd.com` and `*.trustnet-ltd.com` |

**CloudFront Function** (`cloudfront-rewrite.js`)
- Rewrites requests for `/about` → `/about/index.html` (SPA routing)
- Enables client-side routing without .html extensions
- Shared across all TrustNet websites

#### 4. Route53 DNS Records
```
A Record:     trustnet-ltd.com → CloudFront distribution ID
AAAA Record:  trustnet-ltd.com → CloudFront distribution ID (IPv6)
CNAME:        ACM certificate validation (auto-managed)
```

#### 5. SSL/TLS Certificate (AWS ACM)
- **Location:** us-east-1 (CloudFront requirement)
- **Domain:** trustnet-ltd.com
- **Subdomains:** *.trustnet-ltd.com
- **Validation:** DNS-based (automatic)
- **Renewal:** Auto-managed by AWS

#### 6. Terraform Infrastructure-as-Code
```
terraform/
├── trustnet-technology/          ← Current template (proven)
│   ├── main.tf                   ← Core infrastructure (S3, CloudFront, Route53)
│   ├── variables.tf              ← Variable definitions
│   ├── terraform.tfvars          ← Variable values for technology site
│   ├── outputs.tf                ← Terraform outputs
│   └── .terraform/               ← State and plugins
│
├── trustnet-services/            ← Copy of technology template (adapted)
│   ├── main.tf                   ← Same structure as technology
│   ├── variables.tf              ← Same variables, different values
│   ├── terraform.tfvars          ← Variable values for services site
│   ├── outputs.tf                ← Terraform outputs
│   └── .terraform/               ← State and plugins
│
└── trustnet-ltd/                 ← NEW (copy of services template)
    ├── main.tf                   ← (to be created)
    ├── variables.tf              ← (to be created)
    ├── terraform.tfvars          ← (to be created)
    ├── outputs.tf                ← (to be created)
    └── .terraform/               ← (auto-created by terraform init)
```

---

## Deployment Plan for trustnet-ltd.com

### Phase 1: Prerequisites (Decision Required)

**Decision Point 1: AWS Account**
- ✅ Use existing TrustNet Account (424858914547) — **RECOMMENDED**
  - Same as trustnet.services and trustnet.technology
  - Terraform already configured
  - DNS role already set up
  - No new account setup needed
  
**Decision Point 2: AWS Region**
- ✅ Use eu-west-2 (London) — **RECOMMENDED**
  - Same as other TrustNet websites
  - Good for EU users
  - Existing terraform template uses this

**Decision Point 3: Domain Registration**
- ✅ trustnet-ltd.com domain already registered? **CONFIRM WITH USER**
  - Assumed yes based on project name
  - If not: Register at Route53 or transfer to Route53

**Decision Point 4: Route53 Hosted Zone**
- ⏳ Need to create Route53 hosted zone for trustnet-ltd.com in Name Servers Account
  - Similar to trustnet.services zone: `Z03647803DCDYW2KGGD40`
  - Will need zone ID for terraform.tfvars

### Phase 2: Code Preparation (5 Steps)

#### Step 1: Create terraform/trustnet-ltd/ Directory
```bash
# Copy proven template from trustnet-services
cp -r terraform/trustnet-services/ terraform/trustnet-ltd/
```

**Files to be created:**
- `terraform/trustnet-ltd/main.tf`
- `terraform/trustnet-ltd/variables.tf`
- `terraform/trustnet-ltd/terraform.tfvars`
- `terraform/trustnet-ltd/outputs.tf`

#### Step 2: Update main.tf (Bucket & CloudFront configuration)
Changes from template:
- Change resource ID from `services` to `ltd`
- Change bucket name to `trustnet-ltd`
- Change domain name to `trustnet.ltd.com`
- Change tags to reference trustnet.ltd.com
- Keep all else identical (proven pattern)

**Example changes in main.tf:**
```diff
- resource "aws_s3_bucket" "services" {
-   bucket = var.services_bucket_name
+ resource "aws_s3_bucket" "ltd" {
+   bucket = var.ltd_bucket_name

- name     = "${var.services_domain}."
+ name     = "${var.ltd_domain}."

- resource "aws_cloudfront_distribution" "services" {
+ resource "aws_cloudfront_distribution" "ltd" {
    origin {
-     domain_name = aws_s3_bucket.services.bucket_regional_domain_name
+     domain_name = aws_s3_bucket.ltd.bucket_regional_domain_name
```

#### Step 3: Update variables.tf (Variable definitions)
Changes from template:
- Rename all `services_` variables to `ltd_`
- Keep default values and descriptions
- No logic changes, only naming

**Example changes in variables.tf:**
```diff
- variable "services_domain" {
-   description = "Domain name for trustnet.services"
-   default     = "trustnet.services"
+ variable "ltd_domain" {
+   description = "Domain name for trustnet-ltd.com"
+   default     = "trustnet-ltd.com"

- variable "services_bucket_name" {
-   description = "S3 bucket name for trustnet.services website"
-   default     = "trustnet-services"
+ variable "ltd_bucket_name" {
+   description = "S3 bucket name for trustnet-ltd.com website"
+   default     = "trustnet-ltd"

- variable "services_zone_id" {
-   description = "Route53 Hosted Zone ID for trustnet.services"
+ variable "ltd_zone_id" {
+   description = "Route53 Hosted Zone ID for trustnet-ltd.com"
```

#### Step 4: Update terraform.tfvars (Variable values)
**File: terraform/trustnet-ltd/terraform.tfvars**

```hcl
# TrustNet Ltd Website - Terraform Configuration
# This configuration manages the trustnet-ltd.com website infrastructure

aws_region = "eu-west-2"
environment = "production"

# Domain configuration
ltd_domain = "trustnet-ltd.com"

# S3 bucket configuration
ltd_bucket_name = "trustnet-ltd"

# DNS management (Name Servers account)
dns_account_id = "233245301865"

# Route53 hosted zone ID for trustnet-ltd.com (from Name Servers account)
# ⏳ TODO: Replace with actual zone ID after Route53 zone creation
ltd_zone_id = "Z????????????????????"
```

#### Step 5: Create Directory Structure in Git
```bash
# Initialize terraform directory
terraform -chdir=terraform/trustnet-ltd init

# Create .gitignore for terraform
cat > terraform/trustnet-ltd/.gitignore << 'EOF'
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
*.tfstate*
.DS_Store
EOF
```

### Phase 3: AWS Infrastructure Setup (4 Steps)

#### Step 3a: Create Route53 Hosted Zone
**Location:** Name Servers Account (233245301865)  
**Action:** Create new hosted zone for `trustnet-ltd.com`

**Expected output:**
```
Hosted Zone ID: Z???????????????????
Name Servers: 
  ns-1234.awsdns-56.com
  ns-5678.awsdns-89.com
  ns-0123.awsdns-45.org
  ns-9876.awsdns-12.co.uk
```

**Action required:** 
- Update domain registrar nameservers to match Route53 nameservers
- Or if Route53 hosts the domain, nameservers already point correctly

#### Step 3b: Update terraform.tfvars with Zone ID
**File:** `terraform/trustnet-ltd/terraform.tfvars`
```hcl
# Replace this:
ltd_zone_id = "Z????????????????????"

# With actual zone ID:
ltd_zone_id = "Z0ABC1234EXAMPLE"  # From Step 3a output
```

#### Step 3c: Validate IAM Permissions
**Verify:** User running terraform has permissions:
- ✅ S3: CreateBucket, PutBucketPolicy, PutPublicAccessBlock, PutOwnershipControls
- ✅ CloudFront: CreateDistribution, CreateFunction, CreateOriginAccessControl
- ✅ ACM: RequestCertificate, DescribeCertificate
- ✅ Route53 (via assume_role): ChangeResourceRecordSets in Name Servers Account

**Note:** Existing terraform for trustnet.services already has these permissions validated

#### Step 3d: Plan & Review Terraform Changes
```bash
cd terraform/trustnet-ltd
terraform init
terraform plan

# Expected outputs:
# - Create aws_s3_bucket.ltd
# - Create aws_s3_bucket_public_access_block.ltd
# - Create aws_cloudfront_origin_access_control.ltd
# - Create aws_acm_certificate.Ltd
# - Create aws_cloudfront_distribution.ltd
# - Create aws_route53_record (validation, A, AAAA)
# - Plus 15-20 other supporting resources

# Review plan for accuracy before applying
```

---

### Phase 4: Website Build & Upload (3 Steps)

#### Step 4a: Build Static Website
```bash
cd trustnet-ltd-web
pnpm install
pnpm build

# Output: dist/ folder with all static HTML/CSS/JS
ls dist/
  index.html
  es/
    index.html
  _astro/
    [CSS and JS files]
  [favicons, manifest.json]
```

#### Step 4b: Deploy Terraform Infrastructure
```bash
cd terraform/trustnet-ltd
terraform apply

# This creates:
# - S3 bucket (trustnet-ltd)
# - CloudFront distribution
# - ACM certificate (auto-validated via Route53)
# - Route53 DNS records (A, AAAA)
# - CloudFront function for routing
```

#### Step 4c: Upload Website Content to S3
```bash
# Use AWS CLI or Terraform (s3 module not in current template)
aws s3 sync dist/ s3://trustnet-ltd --delete

# Invalidate CloudFront cache to serve new content immediately
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"
```

---

### Phase 5: DNS & Verification (2 Steps)

#### Step 5a: Update Domain Registrar (if needed)
**If domain registered elsewhere:**
- Update nameservers to Route53 nameservers
- Example registrar: Namecheap, GoDaddy, etc.

**If domain in Route53:**
- Already configured, no action needed

#### Step 5b: Verify Deployment
```bash
# 1. Check DNS resolution
dig trustnet-ltd.com
nslookup trustnet-ltd.com

# 2. Test CloudFront origin
curl -I https://d?????.cloudfront.net/

# 3. Test via domain
curl -I https://trustnet-ltd.com/

# 4. Test SSL certificate
openssl s_client -connect trustnet-ltd.com:443

# 5. Visual verification
Open https://trustnet-ltd.com in browser
Verify: English page loads, Spanish page loads via /es/
```

---

## Files & Resources Summary

### Terraform Files (to be created)
```
terraform/trustnet-ltd/
├── main.tf                  ← Infrastructure definition
├── variables.tf             ← Variable definitions
├── terraform.tfvars         ← Variable values (from Phase 2, Step 4)
├── outputs.tf               ← Terraform outputs
├── .gitignore               ← Git excludes
└── .terraform/              ← Auto-created by terraform init
```

### Website Source (already exists)
```
trustnet-ltd-web/
├── src/
│   ├── pages/
│   │   ├── index.astro       ← English homepage
│   │   └── es/index.astro    ← Spanish homepage
│   └── translations.ts       ← Bilingual content
├── public/                   ← Favicons, fonts, etc.
├── dist/                     ← Built static files (output)
├── package.json              ← Dependencies
├── astro.config.mjs          ← Astro configuration
└── tsconfig.json             ← TypeScript config
```

### AWS Resources (to be created)
| Resource | Name | Region | Status |
|----------|------|--------|--------|
| S3 Bucket | `trustnet-ltd` | eu-west-2 | 📋 To create |
| CloudFront Dist | `dXXXXXXXXXXXXXX.cloudfront.net` | Global | 📋 To create |
| ACM Cert | `trustnet-ltd.com` | us-east-1 | 📋 To create |
| Route53 Zone | (already exists or needs creation) | us-east-1 | ⏳ Confirm status |
| A Record | `trustnet-ltd.com` → CloudFront | - | 📋 To create |
| AAAA Record | `trustnet-ltd.com` → CloudFront | - | 📋 To create |

---

## Estimated Timeline

| Phase | Duration | Prerequisite |
|-------|----------|-------------|
| Phase 1: Prerequisites | 30 min | User decisions |
| Phase 2: Code Preparation | 30 min | Phase 1 complete |
| Phase 3: Infrastructure Setup | 1.5 hours | Phase 2 complete |
| Phase 4: Build & Upload | 30 min | Phase 3 complete |
| Phase 5: DNS & Verification | 30 min | Phase 4 complete |
| **Total (without delays)** | **3.5 hours** | All dependencies met |

**Note:** DNS propagation can take 24-48 hours globally, but site is typically live within 5-10 minutes after terraform apply.

---

## Decisions Needed from User

Before implementing deployment, confirm:

1. **AWS Account:** Use existing TrustNet Account (424858914547)? ➜ **(Y/N)**
2. **AWS Region:** Use eu-west-2 (London)? ➜ **(Y/N)**
3. **Domain Status:** Is trustnet-ltd.com already registered? ➜ **(Y/N)**
4. **Route53 Zone:** Should we create Route53 hosted zone automatically via Terraform? ➜ **(Y/N)** or provide existing zone ID
5. **CI/CD:** After deployment, should we set up automatic deployments (push to S3 on code changes)? ➜ **(Y/N)**
6. **Timeline:** Ready to deploy immediately after plan approval? ➜ **(Y/N)**

---

## Similarities to Existing Deployments

### trustnet.services (Feb 6, 2026)
✅ Same terraform template used (proved successful)  
✅ Same AWS account, region, structure  
✅ Same CloudFront CDN pattern  
✅ Same Route53 cross-account DNS

### trustnet.technology (Earlier deployment)
✅ Same terraform template base  
✅ Same S3 + CloudFront + Route53 architecture  
✅ Same ACM certificate pattern  
✅ Same OAC (Origin Access Control) security

### Differences for trustnet-ltd.com
- **New S3 bucket:** trustnet-ltd (instead of trustnet-services or trustnet-technology)
- **New domain:** trustnet-ltd.com (instead of trustnet.services or trustnet.technology)
- **New Route53 zone:** Specific to trustnet-ltd.com
- **Everything else:** Identical pattern (lower risk)

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| IAM permissions insufficient | Low (1%) | High | Test terraform plan first |
| ACM cert validation fails | Very Low (<1%) | Medium | DNS records created automatically |
| CloudFront serves stale content | Low (5%) | Low | Invalidation in upload phase |
| DNS propagation delay | Medium (50%) | Low | Site live via CloudFront domain immediately |
| Terraform state corruption | Very Low (<1%) | High | State stored in Git (committed) |

---

## Next Steps

1. **User confirms decisions** (above decision checklist)
2. **Create Route53 hosted zone** if needed
3. **Execute Phase 2:** Code preparation (copy template, adapt variables)
4. **Execute Phase 3:** Infrastructure setup (terraform init/plan/apply)
5. **Execute Phase 4:** Build & upload website content
6. **Execute Phase 5:** Verify deployment
7. **Post-deployment:** Add logo, integrate contact form backend, set up CI/CD

---

**Document Status:** 📋 PLANNING PHASE — Ready for user review and decision

