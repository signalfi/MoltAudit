#!/usr/bin/env bats
#
# Unit tests for helper functions in molt-security-audit.sh
#

setup() {
    load '../test_helper/common-setup'
    source_moltaudit_functions
}

# =============================================================================
# command_exists tests
# =============================================================================

@test "command_exists returns 0 for existing command (bash)" {
    run command_exists bash
    assert_success
}

@test "command_exists returns 1 for non-existing command" {
    run command_exists nonexistent_command_xyz123
    assert_failure
}

@test "command_exists returns 0 for builtin commands" {
    run command_exists echo
    assert_success
}

# =============================================================================
# json_escape tests
# =============================================================================

@test "json_escape handles simple strings" {
    run json_escape "hello world"
    assert_success
    assert_output "hello world"
}

@test "json_escape escapes double quotes" {
    run json_escape 'say "hello"'
    assert_success
    assert_output 'say \"hello\"'
}

@test "json_escape escapes backslashes" {
    run json_escape 'path\to\file'
    assert_success
    assert_output 'path\\to\\file'
}

@test "json_escape escapes newlines" {
    run json_escape $'line1\nline2'
    assert_success
    assert_output 'line1\nline2'
}

@test "json_escape escapes tabs" {
    run json_escape $'col1\tcol2'
    assert_success
    assert_output 'col1\tcol2'
}

@test "json_escape handles empty string" {
    run json_escape ""
    assert_success
    assert_output ""
}

@test "json_escape handles complex mixed content" {
    run json_escape $'Error: "file\tnot found"\nPath: C:\\Users'
    assert_success
    assert_output 'Error: \"file\tnot found\"\nPath: C:\\Users'
}

# =============================================================================
# get_timestamp tests
# =============================================================================

@test "get_timestamp returns ISO 8601 format" {
    run get_timestamp
    assert_success
    # Format: YYYY-MM-DDTHH:MM:SSZ
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
}

@test "get_timestamp returns UTC time (ends with Z)" {
    run get_timestamp
    assert_success
    [[ "$output" == *"Z" ]]
}

@test "get_timestamp year is reasonable" {
    run get_timestamp
    assert_success
    local year="${output:0:4}"
    [[ $year -ge 2024 && $year -le 2100 ]]
}
