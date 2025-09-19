# Documentation Guide

This directory contains comprehensive documentation for the GTM-146 Revenue Automation project.

## Directory Structure

### 📐 Architecture (`architecture/`)
Technical system design, data models, and integration specifications.

- **Data Models:** Object relationships and field mappings
- **Integration Design:** API specifications and external system connections
- **Security Model:** Permission sets, field-level security, and data access
- **Performance Considerations:** Governor limits, batch processing, optimization

### 🔄 Sessions (`sessions/`)
Development session summaries, progress tracking, and decision logs.

- **Session Summaries:** Daily development progress and accomplishments
- **Decision Log:** Technical decisions and rationale
- **Progress Tracking:** Phase completion status and blockers
- **Change Log:** Major changes and their impact

### 🔧 Technical (`technical/`)
Implementation details, code documentation, and deployment guides.

- **Apex Documentation:** Class and method documentation
- **Flow Documentation:** Process automation specifications
- **Field Mappings:** OLI to Asset conversion specifications
- **Deployment Guides:** Environment-specific deployment instructions

### 👥 User Guides (`user-guides/`)
End-user documentation, training materials, and process workflows.

- **Sales Team Guide:** New opportunity and contract processes
- **Operations Guide:** Manual override procedures and troubleshooting
- **Admin Guide:** Configuration and maintenance procedures
- **Training Materials:** Step-by-step process walkthroughs

## Document Standards

### File Naming Convention
- Use kebab-case for file names: `contract-lifecycle-model.md`
- Include version dates for major updates: `asset-status-framework-v2.md`
- Use descriptive names that indicate content scope

### Content Standards
- Include last updated date in document header
- Reference related GTM tickets where applicable
- Include code examples for technical documents
- Provide screenshots for user-facing documentation

## Template Usage

Each directory contains templates to accelerate documentation:

### Architecture Templates
- **`data-model-template.md`** - For documenting objects, fields, relationships, and business rules
- Use for each major object (Opportunity, Contract, Asset)

### Technical Templates  
- **`apex-class-template.md`** - For documenting Apex classes, methods, and dependencies
- **`flow-template.md`** - For documenting Flows, automation, and business processes
- Use for each significant technical component

### User Guide Templates
- **`user-guide-template.md`** - For end-user documentation with step-by-step instructions
- Use for each user-facing feature or process

## Maintenance

Documentation is updated at the end of each development session based on:
- Session logs from `logs/archive/`  
- Code changes and new implementations
- User feedback and process refinements
- Technical decisions and architecture changes

### Session Workflow
1. Session logs track all development activity
2. Master documentation updated from session logs
3. Session logs archived (excluded from commits)  
4. Progress tracked in `docs/sessions/`

---

**Last Updated:** August 25, 2025 - Project Setup Complete  
**Current Status:** Ready for Phase 1 Development  
**Maintained By:** Development Team
