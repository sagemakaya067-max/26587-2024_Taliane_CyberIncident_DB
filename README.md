# Cyber Security Incident Management System (CSIMS)


# 26587-2024_Taliane_CyberIncident_DB


## Phase I — Problem Statement
**Problem:** Organizations lack a centralized way to log, prioritize, and
track security incidents (phishing, malware, unauthorized access, data
breaches, DDoS). Incidents are tracked informally, response times aren't
measured against SLAs, and there is no audit trail of who changed what.

**Target users:** SOC analysts, security managers, general employees
(reporters), system administrators.

**Objectives:** centralize incident logging; enforce severity-based SLA
response times; maintain a full status-change history; audit all data
changes; restrict configuration changes to controlled maintenance windows.

**Expected benefits:** faster response, accountability, compliance-ready
audit trail, data-driven prioritization.



## PHASE II — Business Process Modeling

### System Scope
CSIMS covers the full lifecycle of a security incident, from initial report
to validated closure, with continuous automated oversight (audit logging,
SLA monitoring, access control on reference data).

### Actors
# Reporter (Employee): 
Detects and submits a security incident.
# System (automated):
Logs, timestamps, audits, monitors SLA, enforces access control.
# SOC Analyst:b 
Investigates, responds to, and resolves incidents.
# Security Manager:
Reviews and approves closure (separation of duties).

### Swimlane diagram
(Swimlane diagram image)

### One-page explanation
**Scope:** CSIMS covers the full lifecycle of a security incident, from
initial report to validated closure, with continuous automated oversight.

**Reporter lane:** any employee can detect and report an incident
(phishing, malware, unauthorized access, etc.) — this is the entry point.

**System lane (fully automated, driven by Oracle triggers):** timestamps
every incident on creation, automatically logs every status change with no
manual intervention required, continuously monitors response-time SLA
against severity level, and enforces the mandatory business rule blocking
configuration changes (severity levels, categories) on weekdays and public
holidays.

**SOC Analyst lane:** takes ownership of the incident, investigates,
executes response actions, and proposes resolution.

**Security Manager lane:** validates the resolution and formally closes the
incident — a two-person control, standard practice in security operations
to prevent a single analyst from silently closing incidents.

**End-to-end flow:** Detect → Report → Log (OPEN) → Assign (IN_PROGRESS) →
Investigate/Respond → Resolve (RESOLVED) → Review → Close (CLOSED), with
full traceability at every transition via the audit and history triggers.


## PHASE III — Logical Database Design

### Entity List (10 entities, all in 3NF)

# ER Diagram

### Normalization Proof (up to 3NF)
**1NF — Atomic values, no repeating groups:**
Every attribute above holds a single atomic value (no comma-separated lists,
no repeating columns like `action1, action2, action3`). Multi-valued facts
— an incident having *many* status changes or *many* response actions —
are modeled as separate child tables (`incident_status_history`,
`response_actions`) rather than repeating columns. This satisfies 1NF.

**2NF — No partial dependency on a composite key:**
Every table uses a single-column surrogate primary key (`*_id`, generated
by IDENTITY). Since no table has a composite primary key, partial
dependency is structurally impossible — 2NF is automatically satisfied.

**3NF — No transitive dependency (non-key attribute depending on another
non-key attribute):**
- In `employees`, `dept_id` determines the department, but department
  *details* (dept_name) live only in `departments` — not duplicated here.
- In `incidents`, `severity_id` and `category_id` are foreign keys;
  `response_time_hours` (a severity attribute) and `category_name`/
  `description` (category attributes) are **not** duplicated into
  `incidents` — they stay in their own lookup tables and are reached via
  JOIN. This is exactly what prevents transitive dependency: if
  `response_time_hours` were copied into every incident row, it would
  depend on `severity_id`, not on `incident_id` — a 3NF violation.
- Similarly, `asset_name`/`ip_address` stay in `assets`, not copied into
  `incidents`.

Because every non-key attribute in every table depends only on that
table's own primary key — the whole key, and nothing but the key — the
schema satisfies 3NF.

## Phase IV — Database Creation
(Database Creation sql script)

## Phase V — Table Implementation
Run in order:
1. `01_create_tables.sql` — all 10 tables, PK/FK/NOT NULL/UNIQUE/CHECK
2. `02_insert_sample_data.sql` — realistic sample rows

## Phase VI — PL/SQL Programming
- `03_procedures_functions.sql` — standalone function
  (`get_open_incidents_count`), three procedures (`report_incident`,
  `assign_incident`, `resolve_incident`), and one cursor-based procedure
  (`list_overdue_incidents`).
- `04_package_incident_mgmt.sql` — `pkg_incident_mgmt` package: groups
  `count_by_status`, `change_status`, `print_incident_summary` under one
  package spec/body, with a custom exception (`e_invalid_status`) and a
  ROWTYPE cursor.

All DML uses explicit `COMMIT`/`ROLLBACK` and `EXCEPTION` blocks — no
silent failures.

## Phase VII — Advanced Database Programming
- `05_triggers_audit.sql`:
  - `trg_incidents_audit` — row-level AFTER trigger logging every
    INSERT/UPDATE/DELETE on `incidents` into `audit_log` (who/when/what).
  - `trg_incidents_status_history` — automatically records every status
    change, so the history is captured even if someone updates the table
    directly (not just through the package).
  - `is_restricted_day` — helper function checking weekday + holiday.
  - `trg_protect_severity_levels` / `trg_protect_incident_categories` —
    **compound triggers** implementing the required business rule: block
    INSERT/UPDATE/DELETE on Mon-Fri and on any date listed in
    `public_holidays`. Applied to the reference/config tables rather than
    `incidents` itself, since incidents must be logged 24/7 — be ready to
    explain this design choice in your defense.


5. The difference between the standalone procedures (Phase VI) and the
   package (also Phase VI) — why group some logic into a package.
