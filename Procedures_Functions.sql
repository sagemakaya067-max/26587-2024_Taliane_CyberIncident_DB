
-- FUNCTION: get_open_incidents_count
CREATE OR REPLACE FUNCTION get_open_incidents_count(p_dept_id IN NUMBER)
RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM incidents i
    JOIN assets a ON i.asset_id = a.asset_id
    WHERE a.dept_id = p_dept_id
      AND i.status IN ('OPEN','IN_PROGRESS');

    RETURN v_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error counting open incidents: ' || SQLERRM);
END get_open_incidents_count;
/

-- PROCEDURE: report_incident
CREATE OR REPLACE PROCEDURE report_incident (
    p_title        IN  VARCHAR2,
    p_description  IN  VARCHAR2,
    p_category_id  IN  NUMBER,
    p_severity_id  IN  NUMBER,
    p_asset_id     IN  NUMBER,
    p_reported_by  IN  NUMBER,
    p_incident_id  OUT NUMBER
)
IS
    e_invalid_reporter EXCEPTION;
    v_dummy NUMBER;
BEGIN
    
    BEGIN
        SELECT 1 INTO v_dummy FROM employees WHERE emp_id = p_reported_by;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_invalid_reporter;
    END;

    INSERT INTO incidents (title, description, category_id, severity_id,
                            asset_id, reported_by, status, date_reported)
    VALUES (p_title, p_description, p_category_id, p_severity_id,
            p_asset_id, p_reported_by, 'OPEN', SYSDATE)
    RETURNING incident_id INTO p_incident_id;

    COMMIT;

EXCEPTION
    WHEN e_invalid_reporter THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Reporter employee ID does not exist.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Error reporting incident: ' || SQLERRM);
END report_incident;
/

-- PROCEDURE: assign_incident
CREATE OR REPLACE PROCEDURE assign_incident (
    p_incident_id IN NUMBER,
    p_analyst_id  IN NUMBER
)
IS
    v_old_status incidents.status%TYPE;
    e_incident_not_found EXCEPTION;
BEGIN
    SELECT status INTO v_old_status
    FROM incidents
    WHERE incident_id = p_incident_id;

    UPDATE incidents
    SET assigned_to = p_analyst_id,
        status = 'IN_PROGRESS'
    WHERE incident_id = p_incident_id;

    INSERT INTO incident_status_history (incident_id, old_status, new_status, changed_by)
    VALUES (p_incident_id, v_old_status, 'IN_PROGRESS', p_analyst_id);

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Incident ID ' || p_incident_id || ' not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'Error assigning incident: ' || SQLERRM);
END assign_incident;
/

-- PROCEDURE: resolve_incident
CREATE OR REPLACE PROCEDURE resolve_incident (
    p_incident_id  IN NUMBER,
    p_action_desc  IN VARCHAR2,
    p_employee_id  IN NUMBER
)
IS
    v_old_status incidents.status%TYPE;
BEGIN
    SELECT status INTO v_old_status FROM incidents WHERE incident_id = p_incident_id;

    UPDATE incidents
    SET status = 'RESOLVED',
        date_resolved = SYSDATE
    WHERE incident_id = p_incident_id;

    INSERT INTO response_actions (incident_id, action_description, action_by)
    VALUES (p_incident_id, p_action_desc, p_employee_id);

    INSERT INTO incident_status_history (incident_id, old_status, new_status, changed_by)
    VALUES (p_incident_id, v_old_status, 'RESOLVED', p_employee_id);

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Incident ID ' || p_incident_id || ' not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'Error resolving incident: ' || SQLERRM);
END resolve_incident;
/

-- CURSOR EXAMPLE: list overdue incidents
CREATE OR REPLACE PROCEDURE list_overdue_incidents
IS
    CURSOR c_overdue IS
        SELECT i.incident_id, i.title, s.severity_name,
               i.date_reported, s.response_time_hours
        FROM incidents i
        JOIN severity_levels s ON i.severity_id = s.severity_id
        WHERE i.status IN ('OPEN','IN_PROGRESS')
          AND SYSDATE > i.date_reported + (s.response_time_hours / 24);
BEGIN
    FOR rec IN c_overdue LOOP
        DBMS_OUTPUT.PUT_LINE('OVERDUE -> Incident #' || rec.incident_id ||
                              ' | ' || rec.title ||
                              ' | Severity: ' || rec.severity_name ||
                              ' | SLA(h): ' || rec.response_time_hours);
    END LOOP;

    IF c_overdue%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No overdue incidents.');
    END IF;
END list_overdue_incidents;
/


EXEC list_overdue_incidents;
SELECT get_open_incidents_count(1) FROM dual;