# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

IRIS-CNCF is a comprehensive learning repository focused on mastering cloud-native technologies, multi-cloud architectures, and Infrastructure as Code. This is primarily a documentation and learning resource repository, not an application codebase. It contains structured learning materials, configuration examples, and reference architectures for cloud platforms (AWS, Azure, GCP), CNCF technologies, and IaC tools (Terraform, Ansible).

**Target Audience**: Cloud professionals preparing for certifications (AWS SAP, CKA, CKAD, CKS) and aspiring to become multi-cloud and CNCF experts.

## Repository Structure

### Major Sections

1. **aws-sap-review/**: AWS Solutions Architect Professional exam preparation
   - Organized by AWS service categories (compute, networking, storage, database, security, etc.)
   - Contains outlines, examples, and real-world scenarios

2. **cncf-real-world/**: Production-ready Kubernetes and cloud-native patterns
   - Deployments, monitoring, security, networking, storage, CI/CD, service mesh, GitOps
   - Focus on production best practices beyond basic Kubernetes concepts

3. **ansible-mastery/**: Ansible automation and configuration management
   - Playbooks, roles, advanced patterns, multi-cloud automation
   - Includes security hardening and CI/CD integration examples

4. **terraform-mastery/**: Multi-cloud Infrastructure as Code with Terraform
   - Separate directories for AWS, Azure, GCP, and multi-cloud patterns
   - Reusable modules and advanced Terraform patterns

5. **cross-cloud-comparison/**: Service equivalency mappings across AWS, Azure, and GCP
   - Comprehensive service-mapping.md showing equivalent services
   - Compute, storage, networking, database, security comparisons

6. **LEARNING_ROADMAP.md**: Detailed 12-week learning plan with daily tasks and progression tracking

## File Structure Conventions

Each section typically contains:
- **README.md**: Overview and learning objectives
- **outline.md**: Detailed topic breakdown
- **examples/**: Practical code samples and configurations
- **labs/**: Hands-on exercises (may not exist yet)
- **real-world-scenarios/**: Production-ready patterns (may not exist yet)
- **cheatsheet.md**: Quick reference guide (may not exist yet)

## Common Tasks

### Creating New Learning Content

When adding new content to this repository:

1. Follow the established directory structure for the relevant section
2. Include both imperative (what to do) and explanatory (why) content
3. Provide practical examples with comments explaining key concepts
4. Reference specific cloud provider documentation where appropriate
5. Include multi-cloud comparisons when adding cloud-specific content

### Documentation Standards

- Use GitHub-flavored Markdown
- Include code blocks with appropriate language tags (yaml, hcl, bash, etc.)
- Use tables for comparisons and mappings
- Include diagrams using ASCII art or Mermaid for architecture patterns
- Organize content with clear headers (##, ###) for easy navigation

### Example Patterns

When creating examples for:

**Kubernetes/CNCF**:
- Always include resource requests/limits
- Show production-ready patterns (health checks, security contexts, etc.)
- Demonstrate best practices (non-root users, read-only filesystems, etc.)
- Include comments explaining why certain configurations are used

**Terraform**:
- Use variables for flexibility
- Include version constraints in terraform blocks
- Show remote state configuration patterns
- Demonstrate module usage for reusability
- Include outputs for important resource attributes

**Ansible**:
- Structure playbooks with clear task names
- Use roles for reusability
- Show handler patterns for service management
- Include both Debian/Ubuntu and RHEL/CentOS examples when OS-specific
- Demonstrate idempotency

## Content Philosophy

This repository emphasizes:

1. **Practical, Production-Ready Patterns**: Not just "hello world" examples, but patterns you'd actually use in production
2. **Multi-Cloud Thinking**: When covering a concept, consider AWS, Azure, and GCP equivalents
3. **Certification Alignment**: Content aligns with industry certifications (AWS SAP, CKA/CKAD/CKS, Terraform Associate)
4. **Progressive Learning**: Material builds from fundamentals to advanced topics
5. **Real-World Context**: Examples should reflect actual production use cases and challenges

## Working with This Repository

### This is a Documentation Repository

Remember that this is not a software project with build/test/deploy workflows. There are:
- No package managers (npm, pip, cargo, etc.)
- No test suites to run
- No CI/CD pipelines (yet - though these could be added as examples)
- No application code to execute

### What You Can Help With

1. **Expanding Content**: Add new outlines, examples, scenarios, and cheatsheets
2. **Creating Examples**: Write Kubernetes manifests, Terraform modules, Ansible playbooks
3. **Documentation**: Improve clarity, add diagrams, create comparison tables
4. **Learning Plans**: Refine the roadmap, add daily tasks, include practice exercises
5. **Cross-References**: Link related concepts across different sections
6. **Validation**: Ensure examples follow current best practices and cloud provider conventions

### What to Avoid

1. Don't create application code or full applications - focus on infrastructure and configuration examples
2. Don't add dependencies or package.json files unless demonstrating a specific IaC tool installation
3. Don't create overly simplified examples - this is for professionals, show production patterns
4. Don't skip explanations - always explain WHY a pattern is used, not just WHAT it does

## Key Learning Concepts

### AWS SAP Focus Areas
- Multi-account architectures with AWS Organizations
- Hybrid connectivity (Direct Connect, Transit Gateway, VPN)
- High availability and disaster recovery patterns
- Cost optimization strategies
- Migration strategies (6 R's: Rehost, Replatform, Refactor, Repurchase, Retire, Retain)

### CNCF Production Patterns
- Resource management and QoS classes
- Deployment strategies (rolling, blue-green, canary)
- Security hardening (RBAC, Network Policies, Pod Security Standards)
- Observability stack (Prometheus, Grafana, Jaeger)
- GitOps workflows (ArgoCD, Flux)
- Service mesh patterns (Istio, Linkerd)

### Multi-Cloud Strategy
- Service equivalency across clouds
- Cloud-agnostic abstractions
- When to use which cloud for which workload
- Cross-cloud networking and disaster recovery
- Cost comparison methodologies

## Future Enhancements

Areas that could be expanded:
- Complete hands-on labs for each section
- Practice scenarios with solutions
- Architecture decision records (ADRs) for design choices
- Video tutorial scripts or references
- Interactive diagrams
- Certification practice questions (following exam guidelines)
