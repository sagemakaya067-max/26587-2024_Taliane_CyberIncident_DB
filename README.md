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
(ER Diagram image)

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
Database_Creation.sql

## Phase V — Table Implementation
Create_Tables.sql
Insert_Sample_Data.sql

## Phase VI — PL/SQL Programming
 Procédures_Fonctions.sql
 Packages_Incident_Management.sql

## Phase VII — Advanced Database Programming
Trigger_Audit.sql

## Queries Explanation
SET SERVEROUTPUT ON;

-- 1. All open/in-progress incidents with severity and category names
SELECT i.incident_id, i.title, c.category_name, s.severity_name, i.status, i.date_reported
FROM incidents i
JOIN incident_categories c ON i.category_id = c.category_id
JOIN severity_levels s     ON i.severity_id = s.severity_id
WHERE i.status IN ('OPEN','IN_PROGRESS')
ORDER BY s.response_time_hours;

-- 2. Incident count per department (uses the standalone function)
SELECT d.dept_name, get_open_incidents_count(d.dept_id) AS open_incidents
FROM departments d
ORDER BY open_incidents DESC;

-- 3. Full audit trail for a given incident
SELECT * FROM incident_status_history WHERE incident_id = 1 ORDER BY change_date;

-- 4. Everything the audit trigger has captured so far
SELECT audit_id, table_name, operation, db_user, action_date, old_value, new_value
FROM audit_log
ORDER BY action_date DESC;

-- 5. Call the package to print a readable incident summary
EXEC pkg_incident_mgmt.print_incident_summary(1);

-- 6. Change a status through the package (fires both triggers automatically)
EXEC pkg_incident_mgmt.change_status(2, 'RESOLVED', 2);

-- 7. Check overdue incidents against SLA (cursor-based procedure)
EXEC list_overdue_incidents;

-- 8. Demonstrate the business-rule trigger blocking a weekday change
-- (Run this on a Mon-Fri to see ORA-20020/20021 raised)
-- INSERT INTO severity_levels (severity_name, response_time_hours) VALUES ('TEST', 1);
