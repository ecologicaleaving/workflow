# PROJECT.md - Single Source of Truth

## Project Info
- **Name**: Workflow Hub
- **Version**: v1.0.0
- **Status**: production
- **Platforms**: documentation
- **Description**: Sistema workflow standardizzato per sviluppo collaborativo AI-assisted

## Database
- **Provider**: none
- **Environment**: N/A
- **Database ID**: N/A
- **Schema**: documentation-only
- **Migration Status**: N/A
- **Connection**: 
  - DEV: N/A (static documentation)
  - PROD: GitHub repository hosting
- **Backup**: git version control
- **Seed Data**: N/A
- **Admin URL**: https://github.com/ecologicaleaving/workflow

## Deployment
- **Live URL**: https://github.com/ecologicaleaving/workflow
- **Deploy Method**: github-hosting
- **Deploy Host**: github-pages (future)
- **CI Status**: passing
- **Last Deploy**: 2026-02-22T05:50:00Z
- **Environment Variables**: 
  - No environment variables required

## Repository
- **Main Branch**: master
- **Development Branch**: N/A (direct commits)
- **GitHub**: https://github.com/ecologicaleaving/workflow

## Tech Stack
- **Frontend**: Markdown documentation
- **Backend**: Git version control
- **Database**: N/A
- **Auth**: GitHub account access
- **Deployment**: GitHub repository + raw file access
- **Automation**: Shell scripts + JSON configuration

## Services
- **Documentation Hosting**: GitHub repository interface
- **Raw File Access**: GitHub raw content serving
- **Version Control**: Git with GitHub remote
- **Issue Tracking**: GitHub Issues (future)
- **Automation Distribution**: curl-based script installation

## Monitoring
- **Health Check**: Repository accessibility
- **Service Health**: GitHub platform status
- **Usage Analytics**: GitHub traffic stats
- **Alerts**: GitHub notifications
- **Auto Deploy**: git push to master

## Development
- **Local Setup**: 
  1. `git clone git@github.com:ecologicaleaving/workflow.git`
  2. Edit markdown files with preferred editor
  3. Test scripts locally if needed
  4. `git commit` and `git push` for updates
- **Build Process**: 
  1. No build required (static documentation)
  2. Scripts are executable shell files
  3. JSON configurations are validated manually
  4. Deploy via git push

## Troubleshooting
- **Repository Access**: Check GitHub SSH keys and permissions
- **Script Installation**: Verify curl access and execution permissions
- **Configuration Issues**: Validate JSON syntax in config files
- **Permission Errors**: Ensure scripts are executable (chmod +x)

## Backlog
- **TODO**: GitHub Pages deployment for better documentation hosting
- **TODO**: Automated testing per script installazione e funzionalità
- **TODO**: Template repository creation per quick project setup
- **TODO**: Integration con GitHub Issues per team task management
- **TODO**: CI/CD pipeline per validation automatica documentation changes
- **DONE**: Core workflow documentation per tutti i ruoli team
- **DONE**: Claudio commit skin con automazione completa
- **TODO**: Training materials e video guides per onboarding
- **TODO**: Metrics collection per workflow effectiveness

---
*Last Updated: 2026-02-22T05:50:00Z*
*Auto-generated from: https://app.8020solutions.org/status.html*