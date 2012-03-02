package require Expectvariable logDir "../logs"proc init_log_files { {log_dir $logDir} } {    # Log file paths    global logRunning    global logDebug    global logTest    global logCli    # The log file name will include data at which script was run    set file_data [clock format [clock seconds] -format %Y_%m_%d_%H_%M_%S]    set logRunning ${file_data}_running.log    set logDebug ${file_data}_debug.log    set logTest ${file_data}_test.log    set logCli ${file_data}_cli.log    # Verify whether log_dir exists. Otherwise create it    if {[file isdirectory $log_dir] != 1} {      puts "$log_dir does not exist. Creating the new directory."      file mkdir $log_dir    }    # Ensure that new log files are empty    close [open $log_dir/$logRunning w]    close [open $log_dir/$logDebug w]    close [open $log_dir/$logTest w]    close [open $log_dir/$logCli w]}##################################################################################################### logFile: Sends log messages to running log debun log error log and also#          displays the log message to standard output.## IN:  text: message you want to send to log files#      args: color: Not used. Keept just for compatibility with older versions.#            debug: send the log message to the debug log#            PASS:  send a Jets compatible PASS message and also send this message to#                   message to running log#            FAIL:  send a Jets compatible FAIL message and also send this message to#                   message to running log#            error: Not used. Keept just for compatibility with older versions.# OUT:#####################################################################################################proc logFile {text args} {    global logRunning logDebug logError    global logDir    set first_arg [lindex $args 0]    ###################################################    # If no args then just send text to the running log    #    if {$args == "" || $first_arg == "color"} {        if {[catch {set fileId [open $logDir/$logRunning a+ 0600]} err]} {            puts "ERROR: logFile proc - fail to open $logDir/$logRunning file:\n$err"        } else {            puts "$text"            puts $fileId $text            close $fileId        }        #############################################        #  PASS/FAIL jets compatible logging messages        #    } elseif {$first_arg == "PASS" || $first_arg == "FAIL" || $first_arg == "ABORT"} {        if {[catch {set fileId [open $logDir/$logRunning a+ 0600]} err]} {            puts "ERROR: logFile proc - fail to open $logDir/$logRunning file:\n$err"        } else {            puts "\n****$first_arg: $text\n"            puts $fileId "****$first_arg: $text"            close $fileId        }        #####################################################################        #  If we get debug for args then we need to send it to the debug log.        #    } elseif {$first_arg == "debug" || $first_arg == "DEBUG"} {        if {[catch {set fileId [open $logDir/$logDebug a+ 0600]} err]} {            puts "ERROR: logFile proc - fail to open $logDir/$logDebug file:\n$err"        } else {            puts $fileId "$text"            close $fileId        }        ##############################################################################        # If we get error for args then we need to raise a bug and log it to error log        #        # Don't know yet how to use error log and if it is useful        # at this moment debug log and running logs seems to be enough        # error log was just keept for compatibility with old versions.        #        # } elseif {$first_arg == "error"} {        #     if {[catch {set fileId [open $logDir/$logError a+ 0600]} err]} {        #          puts "ERROR: logFile proc - fail to open $logDir/$logError file:\n$err"        # } else {        #     puts $fileId "$text"        #     close $fileId        # }    }    catch {close $fileId} err}################################################################ Global:testdone################################################################proc Global:testdone {passCheck test {ip ""} args} {    global testCount    logTest $test $passCheck $ip}##################################################################################################### logTest: Sends log messages to the test log (test name, PASS/FAIL ...)#          Usualy it is called from Global:getlist#####################################################################################################proc logTest {test result {ip ""}} {    global logTest    global logDir    global testsCount passCount failCount skippedCount    global allTestsCount allPassCount allFailCount allSkippedCount    if {[catch {set fileId [open $logDir/$logTest a+ 0600]} err]} {        # do nothing    } else {        set time [clock format [clock seconds] -format "%a %b %d %T"]        if {[regexp -nocase "fail" $result]} {            set result " *FAIL*"            #//CES version            incr failCount            incr allFailCount        }        if {[regexp -nocase "coredump" $result]} {            set result "**FAIL (CoreDump)**"            #//CES version            incr testsCount -1            incr allTestsCount -1        }        if {[regexp -nocase pass $result]} {            set result "  PASS "            #//CES version            incr passCount            incr allPassCount        }        if {[regexp -nocase "skipped" $result] || [regexp -nocase "abort" $result]} {            set result " *ABORT*"            #//CES version            incr skippedCount            incr allSkippedCount        }        #//CES version        incr testsCount        incr allTestsCount        set data [format "%-30s %-10s %-10s" $test $result $time]        puts $fileId $data        close $fileId    }}##################################################################################################### startTestLog: Sends log messages relating to test start#               in running log, CLI log and standard output.##               The message sent to standard output and to CLI#               log is in the format required by Jets framework:##               ****Start Test:<Name>## IN:  test_name## OUT:#####################################################################################################proc testStartLog {test_name} {    logFile "\n\n**** Start Test: $test_name" color yellow    send_log "\n\n\n**** Start Test: $test_name\n"}##################################################################################################### testPurposeLog: Sends to the standard output and running log,#                 messages about:#                 - test purpose#                 - test description##                 The message sent to standard output has#                 the format required by Jets framework:##                 ****Test Purpose:#                 ****Start Description:#                 ****End Description:#####################################################################################################proc testPurposeLog {purpose description} {    logFile "\n**** Test Purpose: $purpose"    logFile "**** Start Description:"    logFile "$description"    logFile "**** End Description:\n"}##################################################################################################### endTestLog: Sends log messages relating to test end to#             test log, running log, cli log, and standard#             output.##             The message sent to standard output and to CLI#             log is in the format required by Jets framework:##             ****End Test:<Name>## IN:  test_name#      test_result: PASS, FAIL, ABORT (case sensitive)## OUT:#####################################################################################################proc testEndLog {test_name test_result} {    set test_result [string toupper $test_result]    switch -regexp $test_result {        "PASS" {            # message to running log and standard output            logFile "\n****PASS: test case: $test_name"            logFile "****End Test: $test_name"            # wait 2 sec before start next test            after 2000            # message to CLI log            send_log "\n\n\n****End Test: $test_name\n"            # message to test log            Global:testdone "PASS" $test_name        }        "ABORT" {            logFile "\n****ABORT: test case: $test_name" color red            logFile "****End Test: $test_name"            # wait 2 sec before start next test            after 2000            send_log "\n\n\n****End Test: $test_name\n"            Global:testdone "ABORT" $test_name        }        default {            logFile "\n****FAIL: test case: $test_name" color red            logFile "****End Test: $test_name"            # wait 2 sec before start next test            after 2000            send_log "\n\n\n****End Test: $test_name\n"            Global:testdone "FAIL" $test_name        }    }}############################################## startSuiteLog: Sends log messages relating to suite start#                in running log, CLI log and standard output.##                The message sent to standard output and to CLI#                log is in the format required by Jets framework:##                ****Start Suite:<Name>## IN:  suite_name## OUT:##############################################proc suiteStartLog {suite_name} {    send_log "\n\n**** Start Suite: $suite_name\n\n"    logFile "\n\n**** Start Suite: $suite_name"    logFile "\n\n -> Suite $suite_name: SETUP"}############################################## startTestLog: Sends log messages relating to suite end#               in running log, CLI log and standard output.##               The message sent to standard output and to CLI#               log is in the format required by Jets framework:##               ****End Suite:<Name>## IN:  suite_name## OUT:##############################################proc suiteEndLog {suite_name} {    logFile "\n\n -> Suite $suite_name: END"    logFile "\n\n**** End Suite: $suite_name"    send_log "\n\n**** End Suite: $suite_name\n\n"}