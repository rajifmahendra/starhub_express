# DAST Implementation Guide - StarHub Express

## Overview

Implementasi Dynamic Application Security Testing (DAST) menggunakan Checkmarx untuk aplikasi StarHub Express API. DAST akan melakukan pengujian keamanan secara otomatis terhadap aplikasi yang berjalan untuk mengidentifikasi vulnerabilities.

## 🎯 Objectives

- Mengimplementasikan DAST scanning dengan Checkmarx
- Mengintegrasikan security testing ke dalam CI/CD pipeline
- Mengidentifikasi vulnerabilities seperti SQL Injection, XSS, Command Injection
- Menghasilkan laporan security yang komprehensif

## 📁 File Structure

```
starhub_express/
├── zap_config.yaml              # Konfigurasi ZAP untuk DAST
├── Dockerfile                   # Optimized Dockerfile untuk testing
├── Jenkinsfile-DAST            # Jenkins pipeline untuk DAST
├── scripts/
│   ├── setup-dast.sh          # Script setup environment
│   └── cleanup-dast.sh        # Script cleanup resources
└── DAST_IMPLEMENTATION_GUIDE.md
```

## 🔧 Configuration Files

### 1. ZAP Configuration (zap_config.yaml)

Konfigurasi utama untuk ZAP scanner dengan fitur:
- **Authentication**: JWT token-based authentication
- **Spider crawling**: Automated discovery endpoint
- **API testing**: OpenAPI/Swagger integration
- **Active scanning**: Comprehensive vulnerability testing
- **Reporting**: HTML dan JSON reports

Key features:
```yaml
authentication:
  method: json
  loginRequestUrl: http://localhost:4003/api/auth/login
  loginRequestBody: '{ "email": "%username%", "password": "%password%" }'

sessionManagement:
  method: httpHeader
  headerName: Authorization
  headerPrefix: Bearer
```

### 2. Optimized Dockerfile

Enhanced untuk DAST testing:
- Health checks untuk readiness validation
- Non-root user untuk security
- Additional tools (curl, wget) untuk testing
- Production-ready build

### 3. Jenkins Pipeline (Jenkinsfile-DAST)

Comprehensive pipeline dengan:
- Multi-stage scanning (quick, full, api-only)
- Network isolation
- Automated cleanup
- Result processing dan archival
- Configurable fail conditions

## 🚀 Setup Instructions

### Prerequisites

1. **Docker** installed dan running
2. **Jenkins** dengan plugins:
   - Docker Pipeline
   - Credentials Binding
   - Archive Artifacts
3. **Checkmarx account** dengan API key
4. **GitHub credentials** untuk repository access

### Step 1: Configure Jenkins Credentials

1. **Checkmarx API Key**:
   ```
   ID: cx-api-key
   Type: Secret text
   Value: <your-checkmarx-api-key>
   ```

2. **GitHub Token**:
   ```
   ID: token-github-project-rajif
   Type: Username with password
   Username: <github-username>
   Password: <github-token>
   ```

### Step 2: Setup Pipeline

1. Create new Jenkins Pipeline job
2. Pipeline definition: "Pipeline script from SCM"
3. SCM: Git
4. Repository URL: `https://github.com/rajifmahendra/starhub_express.git`
5. Script Path: `Jenkinsfile-DAST`

### Step 3: Configure Environment

Update environment variables di Jenkinsfile sesuai setup:
```groovy
environment {
    CHECKMARX_BASE_URL = 'https://anz.ast.checkmarx.net'
    ENV_ID = '1d831157-6d03-448c-8886-63fb575da86f'
    REPO_NAME = 'starhub_express'
}
```

## 🏃‍♂️ Running DAST Scans

### Method 1: Jenkins Pipeline

1. **Quick Scan** (3-5 minutes):
   ```
   Parameters:
   - SCAN_TYPE: quick
   - FAIL_ON_HIGH: false
   ```

2. **Full Scan** (15-30 minutes):
   ```
   Parameters:
   - SCAN_TYPE: full
   - FAIL_ON_HIGH: true
   ```

3. **API Only Scan** (5-10 minutes):
   ```
   Parameters:
   - SCAN_TYPE: api-only
   - FAIL_ON_HIGH: true
   ```

### Method 2: Manual Setup

1. **Setup environment**:
   ```bash
   ./scripts/setup-dast.sh
   ```

2. **Run DAST scan**:
   ```bash
   docker run --user 0 \
     --network dast-network \
     -v "$(pwd)/output:/output" \
     -v "$(pwd)/zap_config.yaml:/config/zap_config.yaml" \
     -e CX_APIKEY=$CX_APIKEY \
     checkmarx/dast:latest \
     web --base-url=$CHECKMARX_BASE_URL \
     --timeout=10000 \
     --log-level=debug \
     --verbose \
     --environment-id=$ENV_ID \
     --fail-on high \
     --config="/config/zap_config.yaml" \
     --output /output
   ```

3. **Cleanup**:
   ```bash
   ./scripts/cleanup-dast.sh
   ```

## 🔍 Vulnerability Categories Tested

### 1. Injection Attacks
- **SQL Injection**: MySQL, PostgreSQL, Oracle, Hypersonic
- **Code Injection**: Server-side code execution
- **Command Injection**: OS command execution

### 2. Cross-Site Scripting (XSS)
- **Reflected XSS**: Input validation bypass
- **Persistent XSS**: Stored malicious scripts
- **DOM-based XSS**: Client-side vulnerabilities

### 3. Authentication & Authorization
- **Session Management**: Token handling
- **Access Control**: Endpoint protection
- **Authentication Bypass**: Login mechanism flaws

### 4. API Security
- **Input Validation**: Parameter manipulation
- **Rate Limiting**: DoS protection
- **Data Exposure**: Sensitive information leakage

## 📊 Reports dan Results

### Report Types

1. **HTML Report**: `dast-report.html`
   - User-friendly vulnerability overview
   - Detailed findings dengan remediation
   - Risk ratings dan severity levels

2. **JSON Report**: `results.json`
   - Machine-readable format
   - Integration dengan tools lain
   - Automated processing

3. **Summary Report**: `dast-summary.txt`
   - Quick overview
   - Vulnerability counts
   - Build information

### Severity Levels

- **Critical**: Immediate action required
- **High**: Fix dalam 7 hari
- **Medium**: Fix dalam 30 hari
- **Low**: Fix dalam next release
- **Info**: Best practices recommendations

## 🛠 Troubleshooting

### Common Issues

1. **Container startup fails**:
   ```bash
   # Check application logs
   docker logs starhub-express
   
   # Verify port binding
   netstat -tlnp | grep 4003
   ```

2. **Authentication failures**:
   ```bash
   # Test login endpoint
   curl -X POST http://localhost:4003/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"rajif@gmail.com","password":"mypassword"}'
   ```

3. **ZAP configuration errors**:
   ```bash
   # Validate YAML syntax
   python3 -c "import yaml; yaml.safe_load(open('zap_config.yaml'))"
   ```

4. **Network connectivity**:
   ```bash
   # Check Docker network
   docker network ls
   docker network inspect dast-network
   ```

### Debug Commands

```bash
# Check container status
./scripts/setup-dast.sh status

# Test API endpoints
./scripts/setup-dast.sh test

# View application logs
docker logs starhub-express --tail 50 -f

# View DAST runner logs
docker logs checkmarx-dast-runner --tail 50 -f
```

## 🔐 Security Best Practices

### Application Security

1. **Input Validation**: Validate semua user inputs
2. **Output Encoding**: Encode outputs untuk prevent XSS
3. **Authentication**: Implement secure JWT handling
4. **Authorization**: Proper role-based access control
5. **Error Handling**: Don't expose sensitive information

### DAST Configuration

1. **Scope Limitation**: Test hanya endpoint yang relevan
2. **Rate Limiting**: Configure scan speed
3. **Authentication**: Use test accounts dengan limited privileges
4. **Data Privacy**: Avoid scanning production data

## 📈 Integration dengan CI/CD

### Pipeline Stages

1. **Build & Test**: Unit dan integration tests
2. **SAST**: Static analysis
3. **Deploy to Test**: Deploy aplikasi
4. **DAST**: Dynamic security testing
5. **Security Review**: Manual review untuk critical findings
6. **Deploy to Production**: Conditional pada security approval

### Quality Gates

```groovy
// Fail pipeline jika ada critical vulnerabilities
if (criticalVulns > 0) {
    error("Critical vulnerabilities found: ${criticalVulns}")
}

// Warning untuk high vulnerabilities
if (highVulns > 5) {
    unstable("High vulnerabilities exceed threshold: ${highVulns}")
}
```

## 📝 Maintenance

### Regular Tasks

1. **Update ZAP rules**: Monthly update
2. **Review scan results**: Weekly security review
3. **Update credentials**: Rotate test credentials
4. **Configuration tuning**: Optimize scan performance

### Monitoring

- Pipeline success rates
- Scan duration trends
- Vulnerability trends over time
- False positive rates

## 🔗 References

- [Checkmarx DAST Documentation](https://checkmarx.com/resource/documents/en/34965-68702-checkmarx-dast.html)
- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

---

**Status**: ✅ Ready for Implementation
**Last Updated**: $(date)
**Maintainer**: DevSecOps Team
