---
description: Deploy Panda Script updates to Test and Production servers
---

## Deployment Strategy
Panda Script follows a strict **Test-Before-Production** deployment rule:
1. **Test Server**: `*.52` (Standardized Web Root: `/home`)
2. **Production Server**: `*.123` (Standardized Web Root: `/home`)

## Workflow Steps

### 1. Verification & Testing (Pre-deployment)
Ensure all code changes are committed and pushed to the `main` branch.
```powershell
git status
git add .
git commit -m "Your descriptive message"
git push origin main
```

### 2. Update Test Server (Mandatory First Step)
Always deploy to the test server first to verify stability and premium UX.
// turbo
```bash
ssh root@171.244.139.52 "cd /opt/panda && git fetch origin && git reset --hard origin/main && cd v3/web && npm install && npm run build && cd .. && go build -o panda-linux main.go && systemctl restart panda"
```
After deployment, verify the health status:
```bash
ssh root@171.244.139.52 "curl -s http://localhost:8888/api/health"
```

### 3. User Confirmation & Production Sync
Only proceed to Production after confirming the Test server is functional and bug-free.
// turbo
```bash
ssh root@160.250.130.123 "cd /opt/panda && git fetch origin && git reset --hard origin/main && cd v3/web && npm install && npm run build && cd .. && go build -o panda-linux main.go && systemctl restart panda"
```

## Maintenance Rules
- Never use `/var/www` anymore; all paths MUST be in `/home`.
- Ensure `go version` is >= 1.24 and `node` is >= v20 on both servers.
- Always use `go build -o panda-linux main.go` with CGO disabled on Linux.