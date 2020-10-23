CREATE OR REPLACE FUNCTION SCHEDULER 
(
  PR_CUR_TIME IN DATE 
, PR_SCHEDULE_MATRIX IN VARCHAR2 
) RETURN DATE AS 
    l_quarters varchar2(100);
    l_hours varchar2(100);
    l_weekdays varchar2(100);
    l_monthdays varchar2(100);
    l_months varchar2(100);
    l_date date;
    l_sql varchar(4000);
    
    function f_split_by_semicolon(pr_martix varchar2, pr_rownum integer) return varchar2 as
        l_result varchar2(100);
    begin
        select regexp_substr(pr_martix, '[^;]+', 1, level)
        into l_result from dual where level = pr_rownum
        connect by regexp_substr(pr_martix, '[^;]+', 1, level) is not null;
        return l_result;
    end;

BEGIN
    if regexp_substr(PR_SCHEDULE_MATRIX, '^[0-9,;]*$') is null then raise VALUE_ERROR; end if;
    
    l_quarters := f_split_by_semicolon(PR_SCHEDULE_MATRIX, 1);
    l_hours := f_split_by_semicolon(PR_SCHEDULE_MATRIX, 2);
    l_weekdays := f_split_by_semicolon(PR_SCHEDULE_MATRIX, 3);
    l_monthdays := f_split_by_semicolon(PR_SCHEDULE_MATRIX, 4);
    l_months := f_split_by_semicolon(PR_SCHEDULE_MATRIX, 5);

    l_sql := '
        select min(date_list) from (
            select trunc(to_date(''' || PR_CUR_TIME || ''', ''DD.MM.YY HH24:MI:SS''), ''HH24'') + (rownum-1)*(interval ''15'' minute) date_list
            from dual
            connect by level <= 35712
        )
        where     to_char(date_list, ''MM'') in (' || l_months || ')
              and to_char(date_list, ''DD'') in (' || l_monthdays || ') 
              and to_char(date_list, ''d'') in (' || l_weekdays || ')
              and to_char(date_list, ''HH24'') in ('  || l_hours || ')
              and to_char(date_list, ''MI'') in (' || l_quarters || ')
              and date_list >= to_date(''' || PR_CUR_TIME || ''', ''DD.MM.YY HH24:MI:SS'')';
    
    execute immediate l_sql into l_date;

    return l_date;
END SCHEDULER;