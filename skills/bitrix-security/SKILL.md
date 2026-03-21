---
name: bitrix-security
description: >
  Audits 1C-Bitrix security configuration. Checks proactive protection, file permissions,
  .htaccess rules, exposed secrets, admin panel protection, and code vulnerabilities.
  Trigger on: bitrix security, безопасность битрикс, проверка безопасности.
user-invokable: true
argument-hint: "[path-to-bitrix-root]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Bitrix Security Audit

Comprehensive security audit for 1C-Bitrix Site Management installation.

## Security Priority Matrix

| Risk Level | Examples | Response Time |
|------------|---------|--------------|
| 🔴 Critical | PHP files in upload/, exposed credentials, no HTTPS | Fix immediately |
| 🟡 High | Outdated core, no WAF, world-writable files | Fix within 48h |
| 🟠 Medium | No admin IP restriction, debug info exposed | Fix this week |
| 🟢 Low | Minor config improvements | Plan for next sprint |

## Analysis Process

### 1. File Permissions Audit

```bash
# Directories should be 755, files 644
# Find world-writable PHP files
find /var/www/html -name "*.php" -perm -o+w 2>/dev/null | head -20

# Check upload/ permissions
stat /var/www/html/upload/

# Check critical config files
stat /var/www/html/local/php_interface/dbconn.php 2>/dev/null
stat /var/www/html/bitrix/.settings.php 2>/dev/null
```

### 2. PHP Execution in Upload Directory

This is the most critical vulnerability — if upload/ allows PHP execution, attackers can upload webshells.

```bash
# PHP files in upload/ (CRITICAL)
find /var/www/html/upload/ -name "*.php" -o -name "*.php5" -o -name "*.phtml" 2>/dev/null

# Check .htaccess in upload/
cat /var/www/html/upload/.htaccess 2>/dev/null
```

Expected `.htaccess` in `upload/`:
```apache
php_flag engine off
Options -ExecCGI
RemoveHandler .php .php5 .phtml .shtml
```

### 3. Exposed Credentials

```bash
# Search for hardcoded passwords in local/
grep -rn "password\s*=\s*['\"]" /var/www/html/local/ --include="*.php" 2>/dev/null | \
  grep -v "//\|#\|\*" | head -20

# Search for API keys
grep -rn "api_key\s*=\|secret_key\s*=\|token\s*=\|apikey" \
  /var/www/html/local/ --include="*.php" 2>/dev/null | head -20

# Check git history for accidental secret commits
git -C /var/www/html log --all --oneline -- "*dbconn*" "*settings*" 2>/dev/null | head -10
```

### 4. .htaccess Security Rules

```bash
cat /var/www/html/.htaccess
```

Required sections in Bitrix `.htaccess`:
- `RewriteRule ^bitrix/modules/ - [F,L]` — deny module access
- `RewriteRule ^local/modules/ - [F,L]` — deny local module access
- Restriction on `/bitrix/admin/` to known IPs (optional but recommended)

### 5. Proactive Protection (Security Module)

```bash
# Check if security module is installed
ls /var/www/html/bitrix/modules/security/ 2>/dev/null && echo "INSTALLED" || echo "NOT INSTALLED"

# Check proactive protection settings
cat /var/www/html/bitrix/.settings.php 2>/dev/null | grep -A5 "security"
```

### 6. Admin Panel Exposure

```bash
# Check if admin has IP restriction in .htaccess
grep -A5 "bitrix/admin" /var/www/html/.htaccess 2>/dev/null

# Check if HTTPS is enforced
grep -i "https\|HTTPS\|443" /var/www/html/.htaccess | head -5
```

### 7. Code Vulnerability Scan

```bash
# XSS: unescaped output
grep -rn "echo \$_GET\|echo \$_POST\|echo \$_REQUEST\|print \$_GET" \
  /var/www/html/local/ --include="*.php" | grep -v "htmlspecialchars\|Application::sanitize" | head -20

# SQL Injection: raw SQL with user input
grep -rn "->Query\|mysql_query\|mysqli_query" \
  /var/www/html/local/ --include="*.php" | grep "\$_GET\|\$_POST\|\$_REQUEST" | head -10

# Path traversal: file include with user input
grep -rn "include\|require" /var/www/html/local/ --include="*.php" | \
  grep "\$_GET\|\$_POST\|\$_REQUEST" | head -10

# eval() usage (almost always a red flag)
grep -rn "eval(" /var/www/html/local/ --include="*.php" | head -10
```

### 8. SSL/HTTPS Status

```bash
# Check if HTTPS redirect is in .htaccess
grep -i "https\|RewriteRule.*443" /var/www/html/.htaccess | head -5

# Check SSL certificate
echo | openssl s_client -connect localhost:443 -servername localhost 2>/dev/null | \
  openssl x509 -noout -dates 2>/dev/null
```

### 9. Backup Files Exposure

```bash
# Old backups in webroot (should be outside docroot or restricted)
find /var/www/html -maxdepth 3 \( -name "*.sql" -o -name "*.bak" -o -name "*.old" \
  -o -name "*.zip" -o -name "dump*" \) 2>/dev/null | head -20
```

## Output Format

```
# Bitrix Security Audit

## Security Score: [0-100]

## Critical Issues 🔴 (Fix Immediately)
[Numbered list with specific file locations]

## High Priority 🟡 (Fix within 48 hours)
[List]

## Medium Priority 🟠 (Fix this week)
[List]

## Passed Checks 🟢
[List of security measures already in place]

## Detailed Findings

### File Permissions
| Path | Current Perms | Issue |
[table]

### PHP in Upload/
- Status: [VULNERABLE / PROTECTED]
- PHP files found: [None / list of paths]
- .htaccess in upload/: [Present/Missing]

### Exposed Credentials
- Credentials in code: [None found / List of files]
- Accidental git commits: [None / Details]

### Admin Panel
- HTTPS enforced: [Yes/No]
- IP restriction: [Yes/No/Unknown]
- Security module: [Installed/Not installed]

### Code Vulnerabilities
- Potential XSS: [N locations]
- Potential SQL injection: [N locations]
- eval() usage: [N locations]

### Backup Files in Webroot
- SQL dumps: [None / List]
- Archive files: [None / List]

## Action Plan (Priority Order)
1. 🔴 [Most critical action with exact command/fix]
2. 🔴 [Next critical]
3. 🟡 [High priority]
...
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No permission to read files | Report what's accessible, flag gaps |
| No git repository | Skip git history check |
| `openssl` not available | Skip certificate check |
| Not Linux (Windows dev) | Note file permission checks are N/A |
