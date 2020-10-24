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
        with t(date_list, next_date, stop) as (
            select to_char(trunc(to_date(''' || PR_CUR_TIME || '''), ''HH24'')) date_list,
                   to_char(trunc(to_date(''' || PR_CUR_TIME || '''), ''HH24'') + (interval ''15'' minute)) next_date,
                   0 stop from dual
        
            union all
            
            select to_char(to_date(date_list) + (interval ''15'' minute)) date_list,
                   to_char(to_date(date_list) + (interval ''15'' minute)*2) next_date,
                   case when 
                            to_char(to_date(next_date), ''MM'') in (' || l_months || ')
                        and to_char(to_date(next_date), ''DD'') in (' || l_monthdays || ') 
                        and to_char(to_date(next_date), ''d'') in (' || l_weekdays || ')
                        and to_char(to_date(next_date), ''HH24'') in ('  || l_hours || ')
                        and to_char(to_date(next_date), ''MI'') in (' || l_quarters || ')
                        and to_date(next_date) >= to_date(''' || PR_CUR_TIME || ''')
                   then 1 else 0 end stop
            from t
            where stop = 0
            )
        cycle date_list set cycle to 1 default 0
        select date_list
        from t
        where stop = 1';

    execute immediate l_sql into l_date;

    return l_date;
END SCHEDULER;