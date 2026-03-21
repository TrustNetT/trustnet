# TrustNet v1.1.0 Implementation Integration Checklist

**Status**: Phase 2 - Implementation Scripts Created ✅

---

## Created Artifacts

### Deployment Scripts (New)
- [x] `tools/scripts/init-blockchain.sh` - 6-step blockchain deployment
- [x] `tools/scripts/init-api-server.sh` - Python/FastAPI setup and deployment  
- [x] `tools/scripts/integrate-v1.1.0.sh` - Orchestration script tying all phases

### Configuration Files (New)
- [x] `tools/configs/caddy-app-routes.conf` - Caddy routing configuration

### Documentation (New)
- [x] `CURRENT_SITUATION_AND_PLAN.md` - Situation analysis and solution strategy
- [x] `DETAILED_IMPLEMENTATION_ROADMAP.md` - Phased execution plan
- [x] `tools/scripts/INTEGRATION_CHECKLIST.md` - This file

---

## Phase-by-Phase Integration

### Phase 1: Understanding Current Gaps ✅
Scripts created address:
- **Gap 1**: No blockchain service initialization → `init-blockchain.sh`
- **Gap 2**: No FastAPI setup → `init-api-server.sh`  
- **Gap 3**: No Caddy routing → `caddy-app-routes.conf`
- **Gap 4**: No service startup → Both scripts create rc-service templates
- **Gap 5**: No orchestration → `integrate-v1.1.0.sh`

### Phase 2: Pre-VM Testing ⏳ (Next Steps)

#### Task 1: Syntax Validation
```bash
# ✓ All scripts created with proper shebang, error handling, logging
# Test locally (non-destructive):
bash -n tools/scripts/init-blockchain.sh
bash -n tools/scripts/init-api-server.sh  
bash -n tools/scripts/integrate-v1.1.0.sh
```
**Success Criteria**: No syntax errors reported

#### Task 2: Script Walkthrough
Each script should:
- [ ] Create documented directory structure
- [ ] Download required files from GitHub
- [ ] Deploy to VM via SSH/SCP
- [ ] Create service configuration
- [ ] Return clear success/failure status

**Verification**: Read scripts line-by-line, verify logic

#### Task 3: Configuration Review
Caddy configuration should:
- [ ] Route `/api/*` to FastAPI (port 8001)
- [ ] Route `/setup*` to static HTML
- [ ] Route `/blockchain/*` to Tendermint (port 6060)
- [ ] Preserve existing dashboard routing (`/`)

**Verification**: Review caddy-app-routes.conf routing order

---

## Phase 3: VM Testing (Critical)

### Required Pre-Conditions
Before running scripts on VM:
- [ ] VM reachable via SSH: `ssh -p 2223 warden@trustnet.local`
- [ ] Base installation exists: `ls /var/www/trustnet/index.html`
- [ ] Caddy running: `rc-service caddy status`
- [ ] No existing `/opt/trustnet/blockchain` (will be created fresh)
- [ ] No existing `/opt/trustnet/api` (will be created fresh)

### Test Sequence

#### 1. Init-Blockchain Script Test
```bash
# On Host:
ssh -p 2223 warden@trustnet.local "bash $(mktemp)" < tools/scripts/init-blockchain.sh

# Or with logging:
bash tools/scripts/init-blockchain.sh 2>&1 | tee /tmp/blockchain-deployment.log
```

**Expected Output**:
```
[TIME] INFO: Starting v1.0.0 blockchain infrastructure...
[TIME] ✓ VM connectivity verified
[TIME] ✓ Directories created
[TIME] ✓ Config deployed
[TIME] ✓ Service template created  
[TIME] ✓ Blockchain infrastructure deployment complete
```

**Verify on VM**:
```bash
ssh -p 2223 warden@trustnet.local << 'VERIFY'
  ls -la /opt/trustnet/blockchain/
  ls -la /opt/trustnet/venv/
  ls -la /etc/conf.d/trustnet-blockchain
  cat /tmp/trustnet-blockchain.template | head -20
VERIFY
```

**Success Criteria**:
- [ ] `/opt/trustnet/blockchain/{config,data,keys,logs}` exist with proper permissions
- [ ] `/opt/trustnet/venv/` created with Go installed
- [ ] `/etc/conf.d/trustnet-blockchain` config file exists
- [ ] `/tmp/trustnet-blockchain.template` contains rc-service script
- [ ] NO ERRORS in deployment log

#### 2. Init-API-Server Script Test
```bash
# On Host:
bash tools/scripts/init-api-server.sh 2>&1 | tee /tmp/api-deployment.log
```

**Expected Output**:
```
[TIME] INFO: Starting v1.1.0 API server deployment...
[TIME] ✓ API directories created
[TIME] ✓ setup.py deployed
[TIME] ✓ first-setup.html deployed
[TIME] ✓ Python environment configured
[TIME] ✓ API configuration deployed
[TIME] ✓ API service template prepared
[TIME] ✓ Caddy configuration template prepared
[TIME] ✓ API health check script deployed
[TIME] ========================================
[TIME] v1.1.0 API deployment complete
```

**Verify on VM**:
```bash
ssh -p 2223 warden@trustnet.local << 'VERIFY'
  ls -la /opt/trustnet/api/
  ls -la /opt/trustnet/web/templates/
  ls -la /opt/trustnet/venv/bin/
  /opt/trustnet/venv/bin/python --version
  cat /tmp/trustnet-api.template | head -20
  cat /tmp/api-routes.conf.template | head -20
VERIFY
```

**Success Criteria**:
- [ ] `/opt/trustnet/api/setup.py` exists
- [ ] `/opt/trustnet/web/templates/first-setup.html` exists
- [ ] Python venv contains fastapi, uvicorn, qrcode packages
- [ ] `/etc/conf.d/trustnet-api` config exists
- [ ] `/tmp/trustnet-api.template` and `/tmp/api-routes.conf.template` exist
- [ ] NO ERRORS in deployment log

#### 3. Integration Script Test
```bash
# On Host (runs both Phase 1 & 2 in sequence):
bash tools/scripts/integrate-v1.1.0.sh 2>&1 | tee /tmp/integration.log
```

**Expected Output**:
```
╔════════════════════════════════════════╗
║ PHASE 0: Validation                    ║
╚════════════════════════════════════════╝
✓ Found: init-blockchain.sh
✓ Found: init-api-server.sh
✓ Found: caddy-app-routes.conf

╔════════════════════════════════════════╗
║ PHASE 1: Blockchain Infrastructure     ║
╚════════════════════════════════════════╝
...blockchain deployment output...

╔════════════════════════════════════════╗
║ PHASE 2: API Server Setup              ║
╚════════════════════════════════════════╝
...api deployment output...

╔════════════════════════════════════════╗
║ PHASE 3: Caddy Routing Configuration   ║
╚════════════════════════════════════════╝
→ Deploying Caddy configuration...
✓ Caddy configuration deployed

╔════════════════════════════════════════╗
║ PHASE 4: Service Initialization        ║
╚════════════════════════════════════════╝
→ Initializing services on VM...
✓ Services initialized on VM

╔════════════════════════════════════════╗
║ PHASE 5: Health Checks and Verification║
╚════════════════════════════════════════╝
✓ Health checks complete

╔════════════════════════════════════════╗
║ INTEGRATION COMPLETE                   ║
╚════════════════════════════════════════╝
✓ All v1.1.0 components deployed successfully
```

**Verify VM State**:
```bash
ssh -p 2223 warden@trustnet.local << 'VERIFY'
  # Services status
  rc-service trustnet-blockchain status
  rc-service trustnet-api status
  rc-service caddy status
  
  # Process check
  pgrep -f ignite && echo "✓ Blockchain running" || echo "✗ Blockchain not running"
  pgrep -f uvicorn && echo "✓ API running" || echo "✗ API not running"
  pgrep -f caddy && echo "✓ Caddy running" || echo "✗ Caddy not running"
  
  # Port check
  nc -zv localhost 6060 && echo "✓ Port 6060" || echo "✗ Port 6060"
  nc -zv localhost 8001 && echo "✓ Port 8001" || echo "✗ Port 8001"
  
  # Caddy routing test
  curl http://localhost/api/health
  curl http://localhost/setup
VERIFY
```

**Success Criteria**:
- [ ] All 3 services report "running"
- [ ] All 3 processes (ignite, uvicorn, caddy) found
- [ ] Ports 6060, 8001, 443/80 responding
- [ ] Caddy routes working (no 404 errors)
- [ ] No service errors in logs

### Failure Recovery

**If blockchain fails**:
- Check: `ssh warden@trustnet.local "rc-service trustnet-blockchain status"`
- Logs: `ssh warden@trustnet.local "tail -50 /var/log/trustnet-blockchain.log"`
- Recover: Delete and rerun only blockchain script

**If API fails**:
- Check: `ssh warden@trustnet.local "rc-service trustnet-api status"`
- Logs: `ssh warden@trustnet.local "tail -50 /var/log/trustnet-api.log"`  
- Recover: Check Python venv, verify setup.py present

**If Caddy routing fails**:
- Check: `ssh warden@trustnet.local "doas rc-service caddy status"`
- Config: `ssh warden@trustnet.local "doas caddy validate --config /etc/caddy/Caddyfile"`
- Recover: Verify `/etc/caddy/conf.d/app.conf` has correct import path

---

## Phase 4: API Testing ⏳

### Endpoint Tests (After VM healthy)

#### 1. Dashboard
```bash
curl -k https://trustnet.local/
# Should return index.html (200, ~5KB of HTML)
```

#### 2. Setup UI  
```bash
curl -k https://trustnet.local/setup
# Should return first-setup.html (200, iOS-compatible form)
```

#### 3. QR Generation (POST)
```bash
curl -k -X POST https://trustnet.local/api/generate \
  -H "Content-Type: application/json" \
  -d '{"data": "test"}' 
# Should return 200 + PNG image or JSON with image data
```

#### 4. Health Check
```bash
curl -k https://trustnet.local/api/health
# Should return {"status": "ok"} or similar
```

#### 5. Blockchain Status
```bash
curl -k https://trustnet.local/blockchain/status
# Should return blockchain node status (if Tendermint/Ignite exposed)
```

**Success Criteria**:
- [ ] All endpoints return appropriate status codes
- [ ] /api/generate produces valid QR codes
- [ ] No SSL errors (if using self-signed, expected)
- [ ] Response times < 500ms

---

## Phase 5: Integration into install.sh ⏳

### Modification Plan (ADDITIVE ONLY)

**Current install.sh structure**:
```bash
(Lines 1-129: Setup/config)
(Lines 130-150: v1.0.0 deployment)
(Lines 151-200: v1.1.0 deployment) ← These never execute!
(Line 201: Exit)
```

**Problem**: Line in install.sh checks `if [ $BASE_INSTALL_RESULT -ne 0 ]` and exits, preventing v1.1.0 section

**Solution**: ADD new section after line 200, before exit, that:
1. Checks if base deployment succeeded
2. Calls new integrate-v1.1.0.sh script
3. Handles deployment status
4. Provides clear exit message

**Exact Changes**:
```bash
# ADD THESE LINES (after line 200, before final exit):

# Phase 3: v1.1.0 Integration (NEW)
log_info "Starting v1.1.0 integration..."
if [ -f "$SCRIPT_DIR/integrate-v1.1.0.sh" ]; then
    if bash "$SCRIPT_DIR/integrate-v1.1.0.sh"; then
        log_success "v1.1.0 components deployed successfully"
        V1_1_INSTALL_RESULT=0
    else
        log_warning "v1.1.0 deployment had issues (non-fatal)"
        V1_1_INSTALL_RESULT=1
    fi
else
    log_warning "v1.1.0 integration script not found"
    V1_1_INSTALL_RESULT=1
fi

# ADD this exit message:
log_info "============================================"  
if [ $BASE_INSTALL_RESULT -eq 0 ]; then
    log_success "TrustNet installation complete!"
    if [ $V1_1_INSTALL_RESULT -eq 0 ]; then
        log_success "v1.1.0 features enabled (QR, API)"
    else
        log_warning "Base working; v1.1.0 features may need manual setup"
    fi
fi
exit $BASE_INSTALL_RESULT
```

**NOT CHANGED**: Everything from lines 1-200 stays exactly as-is

### Testing Modified install.sh

```bash
# Syntax check (no execution):
bash -n install.sh
# Should report no errors

# Full test on fresh VM (optional):
bash install.sh
# Should progress through all 3 phases: base → v1.0.0 → v1.1.0
```

---

## Phase 6: Production One-Liner Testing ⏳

### Final Verification

```bash
# On a fresh/test machine, run the one-liner:
bash <(curl -sSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh)

# Post-installation checks:
ssh trustnet "rc-service -c status"       # All services running
ssh trustnet "curl http://localhost/"     # Dashboard loads
curl -k https://trustnet.local/api/health # API responds
curl -k -X POST https://trustnet.local/api/generate # QR generation works
```

**Success Criteria**:
- [ ] One-liner completes without errors
- [ ] All services start automatically
- [ ] Dashboard accessible
- [ ] All API endpoints respond
- [ ] QR codes can be generated
- [ ] Log shows all 3 phases completed

---

## Code Protection Verification

All work follows the principle: **"Add only, never modify working code"**

### Verification Checklist

- [x] `install.sh` - NO lines modified (original lines 1-200 untouched)
- [x] `setup-trustnet-node.sh` - NOT MODIFIED
- [x] Dashboard HTML - NOT MODIFIED  
- [x] Caddy base config - NOT MODIFIED
- [x] All changes are ADDITIONS in new files:
  - [x] New scripts in `tools/scripts/`
  - [x] New configs in `tools/configs/`
  - [x] New documentation files

---

## Current Status Summary

| Phase | Status | Artifacts |
|-------|--------|-----------|
| Analysis | ✅ Complete | CURRENT_SITUATION_AND_PLAN.md |
| Planning | ✅ Complete | DETAILED_IMPLEMENTATION_ROADMAP.md |
| Scripts Created | ✅ Complete | init-blockchain.sh, init-api-server.sh, integrate-v1.1.0.sh |
| Configs Created | ✅ Complete | caddy-app-routes.conf |
| Pre-VM Testing | ⏳ Pending | Syntax validation, logic review |
| VM Testing Phase 1 | ⏳ Pending | Deploy blockchain script |
| VM Testing Phase 2 | ⏳ Pending | Deploy API script |
| VM Testing Phase 3-5 | ⏳ Pending | Run integration script, test endpoints |
| integration into install.sh | ⏳ Pending | Add Phase 3 section to install.sh |
| One-liner Testing | ⏳ Pending | Test complete flow fresh VM |

---

## Next Actions (In Order)

1. **Syntax Validation** (15 min)
   ```bash
   bash -n tools/scripts/*.sh
   ```

2. **VM Testing - Blockchain** (30 min)
   ```bash
   bash tools/scripts/init-blockchain.sh
   # Verify /opt/trustnet/blockchain created
   ```

3. **VM Testing - API** (30 min)
   ```bash
   bash tools/scripts/init-api-server.sh
   # Verify /opt/trustnet/api and venv created
   ```

4. **VM Testing - Integration** (20 min)
   ```bash
   bash tools/scripts/integrate-v1.1.0.sh
   # Run full orchestration, verify all services
   ```

5. **Endpoint Testing** (15 min)
   ```bash
   curl -k https://trustnet.local/api/health
   curl -k https://trustnet.local/setup
   ```

6. **Modify install.sh** (10 min)
   - Add Phase 3 integration section
   - Test syntax only

7. **Final One-Liner Test** (30 min)
   - Test on fresh VM
   - Verify complete flow

---

**Estimated Total Time**: 2-3 hours for complete implementation and testing

**Risk Level**: Low (all additions, no modifications to working code)

**Rollback Plan**: Not needed (only additions; revert by removing new files)
