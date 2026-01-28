#!/usr/bin/env bats
#
# Integration tests for check_docker_security in molt-security-audit.sh
#

setup() {
    load '../test_helper/common-setup'
    source_moltaudit_functions
    reset_counters
    setup_test_home
}

teardown() {
    teardown_test_home
}

# =============================================================================
# Docker Not Installed Tests
# =============================================================================

@test "check_docker_security skips when docker not installed" {
    # Don't create docker mock
    activate_mocks

    JSON_MODE=false
    QUIET_MODE=false
    SKIP_COUNT=0

    run check_docker_security

    # Should skip, not fail
    assert_success
}

# =============================================================================
# Docker Group Tests
# =============================================================================

@test "check_docker_security warns when user is in docker group" {
    create_mock "docker" 0 ""
    create_mock "groups" 0 "user wheel docker"
    activate_mocks

    run groups
    assert_output --partial "docker"
}

@test "check_docker_security passes when user not in docker group" {
    create_mock "docker" 0 ""
    create_mock "groups" 0 "user wheel staff"
    activate_mocks

    run groups
    refute_output --partial "docker"
}

# =============================================================================
# Privileged Container Tests
# =============================================================================

@test "check_docker_security fails on privileged container" {
    create_mock "docker" 0 ""
    create_smart_mock "docker" << 'MOCK'
case "$1" in
    ps)
        echo "mycontainer"
        ;;
    inspect)
        cat << 'JSON'
[
  {
    "Name": "/mycontainer",
    "HostConfig": {
      "Privileged": true
    },
    "Config": {
      "User": "root"
    },
    "Mounts": []
  }
]
JSON
        ;;
esac
MOCK
    activate_mocks

    run docker inspect mycontainer
    assert_output --partial '"Privileged": true'
}

@test "check_docker_security passes on non-privileged container" {
    create_smart_mock "docker" << 'MOCK'
case "$1" in
    ps)
        echo "secure-container"
        ;;
    inspect)
        cat << 'JSON'
[
  {
    "Name": "/secure-container",
    "HostConfig": {
      "Privileged": false
    },
    "Config": {
      "User": "appuser"
    },
    "Mounts": []
  }
]
JSON
        ;;
esac
MOCK
    activate_mocks

    run docker inspect secure-container
    assert_output --partial '"Privileged": false'
}

# =============================================================================
# Docker Socket Mount Tests
# =============================================================================

@test "check_docker_security fails on docker socket mount" {
    create_smart_mock "docker" << 'MOCK'
case "$1" in
    ps)
        echo "dind-container"
        ;;
    inspect)
        cat << 'JSON'
[
  {
    "Name": "/dind-container",
    "HostConfig": {
      "Privileged": false,
      "Binds": ["/var/run/docker.sock:/var/run/docker.sock"]
    },
    "Config": {
      "User": ""
    },
    "Mounts": [
      {
        "Type": "bind",
        "Source": "/var/run/docker.sock",
        "Destination": "/var/run/docker.sock"
      }
    ]
  }
]
JSON
        ;;
esac
MOCK
    activate_mocks

    run docker inspect dind-container
    assert_output --partial "/var/run/docker.sock"
}

# =============================================================================
# Host Mount Tests
# =============================================================================

@test "check_docker_security fails on host filesystem mount" {
    create_smart_mock "docker" << 'MOCK'
case "$1" in
    ps)
        echo "host-mount-container"
        ;;
    inspect)
        cat << 'JSON'
[
  {
    "Name": "/host-mount-container",
    "HostConfig": {
      "Privileged": false,
      "Binds": ["/:/host"]
    },
    "Config": {
      "User": ""
    },
    "Mounts": [
      {
        "Type": "bind",
        "Source": "/",
        "Destination": "/host"
      }
    ]
  }
]
JSON
        ;;
esac
MOCK
    activate_mocks

    run docker inspect host-mount-container
    assert_output --partial '"Source": "/"'
}

# =============================================================================
# Root User Tests
# =============================================================================

@test "check_docker_security warns on container running as root" {
    create_smart_mock "docker" << 'MOCK'
case "$1" in
    ps)
        if [[ "$2" == "--format" ]]; then
            echo "root-container"
        fi
        ;;
    inspect)
        if [[ "$2" == "root-container" && "$3" == "--format" ]]; then
            echo "root"
        else
            cat << 'JSON'
[{"Config": {"User": "root"}}]
JSON
        fi
        ;;
esac
MOCK
    activate_mocks

    run docker inspect root-container --format '{{.Config.User}}'
    [[ "$output" == "root" || "$output" == "" ]]
}

@test "check_docker_security passes on container with non-root user" {
    create_smart_mock "docker" << 'MOCK'
case "$1" in
    ps)
        echo "secure-container"
        ;;
    inspect)
        if [[ "$3" == "--format" ]]; then
            echo "appuser"
        fi
        ;;
esac
MOCK
    activate_mocks

    run docker inspect secure-container --format '{{.Config.User}}'
    assert_output "appuser"
}

# =============================================================================
# No Running Containers Tests
# =============================================================================

@test "check_docker_security skips when no containers running" {
    create_smart_mock "docker" << 'MOCK'
case "$1" in
    ps)
        # Empty output
        ;;
esac
MOCK
    activate_mocks

    run docker ps --format '{{.Names}}'
    assert_output ""
}

# =============================================================================
# Permission Denied Tests
# =============================================================================

@test "check_docker_security handles permission denied gracefully" {
    create_smart_mock "docker" << 'MOCK'
echo "permission denied" >&2
exit 1
MOCK
    activate_mocks

    run docker ps
    assert_failure
}
