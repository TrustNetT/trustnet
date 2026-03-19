# TrustNet Website Deployment Plan - Feb 6, 2026

## Current Understanding

### Problem
- Yesterday (Feb 5): trustnet.technology website was deployed successfully
- Today (Feb 6): Need to deploy trustnet.services website
- User requirement: Keep separate terraform folders for each website (NOT mixed in single aws/ folder)

### Current Situation (WRONG)
- All terraform code is in: `/home/jcgarcia/wip/priv/trustnet-wip/aws/main.tf`
- This mixes both websites in one file
- git history shows only state files committed, not source terraform code
- Directory `terraform/trustnet-technology/` exists but is empty

### Correct Structure (WHAT WE NEED)
```
terraform/
├── trustnet-technology/
│   ├── main.tf                    (Copy from successful deployment)
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── cloudfront-rewrite.js
│   └── <any other config files>
│
└── trustnet-services/
    ├── main.tf                    (Copy from trustnet-technology and modify)
    ├── variables.tf               (Copy and adjust bucket/domain names)
    ├── terraform.tfvars
    ├── cloudfront-rewrite.js      (Copy from technology version)
    └── <same structure>
```

---

## Deployment Plan - 5 STEPS

### STEP 1: Review Yesterday's Working Code
- **What**: Read the terraform code that successfully deployed trustnet.technology
- **Files**: Main.tf in aws/ folder (currently has working code mixed with services code)
- **Output**: Understand what terraform resources were created (S3, CloudFront, Route53, ACM, etc.)
- **Status**: terraform.tfstate shows resources exist and work

### STEP 2: Create Separate Folder for trustnet-technology
- **What**: Copy the working terraform code from aws/ to terraform/trustnet-technology/
- **Action**: 
  - Copy `aws/main.tf` → `terraform/trustnet-technology/main.tf`
  - Copy `aws/variables.tf` → `terraform/trustnet-technology/variables.tf`
  - Copy `aws/terraform.tfvars` → `terraform/trustnet-technology/terraform.tfvars`
  - Copy `aws/cloudfront-rewrite.js` → `terraform/trustnet-technology/cloudfront-rewrite.js`
- **Keep**: Only the parts related to trustnet.technology (clean out services-related code)
- **Commit**: Git commit with message "Organize: Move trustnet-technology terraform to separate folder"

### STEP 3: Create Folder for trustnet-services  
- **What**: Copy trustnet-technology terraform and adapt it for trustnet-services
- **Action**:
  - Copy `terraform/trustnet-technology/` → `terraform/trustnet-services/`
  - Modify variable files:
    - Change bucket name: trustnet-technology → trustnet-services
    - Change domain: trustnet.technology → trustnet.services
    - Update zone IDs for Route53
  - Keep code structure identical (reuse proven solution)
- **No changes to**: CloudFront function, S3 structure, routing logic
- **Commit**: Git commit with message "Create trustnet-services terraform from trustnet-technology template"

### STEP 4: Build trustnet-services Website
- **What**: Compile the Astro website to static files
- **Command**:
  ```bash
  cd trustnet-services-web/
  pnpm run build
  ```
- **Output**: Creates `dist/` folder with index.html and assets
- **Verify**: Check that dist/ folder has files

### STEP 5: Deploy to S3
- **What**: Upload built website files to S3 bucket
- **Bucket**: Identified from terraform.tfvars (services_bucket_name)
- **Command**: 
  ```bash
  aws s3 sync dist/ s3://{services_bucket_name}/ --delete
  ```
- **Invalidate CloudFront**: Clear cache so new content is visible
  ```bash
  aws cloudfront create-invalidation --distribution-id {services_dist_id} --paths "/*"
  ```
- **Verify**: Access https://trustnet.services and confirm it works

---

## Why This Approach

✅ **Keeps history clean**: Each website has its own folder with only its terraform code
✅ **Easy to modify**: Want to change trustnet.technology? Edit its folder only
✅ **Easy to repeat**: Future websites: copy trustnet-services as template
✅ **No mess**: Original aws/ folder mess removed (clean repository)
✅ **Version control works**: Every change is tracked separately

---

## Questions Before We Start

1. **Is the working terraform code currently in `aws/main.tf`?** (YES - we found it)
2. **Should we keep the aws/ folder empty after moving files?** (User decision)
3. **Bucket names - are these correct?**
   - trustnet-technology (from terraform.tfvars)
   - trustnet-services (need to confirm from tfvars)
4. **CloudFront distribution IDs** - do we have these from terraform.tfstate?

---

## Timeline
- Step 1 (Review): 10 minutes
- Step 2 (Organize technology): 5 minutes  
- Step 3 (Create services): 10 minutes
- Step 4 (Build): 2 minutes
- Step 5 (Deploy): 5 minutes
- **Total**: ~30 minutes

---

**Ready to proceed?** Please confirm:
1. Is this the correct understanding of what needs to be done?
2. Should I start with Step 1 (reviewing the working terraform)?
