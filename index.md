---
layout: default
---

<div class="hero-section">
  <h1>Clear the <span class="highlight">security</span> backlog<br>with speed and precision</h1>
  <p>Execute and investigate macOS MITRE ATT&CK techniques 10x faster with drag-and-drop security workflows that contextualize techniques from all your environments.</p>
  <a href="{{ site.baseurl }}/docs/ROADMAP.html" class="btn">Get Started</a>
  <a href="https://github.com/{{ site.github.repository_nwo }}" class="btn btn-secondary">View on GitHub</a>
</div>

<div class="features-grid">
  <div class="feature-card">
    <div class="feature-icon">🎯</div>
    <h3>MITRE ATT&CK</h3>
    <p>Execute real attack techniques mapped to the MITRE ATT&CK framework for macOS</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">⚡</div>
    <h3>Fast Execution</h3>
    <p>One-liner remote execution with no local installation required</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">🔧</div>
    <h3>Modular Scripts</h3>
    <p>Standalone scripts that can run independently or through the attackmacos.sh wrapper</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">📊</div>
    <h3>Rich Output</h3>
    <p>JSON, CSV, and custom formats with encoding and exfiltration options</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">🛡️</div>
    <h3>Security Testing</h3>
    <p>Test detection capabilities and security controls in controlled environments</p>
  </div>
  
  <div class="feature-card">
    <div class="feature-icon">🔍</div>
    <h3>Discovery</h3>
    <p>Enumerate system information, accounts, browser history, and security software</p>
  </div>
</div>

## Quick Start

Execute techniques directly from GitHub with no local files needed:

```bash
# Execute browser history collection
curl -sSL https://raw.githubusercontent.com/{{ site.github.repository_nwo }}/main/attackmacos/ttp/discovery/browser_history/browser_history.sh | sh -s -- --safari

# Download attackmacos.sh for local execution
curl -O https://raw.githubusercontent.com/{{ site.github.repository_nwo }}/main/attackmacos/attackmacos.sh
chmod +x attackmacos.sh
./attackmacos.sh --list --tactic discovery
```

## Signal: Technique Execution Pipeline

<div class="card">
<pre><code>{
  "technique_id": "T1217",
  "name": "browser_history_collection", 
  "tactic": "discovery",
  "time_to_execute": "< 1 second",
  "details": {
    "description": [
      "User executed browser history collection",
      "Extracted Safari, Chrome, Firefox data",
      "Tagged with MITRE ATT&CK mapping"
    ]
  },
  "username": "security_researcher",
  "source_ip": "192.168.1.100"
}</code></pre>
</div> 