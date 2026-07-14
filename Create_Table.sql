-- 1. DEPARTMENTS  (independent entity - no FKs)
CREATE TABLE departments (
    dept_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dept_name   VARCHAR2(100) NOT NULL UNIQUE
);

-- 2. EMPLOYEES  (reporters, analysts, managers, admins)
CREATE TABLE employees (
    emp_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  VARCHAR2(50)  NOT NULL,
    last_name   VARCHAR2(50)  NOT NULL,
    email       VARCHAR2(100) NOT NULL UNIQUE,
    phone       VARCHAR2(20),
    dept_id     NUMBER NOT NULL,
    emp_role    VARCHAR2(20)  NOT NULL,
    CONSTRAINT fk_emp_dept   FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    CONSTRAINT chk_emp_role  CHECK (emp_role IN ('REPORTER','ANALYST','MANAGER','ADMIN'))
);

-- 3. SEVERITY_LEVELS  (lookup table - drives SLA response time)
CREATE TABLE severity_levels (
    severity_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    severity_name        VARCHAR2(20) NOT NULL UNIQUE,
    response_time_hours  NUMBER NOT NULL,
    CONSTRAINT chk_sev_name  CHECK (severity_name IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT chk_sev_time  CHECK (response_time_hours > 0)
);

-- 4. INCIDENT_CATEGORIES  (lookup table)
CREATE TABLE incident_categories (
    category_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name  VARCHAR2(100) NOT NULL UNIQUE,
    description    VARCHAR2(300)
);

-- 5. ASSETS  (systems/devices that can be affected by an incident)
CREATE TABLE assets (
    asset_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_name   VARCHAR2(100) NOT NULL,
    asset_type   VARCHAR2(50),
    ip_address   VARCHAR2(50),
    dept_id      NUMBER,
    CONSTRAINT fk_asset_dept  FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    CONSTRAINT chk_asset_type CHECK (asset_type IN
        ('SERVER','WORKSTATION','NETWORK_DEVICE','DATABASE','APPLICATION','MOBILE_DEVICE'))
);

-- 6. PUBLIC_HOLIDAYS  (reference table used by the business-rule trigger)
CREATE TABLE public_holidays (
    holiday_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    holiday_date  DATE NOT NULL UNIQUE,
    holiday_name  VARCHAR2(100) NOT NULL
);

-- 7. INCIDENTS  (the core transactional table)
CREATE TABLE incidents (
    incident_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title          VARCHAR2(150) NOT NULL,
    description    VARCHAR2(1000),
    category_id    NUMBER NOT NULL,
    severity_id    NUMBER NOT NULL,
    asset_id       NUMBER,
    reported_by    NUMBER NOT NULL,
    assigned_to    NUMBER,
    status         VARCHAR2(20) DEFAULT 'OPEN' NOT NULL,
    date_reported  DATE DEFAULT SYSDATE NOT NULL,
    date_resolved  DATE,
    CONSTRAINT fk_inc_category  FOREIGN KEY (category_id) REFERENCES incident_categories(category_id),
    CONSTRAINT fk_inc_severity  FOREIGN KEY (severity_id) REFERENCES severity_levels(severity_id),
    CONSTRAINT fk_inc_asset     FOREIGN KEY (asset_id)    REFERENCES assets(asset_id),
    CONSTRAINT fk_inc_reporter  FOREIGN KEY (reported_by) REFERENCES employees(emp_id),
    CONSTRAINT fk_inc_assignee  FOREIGN KEY (assigned_to) REFERENCES employees(emp_id),
    CONSTRAINT chk_inc_status   CHECK (status IN ('OPEN','IN_PROGRESS','RESOLVED','CLOSED')),
    CONSTRAINT chk_inc_dates    CHECK (date_resolved IS NULL OR date_resolved >= date_reported)
);

-- 8. INCIDENT_STATUS_HISTORY  (full audit trail of status changes)
CREATE TABLE incident_status_history (
    history_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    incident_id   NUMBER NOT NULL,
    old_status    VARCHAR2(20),
    new_status    VARCHAR2(20) NOT NULL,
    changed_by    NUMBER,
    change_date   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_hist_incident FOREIGN KEY (incident_id) REFERENCES incidents(incident_id),
    CONSTRAINT fk_hist_emp      FOREIGN KEY (changed_by)  REFERENCES employees(emp_id)
);

-- 9. RESPONSE_ACTIONS  (what the SOC team did to handle an incident)
CREATE TABLE response_actions (
    action_id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    incident_id         NUMBER NOT NULL,
    action_description  VARCHAR2(500) NOT NULL,
    action_by           NUMBER NOT NULL,
    action_date         DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_action_incident FOREIGN KEY (incident_id) REFERENCES incidents(incident_id),
    CONSTRAINT fk_action_emp      FOREIGN KEY (action_by)   REFERENCES employees(emp_id)
);

-- 10. AUDIT_LOG  (generic audit table populated by triggers)
CREATE TABLE audit_log (
    audit_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name   VARCHAR2(50)  NOT NULL,
    operation    VARCHAR2(10)  NOT NULL,
    db_user      VARCHAR2(50)  DEFAULT USER,
    action_date  DATE          DEFAULT SYSDATE,
    record_id    NUMBER,
    old_value    VARCHAR2(1000),
    new_value    VARCHAR2(1000)
);

COMMIT;

SELECT table_name FROM user_tables ORDER BY table_name;