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

## Phase II — Business Process Modeling
Actors (swimlanes): **Reporter → SOC Analyst → Security Manager → System**

Flow: Reporter submits incident → System timestamps and sets status OPEN →
Analyst reviews and self-assigns (status → IN_PROGRESS) → Analyst performs
response actions and logs them → Analyst resolves (status → RESOLVED) →
Manager reviews and closes (status → CLOSED). Every status transition is
recorded automatically by a trigger, independent of which actor triggers it.

*(Build this as a BPMN/UML diagram with swimlanes for one of your slides —
one lane per actor, boxes for each step above, arrows showing the flow.)*

## Phase III — Logical Database Design
10 entities in 3rd Normal Form:
`departments, employees, severity_levels, incident_categories, assets,
public_holidays, incidents, incident_status_history, response_actions,
audit_log`

- Every non-key attribute depends only on its table's primary key (2NF/3NF).
- Lookup data (severity, category) is separated from transactional data
  (incidents) so SLA/category definitions can change without touching
  historical incident records.
- `incident_status_history` exists specifically so the *current* status in
  `incidents` doesn't overwrite the *history* of status changes — this is
  what makes the audit requirement (Phase VII) possible.

See the ERD rendered earlier in this conversation for the full entity
relationship diagram with all foreign keys.

## Phase IV — Database Creation
```sql
-- Run as SYSDBA / a privileged user, replacing placeholders:
CREATE USER "<StudentID>_<FirstName>_CyberIncident_DB"
  IDENTIFIED BY "ChooseAStrongPassword123";

GRANT CONNECT, RESOURCE TO "<StudentID>_<FirstName>_CyberIncident_DB";
GRANT CREATE VIEW, CREATE SEQUENCE, CREATE TRIGGER, CREATE PROCEDURE
  TO "<StudentID>_<FirstName>_CyberIncident_DB";
ALTER USER "<StudentID>_<FirstName>_CyberIncident_DB" QUOTA UNLIMITED ON USERS;
```
Then connect as that user before running the scripts below in order.
Take an OEM (Enterprise Manager) or SQL Developer screenshot showing the
new user/schema for your documentation.

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
