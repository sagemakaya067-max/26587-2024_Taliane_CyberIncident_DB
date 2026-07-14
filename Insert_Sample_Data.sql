-- Departments
INSERT INTO departments (dept_name) VALUES ('IT Security');
INSERT INTO departments (dept_name) VALUES ('Finance');
INSERT INTO departments (dept_name) VALUES ('Human Resources');
INSERT INTO departments (dept_name) VALUES ('Operations');

-- Employees (mix of roles across departments)
INSERT INTO employees (first_name, last_name, email, phone, dept_id, emp_role)
VALUES ('Alcia', 'Milebou', 'alcia.milebou@company.rw', '0793903634', 1, 'ADMIN');

INSERT INTO employees (first_name, last_name, email, phone, dept_id, emp_role)
VALUES ('Sage', 'Moussavou', 'sage.moussavou@company.rw', '0798977313', 1, 'ANALYST');

INSERT INTO employees (first_name, last_name, email, phone, dept_id, emp_role)
VALUES ('Tine', 'Mevoule', 'tine.mevoule@company.rw', '0793951882', 1, 'MANAGER');

INSERT INTO employees (first_name, last_name, email, phone, dept_id, emp_role)
VALUES ('Cyr', 'Allila', 'cyr.allila@company.rw', '0798980038', 2, 'REPORTER');

INSERT INTO employees (first_name, last_name, email, phone, dept_id, emp_role)
VALUES ('Esther', 'Avoume', 'esther.avoume@company.rw', '0798976225', 3, 'REPORTER');

INSERT INTO employees (first_name, last_name, email, phone, dept_id, emp_role)
VALUES ('Adol', 'Makaya', 'adol.makaya@company.rw', '0788666666', 4, 'REPORTER');

-- Severity levels (drives SLA / response time in hours)
INSERT INTO severity_levels (severity_name, response_time_hours) VALUES ('LOW', 72);
INSERT INTO severity_levels (severity_name, response_time_hours) VALUES ('MEDIUM', 24);
INSERT INTO severity_levels (severity_name, response_time_hours) VALUES ('HIGH', 8);
INSERT INTO severity_levels (severity_name, response_time_hours) VALUES ('CRITICAL', 2);

-- Incident categories
INSERT INTO incident_categories (category_name, description)
VALUES ('Phishing', 'Fraudulent email or message attempting credential theft');

INSERT INTO incident_categories (category_name, description)
VALUES ('Malware', 'Malicious software detected on an endpoint or server');

INSERT INTO incident_categories (category_name, description)
VALUES ('Unauthorized Access', 'Login or access attempt without proper authorization');

INSERT INTO incident_categories (category_name, description)
VALUES ('Data Breach', 'Confirmed or suspected exposure of sensitive data');

INSERT INTO incident_categories (category_name, description)
VALUES ('DDoS', 'Distributed denial-of-service attack against a service');

-- Assets
INSERT INTO assets (asset_name, asset_type, ip_address, dept_id)
VALUES ('FIN-DB-01', 'DATABASE', '10.10.2.15', 2);

INSERT INTO assets (asset_name, asset_type, ip_address, dept_id)
VALUES ('HR-WORKSTATION-07', 'WORKSTATION', '10.10.3.22', 3);

INSERT INTO assets (asset_name, asset_type, ip_address, dept_id)
VALUES ('WEB-APP-PORTAL', 'APPLICATION', '10.10.1.5', 1);

INSERT INTO assets (asset_name, asset_type, ip_address, dept_id)
VALUES ('CORE-SWITCH-01', 'NETWORK_DEVICE', '10.10.0.1', 1);

-- Public holidays (Rwanda 2026 examples - adjust to your actual calendar)
INSERT INTO public_holidays (holiday_date, holiday_name) VALUES (DATE '2026-01-01', 'New Year');
INSERT INTO public_holidays (holiday_date, holiday_name) VALUES (DATE '2026-04-07', 'Genocide Memorial Day');
INSERT INTO public_holidays (holiday_date, holiday_name) VALUES (DATE '2026-07-01', 'Independence Day');
INSERT INTO public_holidays (holiday_date, holiday_name) VALUES (DATE '2026-07-04', 'Liberation Day');
INSERT INTO public_holidays (holiday_date, holiday_name) VALUES (DATE '2026-12-25', 'Christmas Day');

-- Incidents (sample transactional records)
INSERT INTO incidents (title, description, category_id, severity_id, asset_id, reported_by, assigned_to, status, date_reported)
VALUES ('Suspicious login attempt on FIN-DB-01', 'Multiple failed logins from foreign IP',
        3, 3, 1, 4, 2, 'IN_PROGRESS', SYSDATE - 3);

INSERT INTO incidents (title, description, category_id, severity_id, asset_id, reported_by, assigned_to, status, date_reported)
VALUES ('Phishing email reported by HR staff', 'Email impersonating IT support requesting password',
        1, 2, 2, 5, 2, 'OPEN', SYSDATE - 1);

INSERT INTO incidents (title, description, category_id, severity_id, asset_id, reported_by, assigned_to, status, date_reported, date_resolved)
VALUES ('Malware detected on web portal', 'Antivirus flagged a trojan on WEB-APP-PORTAL',
        2, 4, 3, 6, 2, 'RESOLVED', SYSDATE - 10, SYSDATE - 8);

INSERT INTO incidents (title, description, category_id, severity_id, asset_id, reported_by, assigned_to, status, date_reported)
VALUES ('DDoS attack against core switch', 'Abnormal traffic spike detected',
        5, 4, 4, 2, 3, 'OPEN', SYSDATE);

COMMIT;


SELECT incident_id, title, status, date_reported FROM incidents ORDER BY incident_id;