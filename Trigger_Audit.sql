
-- TRIGGER 1: trg_incidents_audit
CREATE OR REPLACE TRIGGER trg_incidents_audit
AFTER INSERT OR UPDATE OR DELETE ON incidents
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_val   VARCHAR2(1000);
    v_new_val   VARCHAR2(1000);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_val   := 'title=' || :NEW.title || '; status=' || :NEW.status;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_val   := 'status=' || :OLD.status;
        v_new_val   := 'status=' || :NEW.status;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_val   := 'title=' || :OLD.title || '; status=' || :OLD.status;
    END IF;

    INSERT INTO audit_log (table_name, operation, record_id, old_value, new_value)
    VALUES ('INCIDENTS', v_operation,
            NVL(:NEW.incident_id, :OLD.incident_id),
            v_old_val, v_new_val);
END trg_incidents_audit;
/

-- TRIGGER 2: trg_incidents_status_history
CREATE OR REPLACE TRIGGER trg_incidents_status_history
AFTER UPDATE OF status ON incidents
FOR EACH ROW
WHEN (OLD.status IS NULL OR NEW.status != OLD.status OR OLD.status != NEW.status)
BEGIN
    IF :OLD.status != :NEW.status THEN
        INSERT INTO incident_status_history (incident_id, old_status, new_status, changed_by)
        VALUES (:NEW.incident_id, :OLD.status, :NEW.status, NULL);
    END IF;
END trg_incidents_status_history;
/

-- ---------------------------------------------------------------------
-- HELPER FUNCTION: is_restricted_day
CREATE OR REPLACE FUNCTION is_restricted_day RETURN VARCHAR2 IS
    v_day        VARCHAR2(3);
    v_is_holiday NUMBER;
BEGIN
    v_day := TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH');

    SELECT COUNT(*) INTO v_is_holiday
    FROM public_holidays
    WHERE holiday_date = TRUNC(SYSDATE);

    IF v_day IN ('MON','TUE','WED','THU','FRI') OR v_is_holiday > 0 THEN
        RETURN 'Y';
    ELSE
        RETURN 'N';
    END IF;
END is_restricted_day;
/

-- TRIGGER 3 (COMPOUND TRIGGER): trg_protect_reference_data
CREATE OR REPLACE TRIGGER trg_protect_severity_levels
FOR INSERT OR UPDATE OR DELETE ON severity_levels
COMPOUND TRIGGER

    v_blocked VARCHAR2(1) := 'N';

    BEFORE STATEMENT IS
    BEGIN
        v_blocked := is_restricted_day;
        IF v_blocked = 'Y' THEN
            RAISE_APPLICATION_ERROR(-20020,
                'Changes to severity_levels are blocked on weekdays and public holidays. ' ||
                'Please perform configuration changes during the weekend maintenance window.');
        END IF;
    END BEFORE STATEMENT;

END trg_protect_severity_levels;
/

CREATE OR REPLACE TRIGGER trg_protect_incident_categories
FOR INSERT OR UPDATE OR DELETE ON incident_categories
COMPOUND TRIGGER

    v_blocked VARCHAR2(1) := 'N';

    BEFORE STATEMENT IS
    BEGIN
        v_blocked := is_restricted_day;
        IF v_blocked = 'Y' THEN
            RAISE_APPLICATION_ERROR(-20021,
                'Changes to incident_categories are blocked on weekdays and public holidays. ' ||
                'Please perform configuration changes during the weekend maintenance window.');
        END IF;
    END BEFORE STATEMENT;

END trg_protect_incident_categories;
/


INSERT INTO severity_levels (severity_name, response_time_hours)
VALUES ('TEST', 5);


SELECT * FROM audit_log ORDER BY action_date DESC;
SELECT * FROM incident_status_history ORDER BY change_date DESC;