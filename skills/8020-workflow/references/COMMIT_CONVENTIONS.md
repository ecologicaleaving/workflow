# COMMIT_CONVENTIONS.md - Standard Commit Messages

**Standard per commit messages uniformi e automazione versioning**

## 🎯 Conventional Commits Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## 📝 Commit Types

### **✨ feat** - New Features
- **Version Impact**: MINOR increment (1.2.0 → 1.3.0)
- **Usage**: Nuove funzionalità user-facing
- **Examples**:
  ```bash
  feat: add user authentication system
  feat(ui): implement dark mode toggle
  feat: integrate payment gateway API
  ```

### **🐛 fix** - Bug Fixes  
- **Version Impact**: PATCH increment (1.2.0 → 1.2.1)
- **Usage**: Correzioni di bug
- **Examples**:
  ```bash
  fix: resolve database connection timeout
  fix(auth): handle expired token properly
  fix: correct calculation in price calculator
  ```

### **💥 BREAKING CHANGES** - Major Changes
- **Version Impact**: MAJOR increment (1.2.0 → 2.0.0)
- **Usage**: Changes che rompono backward compatibility
- **Examples**:
  ```bash
  feat!: redesign API endpoints (breaking change)
  fix!: change user model structure
  
  # Alternative syntax
  feat: new authentication system
  
  BREAKING CHANGE: API endpoints now require authorization header
  ```

### **📚 docs** - Documentation
- **Version Impact**: PATCH increment (1.2.0 → 1.2.1)  
- **Usage**: Solo cambi documentazione
- **Examples**:
  ```bash
  docs: update API documentation
  docs: add installation guide
  docs(readme): fix broken links
  ```

### **🎨 style** - Code Style
- **Version Impact**: PATCH increment
- **Usage**: Formattazione, white space, etc (no logic changes)
- **Examples**:
  ```bash
  style: format code with prettier
  style: fix indentation in components
  ```

### **♻️ refactor** - Code Refactoring  
- **Version Impact**: PATCH increment
- **Usage**: Code changes che non sono bug fix né new feature
- **Examples**:
  ```bash
  refactor: extract utility functions
  refactor(auth): simplify token validation logic
  ```

### **✅ test** - Tests
- **Version Impact**: PATCH increment
- **Usage**: Aggiunta o modifica tests
- **Examples**:
  ```bash
  test: add unit tests for user service
  test: update integration tests
  ```

### **🔧 chore** - Maintenance
- **Version Impact**: PATCH increment  
- **Usage**: Build process, dependencies, tool config
- **Examples**:
  ```bash
  chore: update dependencies
  chore: configure GitHub Actions
  chore(deps): bump flutter version to 3.16
  ```

## 🏷️ Scopes (Optional)

Scopes specificano la parte del codebase modificata:

```bash
feat(ui): new button component
fix(api): handle 404 errors  
docs(readme): installation steps
test(auth): login flow tests
```

**Common Scopes**:
- `ui` - User interface components
- `api` - Backend API changes  
- `auth` - Authentication system
- `db` - Database related
- `config` - Configuration files
- `deps` - Dependencies

## 🤖 Automated Versioning

Il **commit skin** legge il tipo di commit e incrementa automaticamente la versione in PROJECT.md:

| Commit Type | Version Impact | Example |
|-------------|---------------|---------|
| `feat:` | MINOR +1 | 1.2.0 → 1.3.0 |
| `fix:` | PATCH +1 | 1.2.0 → 1.2.1 |
| `feat!:` | MAJOR +1 | 1.2.0 → 2.0.0 |
| `docs:` | PATCH +1 | 1.2.0 → 1.2.1 |
| `BREAKING CHANGE:` | MAJOR +1 | 1.2.0 → 2.0.0 |

## ✅ Good Commit Examples

### **Feature Additions**
```bash
feat: implement user profile editing
feat(mobile): add offline sync capability
feat: integrate AI-powered search suggestions
```

### **Bug Fixes**
```bash
fix: resolve memory leak in image loader
fix(payment): handle declined card scenarios
fix: correct date formatting in reports
```

### **Breaking Changes**
```bash
feat!: redesign authentication flow

BREAKING CHANGE: Login API now requires email instead of username.
Users will need to update their client applications.

Migration guide: https://docs.example.com/migration-v2
```

### **Documentation & Maintenance**
```bash
docs: add troubleshooting guide for deployment
chore: update CI/CD pipeline configuration
refactor: simplify error handling middleware
test: add comprehensive API endpoint tests
```

## ❌ Bad Commit Examples

### **Avoid These**:
```bash
❌ "updated stuff"
❌ "fix bug" 
❌ "work in progress"
❌ "changes"
❌ "improvements"
❌ "refactoring"
```

### **Instead Use**:
```bash
✅ "feat: add user notification preferences"
✅ "fix: resolve login timeout issue"
✅ "refactor: extract database connection logic"  
✅ "docs: update API endpoints documentation"
```

## 📋 Commit Message Checklist

Before committing, ensure:

- [ ] **Type** is correct and appropriate
- [ ] **Description** is clear and specific (50 chars or less)
- [ ] **Body** explains "what" and "why" if needed
- [ ] **Breaking changes** are clearly marked
- [ ] **Scope** is used when multiple areas are affected
- [ ] **Issue references** included if applicable (closes #123)

## 🔄 Integration with Claudio Skin

The commit skin automatically:

1. **Parses commit message** to determine version increment
2. **Updates PROJECT.md** with new version  
3. **Builds project** if needed (APK, web, etc.)
4. **Stages artifacts** in releases/ directory
5. **Enhances commit message** with build summary

Example enhanced commit:
```bash
Original: "feat: add dark mode support"

Enhanced by skin:
feat: add dark mode support

Auto-generated by claudio-commit-skin:
- Updated PROJECT.md: v1.2.0 → v1.3.0  
- Built 2 artifact(s): myapp-v1.3.0.apk myapp-web-v1.3.0.zip
- Ready for deployment by Ciccio
```

## 📖 References

- **Conventional Commits**: https://www.conventionalcommits.org/
- **Semantic Versioning**: https://semver.org/
- **80/20 Workflow**: See WORKFLOW_CLAUDIO.md for full process

---

**Remember**: Good commit messages are documentation for future developers (including yourself)!