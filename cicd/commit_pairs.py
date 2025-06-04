#!/usr/bin/env python3
"""
Intelligent YAML+Script commit tool.

Analyzes changes in YAML configuration files and corresponding shell scripts,
then generates intelligent commit messages based on actual modifications.
"""

import os
import sys
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import subprocess
import difflib

try:
    import git
    from git import Repo
except ImportError:
    print("GitPython not found. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "GitPython", "--break-system-packages"])
    import git
    from git import Repo

try:
    import yaml
except ImportError:
    print("PyYAML not found. Installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "PyYAML", "--break-system-packages"])
    import yaml


class IntelligentCommitter:
    def __init__(self, repo_path: str = "."):
        """Initialize with repository path."""
        try:
            # Try to find the git repository root
            current_dir = Path(repo_path).resolve()
            
            # Look for .git directory in current and parent directories
            search_dir = current_dir
            while search_dir.parent != search_dir:  # Stop at filesystem root
                if (search_dir / '.git').exists():
                    self.repo = Repo(str(search_dir))
                    self.repo_path = search_dir
                    print(f"📁 Found Git repository at: {self.repo_path}")
                    return
                search_dir = search_dir.parent
            
            # If no .git found, try current directory anyway
            self.repo = Repo(repo_path)
            self.repo_path = Path(repo_path).resolve()
            
        except Exception as e:
            print(f"Error initializing repository: {e}")
            # Try parent directory as fallback
            parent_path = Path(repo_path).parent
            try:
                self.repo = Repo(str(parent_path))
                self.repo_path = parent_path.resolve()
                print(f"📁 Using parent directory as repository: {self.repo_path}")
            except Exception as e2:
                raise Exception(f"Could not find Git repository. Tried current dir and parent: {e2}")
        
    def get_modified_pairs(self) -> List[Tuple[str, str]]:
        """Get modified YAML+script pairs from git status."""
        pairs = []
        
        # Get all modified files
        modified_files = [item.a_path for item in self.repo.index.diff(None)]
        modified_files.extend([item.a_path for item in self.repo.index.diff('HEAD')])
        
        # Find YAML files
        yaml_files = [f for f in modified_files if f.endswith('.yml') and 'attackmacos/core/config/' in f]
        
        for yaml_file in yaml_files:
            procedure_name = Path(yaml_file).stem
            
            # Skip template files
            if procedure_name == "procedure":
                continue
                
            # Find corresponding shell script
            script_files = [f for f in modified_files if f.endswith('.sh') and procedure_name in f]
            
            if script_files:
                # Take the first matching script
                script_file = script_files[0]
                pairs.append((yaml_file, script_file))
                print(f"📋 Found pair: {procedure_name}")
                print(f"   YAML: {yaml_file}")
                print(f"   Script: {script_file}")
            else:
                print(f"⚠️  No matching script found for: {procedure_name}")
                
        return pairs
    
    def get_standalone_files(self) -> List[str]:
        """Get important standalone files that should be committed separately."""
        # Get all modified files
        modified_files = [item.a_path for item in self.repo.index.diff(None)]
        modified_files.extend([item.a_path for item in self.repo.index.diff('HEAD')])
        
        standalone_files = []
        
        # Important standalone patterns
        important_patterns = [
            'attackmacos/core/base/base.sh',  # Core framework
            'cicd/sync_function_docs.py',    # Build tools
            'cicd/commit_pairs.py',          # Build tools
            'docs/Functions/Shell/',         # Documentation
            'docs/Guides/',                  # Documentation
            'attackmacos/core/config/procedure.yml'  # Template
        ]
        
        for file_path in modified_files:
            # Skip files already in pairs
            if any(file_path.endswith('.yml') and 'attackmacos/core/config/' in file_path and 
                   Path(file_path).stem != "procedure" for _ in [None]):
                continue
            if any(file_path.endswith('.sh') and any(Path(f).stem in file_path for f in modified_files 
                   if f.endswith('.yml') and 'attackmacos/core/config/' in f) for _ in [None]):
                continue
                
            # Check if it matches important patterns
            for pattern in important_patterns:
                if pattern in file_path:
                    standalone_files.append(file_path)
                    print(f"📄 Found standalone: {Path(file_path).name}")
                    print(f"   Path: {file_path}")
                    break
        
        return standalone_files
    
    def analyze_standalone_changes(self, file_path: str) -> Dict[str, any]:
        """Analyze what changed in a standalone file."""
        try:
            diff = self.repo.git.diff('HEAD', file_path)
            
            changes = {
                'file_type': self.get_file_type(file_path),
                'major_changes': False,
                'new_functions': [],
                'documentation_updates': False,
                'build_system_changes': False,
                'core_framework_changes': False
            }
            
            added_lines = [line[1:] for line in diff.split('\n') if line.startswith('+') and not line.startswith('+++')]
            
            # Analyze by file type
            if 'base.sh' in file_path:
                changes['core_framework_changes'] = True
                # Look for new functions
                for line in added_lines:
                    if 'core_' in line and '()' in line:
                        func_match = re.search(r'(core_\w+)\(\)', line)
                        if func_match:
                            changes['new_functions'].append(func_match.group(1))
                            
            elif 'docs/' in file_path:
                changes['documentation_updates'] = True
                
            elif 'cicd/' in file_path:
                changes['build_system_changes'] = True
                
            # Check for major changes (lots of additions)
            if len(added_lines) > 20:
                changes['major_changes'] = True
                
            return changes
            
        except Exception as e:
            print(f"Error analyzing standalone changes: {e}")
            return {'file_type': 'unknown'}
    
    def get_file_type(self, file_path: str) -> str:
        """Determine the type of file for categorization."""
        if 'base.sh' in file_path:
            return 'core_framework'
        elif 'docs/' in file_path:
            return 'documentation'
        elif 'cicd/' in file_path:
            return 'build_system'
        elif file_path.endswith('.yml'):
            return 'configuration'
        elif file_path.endswith('.sh'):
            return 'script'
        else:
            return 'other'
    
    def generate_standalone_commit_message(self, file_path: str, changes: Dict) -> str:
        """Generate commit message for standalone files."""
        file_name = Path(file_path).name
        file_type = changes.get('file_type', 'unknown')
        
        if file_type == 'core_framework':
            title = "Update core framework (base.sh):"
            details = []
            
            if changes.get('new_functions'):
                title += " new functions and enhancements"
                details.append(f"- Added functions: {', '.join(changes['new_functions'][:3])}")
            else:
                title += " enhanced functionality"
                
            if changes.get('major_changes'):
                details.append("- Major framework improvements")
            
            details.extend([
                "- Updated core function implementations",
                "- Enhanced framework capabilities",
                "- Applied coding standards"
            ])
            
        elif file_type == 'documentation':
            title = f"Update documentation: {file_name}"
            details = [
                "- Updated function documentation",
                "- Enhanced code examples and usage",
                "- Improved clarity and accuracy"
            ]
            
        elif file_type == 'build_system':
            title = f"Update build system: {file_name}"
            details = [
                "- Enhanced build and deployment tools",
                "- Improved automation and workflows",
                "- Updated development utilities"
            ]
            
        else:
            title = f"Update {file_name}: enhanced implementation"
            details = [
                "- Updated implementation",
                "- Applied best practices"
            ]
        
        message = title + "\n\n" + "\n".join(details)
        return message
    
    def commit_standalone(self, file_path: str) -> bool:
        """Commit a standalone file with intelligent message."""
        try:
            file_name = Path(file_path).name
            
            print(f"\n🔍 Analyzing standalone file: {file_name}...")
            
            # Analyze changes
            changes = self.analyze_standalone_changes(file_path)
            
            # Generate commit message
            commit_message = self.generate_standalone_commit_message(file_path, changes)
            
            print(f"📝 Generated commit message:")
            print(f"{commit_message}")
            print()
            
            # Stage and commit file
            self.repo.index.add([file_path])
            self.repo.index.commit(commit_message)
            
            # Push to remote
            origin = self.repo.remote('origin')
            origin.push()
            
            print(f"✅ Committed and pushed: {file_name}")
            return True
            
        except Exception as e:
            print(f"❌ Error committing {file_name}: {e}")
            return False
    
    def analyze_yaml_changes(self, yaml_path: str) -> Dict[str, any]:
        """Analyze what changed in a YAML file."""
        try:
            # Get diff from git
            diff = self.repo.git.diff('HEAD', yaml_path)
            
            changes = {
                'new_fields': [],
                'modified_fields': [],
                'removed_fields': [],
                'mitre_changes': False,
                'function_changes': False,
                'config_changes': False
            }
            
            # Parse diff lines
            added_lines = [line[1:] for line in diff.split('\n') if line.startswith('+') and not line.startswith('+++')]
            removed_lines = [line[1:] for line in diff.split('\n') if line.startswith('-') and not line.startswith('---')]
            
            # Analyze key patterns
            for line in added_lines:
                if 'mitre_attack' in line.lower() or 'ttp_id' in line.lower():
                    changes['mitre_changes'] = True
                elif 'function' in line.lower() or 'procedure' in line.lower():
                    changes['function_changes'] = True
                elif any(key in line.lower() for key in ['config', 'param', 'setting', 'option']):
                    changes['config_changes'] = True
                    
                # Extract field names
                if ':' in line:
                    field = line.split(':')[0].strip()
                    if field and not field.startswith('#'):
                        changes['new_fields'].append(field)
            
            return changes
            
        except Exception as e:
            print(f"Error analyzing YAML changes: {e}")
            return {}
    
    def analyze_script_changes(self, script_path: str) -> Dict[str, any]:
        """Analyze what changed in a shell script."""
        try:
            # Get diff from git
            diff = self.repo.git.diff('HEAD', script_path)
            
            changes = {
                'new_functions': [],
                'modified_functions': [],
                'security_improvements': False,
                'performance_improvements': False,
                'bug_fixes': False,
                'obfuscation_changes': False
            }
            
            # Parse diff lines
            added_lines = [line[1:] for line in diff.split('\n') if line.startswith('+') and not line.startswith('+++')]
            removed_lines = [line[1:] for line in diff.split('\n') if line.startswith('-') and not line.startswith('---')]
            
            # Analyze patterns
            for line in added_lines:
                if 'function' in line and '()' in line:
                    func_name = re.search(r'(\w+)\(\)', line)
                    if func_name:
                        changes['new_functions'].append(func_name.group(1))
                
                # Security patterns
                if any(term in line.lower() for term in ['encrypt', 'obfuscat', 'steganograph', 'base64']):
                    changes['security_improvements'] = True
                    
                # Performance patterns  
                if any(term in line.lower() for term in ['optim', 'faster', 'efficien', 'cache']):
                    changes['performance_improvements'] = True
                    
                # Bug fix patterns
                if any(term in line.lower() for term in ['fix', 'error', 'bug', 'correct']):
                    changes['bug_fixes'] = True
                    
                # Obfuscation patterns
                if any(term in line.lower() for term in ['eval', 'exec', 'construct', 'dynamic']):
                    changes['obfuscation_changes'] = True
            
            return changes
            
        except Exception as e:
            print(f"Error analyzing script changes: {e}")
            return {}
    
    def generate_intelligent_commit_message(self, procedure_name: str, yaml_changes: Dict, script_changes: Dict) -> str:
        """Generate intelligent commit message based on changes."""
        
        # Start with base message
        title = f"Update {procedure_name}:"
        
        # Analyze changes to determine focus
        focus_areas = []
        details = []
        
        # YAML analysis
        if yaml_changes.get('mitre_changes'):
            focus_areas.append("MITRE ATT&CK alignment")
            details.append("- Updated MITRE ATT&CK technique mapping")
            
        if yaml_changes.get('function_changes'):
            focus_areas.append("function configuration")
            details.append("- Enhanced function definitions and parameters")
            
        if yaml_changes.get('config_changes'):
            focus_areas.append("configuration")
            details.append("- Updated configuration parameters")
        
        # Script analysis
        if script_changes.get('security_improvements'):
            focus_areas.append("security enhancements")
            details.append("- Improved security and evasion techniques")
            
        if script_changes.get('obfuscation_changes'):
            focus_areas.append("obfuscation")
            details.append("- Enhanced command obfuscation and dynamic execution")
            
        if script_changes.get('performance_improvements'):
            focus_areas.append("performance optimization")
            details.append("- Optimized execution performance")
            
        if script_changes.get('bug_fixes'):
            focus_areas.append("bug fixes")
            details.append("- Fixed implementation issues")
            
        if script_changes.get('new_functions'):
            focus_areas.append("new functionality")
            details.append(f"- Added functions: {', '.join(script_changes['new_functions'][:3])}")
        
        # Build title
        if focus_areas:
            title += f" {' and '.join(focus_areas[:2])}"
        else:
            title += " enhanced implementation"
        
        # Build full message
        message = title + "\n\n"
        
        if details:
            message += "\n".join(details)
        else:
            message += "- Updated YAML configuration\n"
            message += "- Improved shell script implementation"
            
        message += "\n- Applied coding standards and best practices"
        
        return message
    
    def commit_pair(self, yaml_path: str, script_path: str) -> bool:
        """Commit a YAML+script pair with intelligent message."""
        try:
            procedure_name = Path(yaml_path).stem
            
            print(f"\n🔍 Analyzing changes for {procedure_name}...")
            
            # Analyze changes
            yaml_changes = self.analyze_yaml_changes(yaml_path)
            script_changes = self.analyze_script_changes(script_path)
            
            # Generate commit message
            commit_message = self.generate_intelligent_commit_message(
                procedure_name, yaml_changes, script_changes
            )
            
            print(f"📝 Generated commit message:")
            print(f"{commit_message}")
            print()
            
            # Stage and commit files
            self.repo.index.add([yaml_path, script_path])
            self.repo.index.commit(commit_message)
            
            # Push to remote
            origin = self.repo.remote('origin')
            origin.push()
            
            print(f"✅ Committed and pushed: {procedure_name}")
            return True
            
        except Exception as e:
            print(f"❌ Error committing {procedure_name}: {e}")
            return False


def main():
    """Main execution function."""
    print("🚀 IntelligentCommitter - AI-Enhanced Git Commit Tool")
    print("=" * 50)
    
    # Initialize committer
    committer = IntelligentCommitter()
    
    if not committer.repo:
        print("❌ Not a git repository or no repository found")
        return
    
    # Get modified YAML+script pairs
    pairs = committer.get_modified_pairs()
    
    # Get standalone files
    standalone_files = committer.get_standalone_files()
    
    total_commits = 0
    
    # Process YAML+script pairs
    if pairs:
        print(f"\n📋 Found {len(pairs)} YAML+script pairs to commit")
        
        for yaml_file, script_file in pairs:
            success = committer.commit_pair(yaml_file, script_file)
            if success:
                total_commits += 1
    else:
        print("\n📋 No YAML+script pairs found to commit")
    
    # Process standalone files
    if standalone_files:
        print(f"\n📄 Found {len(standalone_files)} standalone files to commit")
        
        for file_path in standalone_files:
            success = committer.commit_standalone(file_path)
            if success:
                total_commits += 1
    else:
        print("\n📄 No important standalone files found to commit")
    
    # Summary
    print(f"\n🎯 Summary: {total_commits} commits completed")
    
    if total_commits == 0:
        print("💡 No files were committed. Make sure you have staged changes.")
    else:
        print("✅ All commits have been pushed to remote repository")


if __name__ == "__main__":
    main() 