-- PACKAGE SPECIFICATION
CREATE OR REPLACE PACKAGE pkg_incident_mgmt IS

    e_invalid_status EXCEPTION;

    FUNCTION  count_by_status(p_status IN VARCHAR2) RETURN NUMBER;

    PROCEDURE change_status(
        p_incident_id IN NUMBER,
        p_new_status  IN VARCHAR2,
        p_changed_by  IN NUMBER
    );

    PROCEDURE print_incident_summary(p_incident_id IN NUMBER);

END pkg_incident_mgmt;
/

-- PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY pkg_incident_mgmt IS

    FUNCTION count_by_status(p_status IN VARCHAR2) RETURN NUMBER
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM incidents
        WHERE status = UPPER(p_status);

        RETURN v_count;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Error in count_by_status: ' || SQLERRM);
    END count_by_status;

    PROCEDURE change_status(
        p_incident_id IN NUMBER,
        p_new_status  IN VARCHAR2,
        p_changed_by  IN NUMBER
    )
    IS
        v_old_status incidents.status%TYPE;
        v_valid_statuses SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
            'OPEN','IN_PROGRESS','RESOLVED','CLOSED'
        );
        v_is_valid BOOLEAN := FALSE;
    BEGIN
        
        FOR i IN 1 .. v_valid_statuses.COUNT LOOP
            IF v_valid_statuses(i) = UPPER(p_new_status) THEN
                v_is_valid := TRUE;
            END IF;
        END LOOP;

        IF NOT v_is_valid THEN
            RAISE e_invalid_status;
        END IF;

        SELECT status INTO v_old_status
        FROM incidents WHERE incident_id = p_incident_id;

        UPDATE incidents
        SET status = UPPER(p_new_status),
            date_resolved = CASE WHEN UPPER(p_new_status) IN ('RESOLVED','CLOSED')
                                  THEN SYSDATE ELSE date_resolved END
        WHERE incident_id = p_incident_id;

        INSERT INTO incident_status_history (incident_id, old_status, new_status, changed_by)
        VALUES (p_incident_id, v_old_status, UPPER(p_new_status), p_changed_by);

        COMMIT;

    EXCEPTION
        WHEN e_invalid_status THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20011, 'Invalid status value: ' || p_new_status);
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012, 'Incident ' || p_incident_id || ' not found.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20013, 'Error changing status: ' || SQLERRM);
    END change_status;

    PROCEDURE print_incident_summary(p_incident_id IN NUMBER)
    IS
        CURSOR c_inc IS
            SELECT i.title, i.status, c.category_name, s.severity_name,
                   e1.first_name || ' ' || e1.last_name AS reporter,
                   e2.first_name || ' ' || e2.last_name AS assignee
            FROM incidents i
            JOIN incident_categories c ON i.category_id = c.category_id
            JOIN severity_levels s     ON i.severity_id = s.severity_id
            JOIN employees e1          ON i.reported_by = e1.emp_id
            LEFT JOIN employees e2     ON i.assigned_to = e2.emp_id
            WHERE i.incident_id = p_incident_id;

        v_rec c_inc%ROWTYPE;
    BEGIN
        OPEN c_inc;
        FETCH c_inc INTO v_rec;

        IF c_inc%NOTFOUND THEN
            DBMS_OUTPUT.PUT_LINE('No incident found with ID ' || p_incident_id);
        ELSE
            DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
            DBMS_OUTPUT.PUT_LINE('Incident: ' || v_rec.title);
            DBMS_OUTPUT.PUT_LINE('Status  : ' || v_rec.status);
            DBMS_OUTPUT.PUT_LINE('Category: ' || v_rec.category_name);
            DBMS_OUTPUT.PUT_LINE('Severity: ' || v_rec.severity_name);
            DBMS_OUTPUT.PUT_LINE('Reporter: ' || v_rec.reporter);
            DBMS_OUTPUT.PUT_LINE('Assignee: ' || NVL(v_rec.assignee, 'Unassigned'));
            DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
        END IF;

        CLOSE c_inc;
    EXCEPTION
        WHEN OTHERS THEN
            IF c_inc%ISOPEN THEN CLOSE c_inc; END IF;
            RAISE_APPLICATION_ERROR(-20014, 'Error printing summary: ' || SQLERRM);
    END print_incident_summary;

END pkg_incident_mgmt;
/

SET SERVEROUTPUT ON;
EXEC pkg_incident_mgmt.print_incident_summary(1);
EXEC pkg_incident_mgmt.change_status(2, 'IN_PROGRESS', 2);
SELECT pkg_incident_mgmt.count_by_status('OPEN') FROM dual;