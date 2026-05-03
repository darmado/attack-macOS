#!/usr/bin/env python3
"""
Attack-macOS Decryption Tool

Description:
    Clean, modular decryption tool for data encrypted by attack-macOS scripts.
    Supports AES-256-CBC, GPG symmetric, and XOR decryption methods.
    Uses only Python standard library - no third-party dependencies.

Author: @darmado | https://x.com/darmad0
Version: 1.0
Date: 2025-05-27

Supported Methods:
    - AES-256-CBC (via openssl subprocess)
    - GPG symmetric (via gpg subprocess) 
    - XOR (native Python implementation)

Usage:
    python3 decrypt.py --method aes --key <key> --data <encrypted_data>
    python3 decrypt.py --method gpg --key <key> --data <encrypted_data>
    python3 decrypt.py --method xor --key <key> --data <encrypted_data>
    python3 decrypt.py --method auto --key <key> --data <encrypted_data>
    
    # From file
    python3 decrypt.py --method aes --key <key> --file <encrypted_file>
    
    # Interactive mode
    python3 decrypt.py --interactive
"""

import sys
import os
import subprocess
import base64
import argparse
import json
from typing import Optional, Dict, Any, Tuple


class DecryptionError(Exception):
    """Custom exception for decryption errors"""
    pass


class AttackMacOSDecryptor:
    """
    Main decryption class for attack-macOS encrypted data
    
    Supports multiple encryption methods used by the framework:
    - AES-256-CBC (OpenSSL)
    - GPG symmetric encryption
    - XOR encryption (custom implementation)
    """
    
    def __init__(self, verbose: bool = False):
        """
        Initialize the decryptor
        
        Args:
            verbose: Enable verbose output for debugging
        """
        self.verbose = verbose
        self.supported_methods = ['aes', 'gpg', 'xor', 'auto']
    
    def log(self, message: str) -> None:
        """Log message if verbose mode is enabled"""
        if self.verbose:
            print(f"[DEBUG] {message}", file=sys.stderr)
    
    def detect_encryption_method(self, encrypted_data: str) -> str:
        """
        Attempt to detect encryption method from data format
        
        Args:
            encrypted_data: The encrypted data string
            
        Returns:
            Detected method name or 'unknown'
        """
        # Remove whitespace
        data = encrypted_data.strip()
        
        # GPG armored data
        if data.startswith('-----BEGIN PGP MESSAGE-----'):
            self.log("Detected GPG armored format")
            return 'gpg'
        
        # XOR format (custom format: XOR-ENCRYPTED:hex_data:key_hint)
        if data.startswith('XOR-ENCRYPTED:'):
            self.log("Detected XOR custom format")
            return 'xor'
        
        # Try to decode as base64 - could be AES or other
        try:
            decoded = base64.b64decode(data)
            if len(decoded) > 0:
                self.log("Detected base64 format - likely AES")
                return 'aes'
        except Exception:
            pass
        
        self.log("Could not detect encryption method")
        return 'unknown'
    
    def decrypt_aes(self, encrypted_data: str, key: str) -> str:
        """
        Decrypt AES-256-CBC encrypted data using OpenSSL
        
        Args:
            encrypted_data: Base64 encoded AES encrypted data
            key: Decryption key
            
        Returns:
            Decrypted plaintext
            
        Raises:
            DecryptionError: If decryption fails
        """
        self.log(f"Attempting AES decryption with key length: {len(key)}")
        
        try:
            # Use openssl to decrypt (same as the shell script)
            cmd = ['openssl', 'enc', '-aes-256-cbc', '-d', '-base64', '-k', key]
            
            process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate(input=encrypted_data)
            
            if process.returncode != 0:
                raise DecryptionError(f"OpenSSL decryption failed: {stderr}")
            
            self.log("AES decryption successful")
            return stdout
            
        except FileNotFoundError:
            raise DecryptionError("OpenSSL not found. Please install OpenSSL.")
        except Exception as e:
            raise DecryptionError(f"AES decryption error: {str(e)}")
    
    def decrypt_gpg(self, encrypted_data: str, key: str) -> str:
        """
        Decrypt GPG symmetric encrypted data
        
        Args:
            encrypted_data: GPG armored encrypted data
            key: Decryption passphrase
            
        Returns:
            Decrypted plaintext
            
        Raises:
            DecryptionError: If decryption fails
        """
        self.log(f"Attempting GPG decryption")
        
        try:
            # Use gpg to decrypt (same options as shell script)
            cmd = [
                'gpg', '--batch', '--yes', '--quiet', '--decrypt',
                '--cipher-algo', 'AES256', '--passphrase', key
            ]
            
            process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate(input=encrypted_data)
            
            if process.returncode != 0:
                raise DecryptionError(f"GPG decryption failed: {stderr}")
            
            self.log("GPG decryption successful")
            return stdout
            
        except FileNotFoundError:
            raise DecryptionError("GPG not found. Please install GPG.")
        except Exception as e:
            raise DecryptionError(f"GPG decryption error: {str(e)}")
    
    def decrypt_xor(self, encrypted_data: str, key: str) -> str:
        """
        Decrypt XOR encrypted data (custom implementation)
        
        Args:
            encrypted_data: XOR encrypted data in custom format
            key: XOR key
            
        Returns:
            Decrypted plaintext
            
        Raises:
            DecryptionError: If decryption fails
        """
        self.log(f"Attempting XOR decryption with key: {key[:8]}...")
        
        try:
            # Handle custom XOR format: XOR-ENCRYPTED:hex_data:key_hint
            if encrypted_data.startswith('XOR-ENCRYPTED:'):
                # Parse the custom format
                parts = encrypted_data.split(':')
                if len(parts) >= 3:
                    # Decode from base64 first (as the shell script does)
                    base64_data = ':'.join(parts[1:])
                    decoded = base64.b64decode(base64_data)
                    # Extract hex data and key hint
                    decoded_str = decoded.decode('utf-8')
                    if ':' in decoded_str:
                        hex_data, key_hint = decoded_str.split(':', 1)
                        self.log(f"Extracted hex data length: {len(hex_data)}, key hint: {key_hint}")
                    else:
                        hex_data = decoded_str
                else:
                    raise DecryptionError("Invalid XOR format")
            else:
                # Assume it's direct hex data
                hex_data = encrypted_data
            
            # Convert hex to bytes
            try:
                encrypted_bytes = bytes.fromhex(hex_data)
            except ValueError:
                raise DecryptionError("Invalid hex data in XOR encrypted string")
            
            # Perform XOR decryption
            key_bytes = key.encode('utf-8')
            decrypted_bytes = bytearray()
            
            for i, byte in enumerate(encrypted_bytes):
                key_byte = key_bytes[i % len(key_bytes)]
                decrypted_bytes.append(byte ^ key_byte)
            
            decrypted_text = decrypted_bytes.decode('utf-8')
            self.log("XOR decryption successful")
            return decrypted_text
            
        except Exception as e:
            raise DecryptionError(f"XOR decryption error: {str(e)}")
    
    def decrypt(self, method: str, encrypted_data: str, key: str) -> str:
        """
        Main decryption method that routes to specific decryption functions
        
        Args:
            method: Encryption method ('aes', 'gpg', 'xor', 'auto')
            encrypted_data: Encrypted data string
            key: Decryption key
            
        Returns:
            Decrypted plaintext
            
        Raises:
            DecryptionError: If method is unsupported or decryption fails
        """
        if method not in self.supported_methods:
            raise DecryptionError(f"Unsupported method: {method}")
        
        # Auto-detect method if requested
        if method == 'auto':
            detected_method = self.detect_encryption_method(encrypted_data)
            if detected_method == 'unknown':
                raise DecryptionError("Could not auto-detect encryption method")
            method = detected_method
            self.log(f"Auto-detected method: {method}")
        
        # Route to appropriate decryption method
        if method == 'aes':
            return self.decrypt_aes(encrypted_data, key)
        elif method == 'gpg':
            return self.decrypt_gpg(encrypted_data, key)
        elif method == 'xor':
            return self.decrypt_xor(encrypted_data, key)
        else:
            raise DecryptionError(f"Method {method} not implemented")


def parse_json_data(json_str: str) -> Tuple[str, Dict[str, Any]]:
    """
    Parse JSON output from attack-macOS scripts to extract encrypted data
    
    Args:
        json_str: JSON string from attack-macOS script
        
    Returns:
        Tuple of (encrypted_data, metadata)
    """
    try:
        data = json.loads(json_str)
        
        # Extract metadata
        metadata = {
            'timestamp': data.get('timestamp'),
            'command': data.get('command'),
            'jobId': data.get('jobId'),
            'procedure': data.get('procedure'),
            'encoding': data.get('encoding', {}),
            'encryption': data.get('encryption', {}),
            'steganography': data.get('steganography', {})
        }
        
        # Extract encrypted data
        if 'data' in data and isinstance(data['data'], list):
            # Join all data lines
            encrypted_data = '\n'.join(str(item) for item in data['data'])
        else:
            encrypted_data = str(data.get('data', ''))
        
        return encrypted_data, metadata
        
    except json.JSONDecodeError as e:
        raise DecryptionError(f"Invalid JSON data: {str(e)}")


def interactive_mode():
    """Interactive mode for decryption"""
    print("=== Attack-macOS Interactive Decryption Tool ===")
    print("Supported methods: aes, gpg, xor, auto")
    print()
    
    decryptor = AttackMacOSDecryptor(verbose=True)
    
    while True:
        try:
            # Get method
            method = input("Encryption method (aes/gpg/xor/auto) [auto]: ").strip().lower()
            if not method:
                method = 'auto'
            
            if method not in decryptor.supported_methods:
                print(f"Error: Unsupported method '{method}'")
                continue
            
            # Get key
            key = input("Decryption key: ").strip()
            if not key:
                print("Error: Key cannot be empty")
                continue
            
            # Get data
            print("Enter encrypted data (press Enter twice to finish):")
            lines = []
            while True:
                line = input()
                if line == "" and lines and lines[-1] == "":
                    break
                lines.append(line)
            
            encrypted_data = '\n'.join(lines).strip()
            if not encrypted_data:
                print("Error: No data provided")
                continue
            
            # Check if it's JSON
            if encrypted_data.startswith('{'):
                try:
                    data, metadata = parse_json_data(encrypted_data)
                    print(f"\n=== Metadata ===")
                    for key, value in metadata.items():
                        print(f"{key}: {value}")
                    encrypted_data = data
                except DecryptionError as e:
                    print(f"JSON parsing error: {e}")
                    continue
            
            # Decrypt
            try:
                decrypted = decryptor.decrypt(method, encrypted_data, key)
                print(f"\n=== Decrypted Data ===")
                print(decrypted)
                print("=" * 50)
                
            except DecryptionError as e:
                print(f"Decryption error: {e}")
            
            # Continue?
            if input("\nDecrypt another? (y/N): ").strip().lower() != 'y':
                break
                
        except KeyboardInterrupt:
            print("\nExiting...")
            break
        except EOFError:
            print("\nExiting...")
            break


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Attack-macOS Decryption Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Decrypt AES data
  python3 decrypt.py --method aes --key mykey --data "U2FsdGVkX1..."
  
  # Auto-detect method
  python3 decrypt.py --method auto --key mykey --data "encrypted_data"
  
  # Decrypt from file
  python3 decrypt.py --method aes --key mykey --file encrypted.txt
  
  # Interactive mode
  python3 decrypt.py --interactive
        """
    )
    
    parser.add_argument('--method', '-m', 
                       choices=['aes', 'gpg', 'xor', 'auto'],
                       help='Decryption method')
    
    parser.add_argument('--key', '-k',
                       help='Decryption key/passphrase')
    
    parser.add_argument('--data', '-d',
                       help='Encrypted data string')
    
    parser.add_argument('--file', '-f',
                       help='File containing encrypted data')
    
    parser.add_argument('--interactive', '-i',
                       action='store_true',
                       help='Interactive mode')
    
    parser.add_argument('--verbose', '-v',
                       action='store_true',
                       help='Verbose output')
    
    parser.add_argument('--json',
                       action='store_true',
                       help='Parse input as JSON from attack-macOS script')
    
    args = parser.parse_args()
    
    # Interactive mode
    if args.interactive:
        interactive_mode()
        return
    
    # Validate arguments
    if not args.method:
        parser.error("Method is required (or use --interactive)")
    
    if not args.key:
        parser.error("Key is required (or use --interactive)")
    
    if not args.data and not args.file:
        parser.error("Either --data or --file is required (or use --interactive)")
    
    # Get encrypted data
    if args.file:
        try:
            with open(args.file, 'r') as f:
                encrypted_data = f.read().strip()
        except IOError as e:
            print(f"Error reading file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        encrypted_data = args.data
    
    # Parse JSON if requested
    if args.json:
        try:
            data, metadata = parse_json_data(encrypted_data)
            if args.verbose:
                print("=== Metadata ===", file=sys.stderr)
                for key, value in metadata.items():
                    print(f"{key}: {value}", file=sys.stderr)
                print("", file=sys.stderr)
            encrypted_data = data
        except DecryptionError as e:
            print(f"JSON parsing error: {e}", file=sys.stderr)
            sys.exit(1)
    
    # Decrypt
    try:
        decryptor = AttackMacOSDecryptor(verbose=args.verbose)
        decrypted = decryptor.decrypt(args.method, encrypted_data, args.key)
        print(decrypted)
        
    except DecryptionError as e:
        print(f"Decryption error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main() 