#!/bin/bash
# Auto-generated test for modify_security_settings.sh

# Test with all options
../attackmacos/ttp/defense_evasion/shell/modify_security_settings.sh --gatekeeper-defaults "test_value" --appfw-socketfilter "test_value" --appfw-defaults "test_value" --gatekeeper-spctl "test_value" --restore-defaults --show-security-settings --set-blockall "test_value" --set-stealthmode "test_value" --set-loggingmode "test_value" --block-app "test_value" --unblock-app "test_value" --remove-app "test_value" --disable-sip --disable-authenticated-root --reset-login-items --erase-logs --disable-quarantine
