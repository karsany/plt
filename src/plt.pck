Create Or Replace Package plt Is
  /***
  * PL/SQL Unit Test Tool
  */

  co_pkg_name Constant Varchar2(30) := 'plt';
  co_version  Constant Varchar2(30) := 'v1.0.0';

  /***
  * Runs all testcases from packages
  * Package name have to begin with "plt$"
  * Runs plt_setup method from package before start tests
  * Runs plt_setup_tc method from package before any test cases
  * Runs all methods beginning with tc_, alphabetically
  * Runs plt_teardown method from package after any
  */
  Procedure run_test_package(package_name In Varchar2);

  /***
  * Configuring the PLT Test tool.
  * Use in the plt_setup method, if you want to change the defaults.
  *
  * Settings VAR - VAL :         description
  * OUTPUT - HTML :              HTML output on dbms output
  * OUTPUT - TXT  :              Text putput on dbms output (default)
  */
  Procedure config(var In Varchar2
                  ,val In Varchar2);

  /***
  * Output helper functions
  */
  Procedure print_header(s In Varchar2);

  /***
  * Assert procedures
  */

  Procedure assert_true(msg In Varchar2
                       ,b   In Boolean);

  Procedure assert_false(msg In Varchar2
                        ,b   In Boolean);

  Procedure assert_null(msg In Varchar2
                       ,s   In Varchar2);

  Procedure assert_null(msg In Varchar2
                       ,n   In Number);

  Procedure assert_null(msg In Varchar2
                       ,d   In Date);

  Procedure assert_equal(msg In Varchar2
                        ,s1  In Varchar2
                        ,s2  In Varchar2);

  Procedure assert_equal(msg In Varchar2
                        ,n1  In Number
                        ,n2  In Number);

  Procedure assert_equal(msg In Varchar2
                        ,d1  In Date
                        ,d2  In Date);

End plt;
/
Create Or Replace Package Body plt Is

  g_test_case_nr Pls_Integer := 0;
  g_test_case_ok Pls_Integer := 0;

  g_html_mode Boolean := False;

  Procedure print(s In Varchar2) Is
  Begin
    dbms_output.put_line(s);
  End print;

  Procedure print_header1(s In Varchar2) Is
  Begin
    If g_html_mode
    Then
      print('<tr><td colspan=5><h1>' || s || '</h1></td></tr>');
    Else
      print('=====================================');
      print('  ' || s);
      print('=====================================');
    End If;
  End print_header1;

  Procedure print_header2(s In Varchar2) Is
  Begin
    If g_html_mode
    Then
      print('<tr><td colspan=5><h2>' || s || '</h2></td></tr>');
    Else
      print('-------------------------------------');
      print('  ' || s);
      print('-------------------------------------');
    End If;
  End print_header2;

  Procedure print_header3(s In Varchar2) Is
  Begin
    If g_html_mode
    Then
      print('<tr><td colspan=5><h3>' || s || '</h3></td></tr>');
    Else
      print('');
      print('  ' || s);
      print('-------------------------------------');
    End If;
  End print_header3;

  Procedure print_header(s In Varchar2) Is
  Begin
    print_header3(s);
  End print_header;

  Procedure run_test_package(package_name In Varchar2) Is
    v_count Number;
  Begin
    g_test_case_nr := 0;
    g_test_case_ok := 0;
  
    If g_html_mode
    Then
      print('<table border="1">');
    End If;
    print_header1('TEST RUN : ' || package_name);
  
    Select Count(*)
      Into v_count
      From user_procedures
     Where object_name = upper(Trim(package_name))
       And procedure_name = 'PLT_SETUP';
  
    If v_count = 1
    Then
      Execute Immediate 'BEGIN ' || package_name || '.PLT_SETUP; END;';
    End If;
  
    Select Count(*)
      Into v_count
      From user_procedures
     Where object_name = upper(Trim(package_name))
       And procedure_name = 'PLT_SETUP_TC';
  
    For c_row In (Select *
                    From user_procedures
                   Where object_name = upper(Trim(package_name))
                     And procedure_name Like 'TC\_%' Escape '\')
    Loop
      print_header2('TEST CASE: ' || c_row.procedure_name);
      If v_count = 1
      Then
        Execute Immediate 'BEGIN ' || package_name || '.PLT_SETUP_TC; END;';
      End If;
      Execute Immediate 'BEGIN ' || package_name || '.' || c_row.procedure_name || '; END;';
    End Loop;
  
    Select Count(*)
      Into v_count
      From user_procedures
     Where object_name = upper(Trim(package_name))
       And procedure_name = 'PLT_TEARDOWN';
  
    If v_count = 1
    Then
      Execute Immediate 'BEGIN ' || package_name || '.PLT_TEARDOWN; END;';
    End If;
  
    If g_html_mode
    Then
      print('<tr><td>TESTS: ' || g_test_case_nr || '</td><td>OK: ' || g_test_case_ok ||
            '</td><td>FAILED : ' || (g_test_case_nr - g_test_case_ok) || '</td><td>RATIO: ' ||
            round(g_test_case_ok * 100 / g_test_case_nr, 2) || '%</td><td></td></tr>');
    
    Else
      print_header1('TESTS: ' || g_test_case_nr || ' OK: ' || g_test_case_ok || ' FAILED : ' ||
                    (g_test_case_nr - g_test_case_ok) || ' RATIO: ' ||
                    round(g_test_case_ok * 100 / g_test_case_nr, 2) || '%');
      Null;
    End If;
  
    If g_html_mode
    Then
      print('</table>');
    End If;
  
  End run_test_package;

  Procedure config(var In Varchar2
                  ,val In Varchar2) Is
  Begin
    If var = 'OUTPUT'
    Then
      If val = 'HTML'
      Then
        g_html_mode := True;
      Else
        g_html_mode := False;
      End If;
    End If;
  End config;

  Procedure print_test_case_ok(msg In Varchar2) Is
  Begin
    If g_html_mode
    Then
      print('<tr bgcolor="#aaffaa"><td>[ OK ]</td><td>' || lpad(g_test_case_nr, 4) || '</td><td>' || msg ||
            '</td><td></td><td></td></tr>');
    Else
      print('[ OK ] ' || lpad(g_test_case_nr, 4) || ' ' || msg);
    End If;
  
  End print_test_case_ok;

  Procedure print_test_case_fail(msg      In Varchar2
                                ,expected In Varchar2
                                ,got      In Varchar2) Is
  Begin
    If g_html_mode
    Then
      print('<tr bgcolor="#ffaaaa"><td>[FAIL]</td><td>' || lpad(g_test_case_nr, 4) || '</td><td>' || msg ||
            '</td><td>' || expected || '</td><td>' || got || '</td></tr>');
    Else
      print('[FAIL] ' || lpad(g_test_case_nr, 4) || ' ' || msg);
      print('            ' || 'EXPECTED: <' || expected || '> GOT: <' || got || '>');
    End If;
  End print_test_case_fail;

  Procedure assert(msg      In Varchar2
                  ,b        In Boolean
                  ,expected In Varchar2
                  ,got      In Varchar2) Is
  Begin
  
    g_test_case_nr := g_test_case_nr + 1;
  
    If b
    Then
      g_test_case_ok := g_test_case_ok + 1;
      print_test_case_ok(msg);
    Else
      print_test_case_fail(msg, expected, got);
    End If;
  
  End assert;

  -------------------------------------------

  Procedure assert_true(msg In Varchar2
                       ,b   In Boolean) Is
  Begin
    assert(msg, b, 'TRUE', Case When b Is Null Then 'NULL' When b Then 'TRUE' Else 'FALSE' End);
  End assert_true;

  Procedure assert_false(msg In Varchar2
                        ,b   In Boolean) Is
  Begin
    assert(msg
          ,Not b
          ,'FALSE'
          ,Case When b Is Null Then 'NULL' When b Then 'TRUE' Else 'FALSE' End);
  End assert_false;

  Procedure assert_null(msg In Varchar2
                       ,s   In Varchar2) Is
  Begin
    assert(msg, s Is Null, Null, s);
  End assert_null;

  Procedure assert_null(msg In Varchar2
                       ,n   In Number) Is
  Begin
    assert(msg, n Is Null, Null, n);
  End assert_null;

  Procedure assert_null(msg In Varchar2
                       ,d   In Date) Is
  Begin
    assert(msg, d Is Null, Null, d);
  End assert_null;

  Procedure assert_equal(msg In Varchar2
                        ,s1  In Varchar2
                        ,s2  In Varchar2) Is
  Begin
    assert(msg, (s1 Is Null And s2 Is Null) Or (s1 = s2), s1, s2);
  End assert_equal;

  Procedure assert_equal(msg In Varchar2
                        ,n1  In Number
                        ,n2  In Number) Is
  Begin
    assert(msg, (n1 Is Null And n2 Is Null) Or (n1 = n2), n1, n2);
  End assert_equal;

  Procedure assert_equal(msg In Varchar2
                        ,d1  In Date
                        ,d2  In Date) Is
  Begin
    assert(msg, (d1 Is Null And d2 Is Null) Or (d1 = d2), d1, d2);
  End assert_equal;

End plt;
/
