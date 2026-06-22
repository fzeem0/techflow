bash << 'PART1'
set -e
echo "==> Part 1: Creating TechFlow structure..."

mkdir -p ~/techflow/{missions,data,logs,config,backups,app,scripts,reports}

cat > ~/techflow/config/app.conf << 'EOF'
[database]
host = localhost
port = 5432
name = techflow_db
user = app_user
password = changeme123
pool_size = 10

[app]
debug = True
environment = development
secret_key = dev-secret-key-change-in-prod
workers = 1
log_level = DEBUG

[cache]
backend = redis
host = localhost
port = 6379
ttl = 3600
EOF

cat > ~/techflow/config/nginx.conf << 'EOF'
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name localhost;
        location / {
            proxy_pass http://localhost:8080;
        }
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
    }
}
EOF

cp ~/techflow/config/nginx.conf ~/techflow/config/nginx.conf.bak

cat > ~/techflow/app/server.py << 'EOF'
#!/usr/bin/env python3
import http.server, socketserver, json, datetime

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type','application/json')
            self.end_headers()
            data = {'status':'ok','timestamp':str(datetime.datetime.now()),'version':'1.0.0'}
            self.wfile.write(json.dumps(data).encode())
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type','text/html')
            self.end_headers()
            self.wfile.write(b'<h1>TechFlow App is Running!</h1>')
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(('', 8888), Handler) as httpd:
    print('TechFlow app running on port 8888')
    httpd.serve_forever()
EOF

cp ~/techflow/config/app.conf ~/techflow/config/secret.conf
chmod 777 ~/techflow/config/secret.conf

echo "==> Part 1 done. Folders and config files created."

python3 << 'PART2'
import random, datetime, os

home = os.path.expanduser('~')
base = os.path.join(home, 'techflow')

print("==> Part 2: Generating data files...")

# SYSLOG
levels = ['INFO','INFO','INFO','WARN','ERROR','DEBUG']
services = ['nginx','postgres','app','redis','celery']
msgs = [
    'Request processed successfully',
    'Database connection established',
    'Cache miss for key user_session',
    'Failed to connect to upstream',
    'Connection timeout after 30s',
    'Worker process started',
    'Memory usage at 87%',
    'Disk IO wait high',
    'Authentication failed for user admin',
    'SSL certificate expires in 14 days',
    'Query took 2.3s slow query log',
    'OOM killer triggered on pid 1234',
    'Segmentation fault in worker',
    'Too many open files',
    'Connection refused on port 5432',
]
start = datetime.datetime(2025,1,1,0,0,0)
lines = []
for i in range(5000):
    ts = start + datetime.timedelta(seconds=i*17)
    level = random.choice(levels)
    svc = random.choice(services)
    msg = random.choice(msgs)
    pid = random.randint(1000,9999)
    lines.append(f'{ts.strftime("%b %d %H:%M:%S")} prod-server {svc}[{pid}]: {level} {msg}')

with open(os.path.join(base,'logs','syslog.log'),'w') as f:
    f.write('\n'.join(lines))
print("    syslog.log created (5000 lines)")

# ACCESS LOG
ips = ['203.0.113.'+str(i) for i in range(1,30)]
ips += ['1.2.3.4']*150
ips += ['10.0.0.'+str(i) for i in range(1,20)]
urls = ['/','/','/api/users','/api/orders',
        '/static/app.js','/static/style.css',
        '/api/health','/login','/dashboard',
        '/api/products','/favicon.ico','/admin']
codes = [200,200,200,200,200,301,404,404,500,403]
lines = []
for i in range(3000):
    ip = random.choice(ips)
    url = random.choice(urls)
    code = random.choice(codes)
    size = random.randint(200,50000)
    hour = str(random.randint(0,23)).zfill(2)
    minute = str(random.randint(0,59)).zfill(2)
    second = str(random.randint(0,59)).zfill(2)
    lines.append(
        f'{ip} - - [15/Jan/2025:{hour}:{minute}:{second} +0000] '
        f'"GET {url} HTTP/1.1" {code} {size} "-" "Mozilla/5.0"'
    )

with open(os.path.join(base,'logs','access.log'),'w') as f:
    f.write('\n'.join(lines))
print("    access.log created (3000 lines)")

# METRICS CSV
rows = ['timestamp,server,cpu,memory,disk,network_in,network_out']
servers = ['web-01','web-02','web-03','db-01','cache-01']
start2 = datetime.datetime(2025,1,1,0,0,0)
for i in range(500):
    ts = start2 + datetime.timedelta(minutes=i*5)
    for srv in servers:
        cpu = round(random.uniform(5,95),1)
        mem = round(random.uniform(30,90),1)
        disk = round(random.uniform(40,88),1)
        net_in = random.randint(100,5000)
        net_out = random.randint(50,3000)
        rows.append(
            f'{ts.strftime("%Y-%m-%d %H:%M:%S")},'
            f'{srv},{cpu},{mem},{disk},{net_in},{net_out}'
        )

with open(os.path.join(base,'data','metrics.csv'),'w') as f:
    f.write('\n'.join(rows))
print("    metrics.csv created (2500 rows)")

# IP LIST
ips2 = []
for _ in range(5000):
    ips2.append(f'192.168.{random.randint(1,10)}.{random.randint(1,254)}')
with open(os.path.join(base,'data','ips.txt'),'w') as f:
    f.write('\n'.join(ips2))
print("    ips.txt created (5000 entries)")

# MYSTERY FILES
with open(os.path.join(base,'data','mystery1'),'w') as f:
    f.write('#!/bin/bash\necho "You found a hidden script!"\n')

import gzip, shutil
src = os.path.join(base,'config','app.conf')
dst = os.path.join(base,'data','mystery2.gz')
with open(src,'rb') as f_in:
    with gzip.open(dst,'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)

import tarfile
with tarfile.open(os.path.join(base,'data','mystery3.tar.gz'),'w:gz') as tar:
    tar.add(os.path.join(base,'config','nginx.conf'), arcname='nginx.conf')

print("    mystery files created")

# BIG LOG TO CLEAN UP
with open(os.path.join(base,'logs','old_debug.log'),'w') as f:
    for i in range(30000):
        f.write(f'DEBUG line {i}: verbose output nobody reads wastes disk space\n')
print("    old_debug.log created (30000 lines - needs cleanup!)")

print("==> Part 2 done. All data files generated.")

bash << 'PART3'
set -e
echo "==> Part 3: Installing mission runner..."

cat > ~/techflow/techflow << 'MISSIONEOF'
#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

BASE="$HOME/techflow"
PROGRESS="$HOME/.techflow_progress"

[ ! -f "$PROGRESS" ] && echo -e "DONE=\nCURRENT=1" > "$PROGRESS"
source "$PROGRESS"
DONE="${DONE:-}"
CURRENT="${CURRENT:-1}"

done_check() { echo "$DONE" | grep -qw "$1"; }

mark_done() {
    local m=$1
    done_check "$m" && return
    DONE="$DONE $m"
    CURRENT=$((m+1))
    sed -i "s/DONE=.*/DONE=\"$DONE\"/" "$PROGRESS"
    sed -i "s/CURRENT=.*/CURRENT=$CURRENT/" "$PROGRESS"
}

header() {
    clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║       TechFlow DevOps Training — 180 Commands        ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
    local total=9
    local cnt=$(echo "$DONE" | wc -w)
    local pct=$((cnt*100/total))
    local filled=$((pct/5))
    local bar=""
    for i in $(seq 1 $filled 2>/dev/null); do bar="${bar}█"; done
    for i in $(seq $((filled+1)) 20 2>/dev/null); do bar="${bar}░"; done
    echo -e "  Progress: ${GREEN}${bar}${RESET} ${pct}% (${cnt}/${total} missions)"
    echo ""
}

menu() {
    header
    local entries=(
        "1:Server Recon — Know Your Machine:easy"
        "2:Filesystem Disaster Recovery:medium"
        "3:Log Investigation — Find the Incident:medium"
        "4:Text Processing Gauntlet:hard"
        "5:Process Crisis Management:hard"
        "6:Network Diagnosis:hard"
        "7:Bash Scripting — Automate Everything:hard"
        "8:Git Operations Workflow:medium"
        "9:System Administration:hard"
    )
    echo -e "  ${BOLD}MISSIONS${RESET}"
    echo ""
    for e in "${entries[@]}"; do
        local n="${e%%:*}"
        local rest="${e#*:}"
        local name="${rest%%:*}"
        local diff="${rest##*:}"
        local dc="$GREEN"
        [ "$diff" = "medium" ] && dc="$YELLOW"
        [ "$diff" = "hard" ] && dc="$RED"
        [ "$diff" = "extreme" ] && dc="$MAGENTA"
        local prev=$((n-1))
        if done_check "$n"; then
            echo -e "  ${GREEN}[✓]${RESET} M${n}: ${DIM}${name}${RESET} ${dc}(${diff})${RESET}"
        elif [ "$n" = "$CURRENT" ]; then
            echo -e "  ${YELLOW}[→]${RESET} M${n}: ${BOLD}${name}${RESET} ${dc}(${diff})${RESET} ${CYAN}← YOU ARE HERE${RESET}"
        elif done_check "$prev" || [ "$n" = "1" ]; then
            echo -e "  ${BLUE}[ ]${RESET} M${n}: ${name} ${dc}(${diff})${RESET}"
        else
            echo -e "  ${DIM}[🔒] M${n}: ${name} (${diff})${RESET}"
        fi
    done
    echo ""
    echo -e "  ${BOLD}How to use:${RESET}"
    echo -e "  ${CYAN}techflow mission <N>${RESET}   open a mission"
    echo -e "  ${CYAN}techflow hint <N>${RESET}      get a hint"
    echo -e "  ${CYAN}techflow verify <N>${RESET}    auto-check your work"
    echo -e "  ${CYAN}techflow done <N>${RESET}      mark complete"
    echo -e "  ${CYAN}tf${RESET}                    shortcut for techflow"
    echo ""
}

mission() {
    local N=$1
    header
    case $N in
    1)
        echo -e "${BOLD}${CYAN}MISSION 1 — Server Recon: Know Your Machine${RESET}"
        echo -e "${DIM}Difficulty: Easy | ~30 min | Commands: uname hostname uptime w last df du free vmstat ss ps top file stat tree${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} You just got SSH access to TechFlow production server."
        echo "Nobody documented anything. Your job: understand this machine completely."
        echo "Do not change anything. Just observe and report."
        echo ""
        echo -e "${BOLD}TASK 1.1 — Kernel and Architecture${RESET}"
        echo "Find: kernel version, OS architecture (32/64 bit), hostname, all IPs"
        echo -e "${DIM}Use: uname -a | hostname -f | hostname -I${RESET}"
        echo -e "${DIM}Repeat: run uname -a 3 times and explain each field${RESET}"
        echo ""
        echo -e "${BOLD}TASK 1.2 — Uptime and Load${RESET}"
        echo "How long has server been up? Is load average normal?"
        echo -e "${DIM}Use: uptime | lscpu | nproc${RESET}"
        echo -e "${DIM}Rule: load average should be below number of CPU cores${RESET}"
        echo ""
        echo -e "${BOLD}TASK 1.3 — Who Is On This Server${RESET}"
        echo "Who is logged in right now? Who logged in last week?"
        echo -e "${DIM}Use: w | last | last | head -20${RESET}"
        echo ""
        echo -e "${BOLD}TASK 1.4 — Disk Space Audit${RESET}"
        echo "Check every filesystem. Find the biggest directories in ~/techflow"
        echo -e "${DIM}Use: df -h | df -hT | du -sh ~/techflow/* | du -sh ~/techflow/logs/*${RESET}"
        echo -e "${DIM}Question: which directory is biggest? Is anything over 80%?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 1.5 — Memory Check${RESET}"
        echo "Is RAM available? Is swap being used? Any memory pressure?"
        echo -e "${DIM}Use: free -h | vmstat 1 5${RESET}"
        echo -e "${DIM}Question: what does the 'available' column mean vs 'free'?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 1.6 — Open Ports${RESET}"
        echo "What ports are listening? What process owns each port?"
        echo -e "${DIM}Use: ss -tulnp | netstat -tulnp${RESET}"
        echo -e "${DIM}Run both. Compare output. What is different?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 1.7 — Running Processes${RESET}"
        echo "What are top 10 processes by CPU? By memory?"
        echo -e "${DIM}Use: ps aux --sort=-%cpu | head -11${RESET}"
        echo -e "${DIM}Use: ps aux --sort=-%mem | head -11${RESET}"
        echo -e "${DIM}Explain every column: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND${RESET}"
        echo ""
        echo -e "${BOLD}TASK 1.8 — Explore the Training Data${RESET}"
        echo "Look at the techflow directory structure. Identify mystery files."
        echo -e "${DIM}Use: tree ~/techflow | ls -la ~/techflow/data/ | file ~/techflow/data/mystery*${RESET}"
        echo -e "${DIM}Use: stat ~/techflow/data/mystery1${RESET}"
        echo -e "${DIM}Question: what type is each mystery file?${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE — do not skip this:${RESET}"
        echo "Run each command below 3 times until you can type it without thinking:"
        echo -e "  ${DIM}ss -tulnp${RESET}"
        echo -e "  ${DIM}ps aux --sort=-%cpu | head -10${RESET}"
        echo -e "  ${DIM}df -hT${RESET}"
        echo -e "  ${DIM}free -h${RESET}"
        echo -e "  ${DIM}du -sh ~/techflow/*${RESET}"
        echo ""
        echo -e "${GREEN}When done: techflow verify 1${RESET}"
        ;;
    2)
        echo -e "${BOLD}${CYAN}MISSION 2 — Filesystem Disaster Recovery${RESET}"
        echo -e "${DIM}Difficulty: Medium | ~45 min | Commands: find du ls gzip tar chmod stat sed diff sha256sum ln cp mv rm${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} The filesystem is a mess. Giant log files eating"
        echo "disk space. Wrong permissions on secret files. Config has wrong"
        echo "values. Mystery files everywhere. Fix it all."
        echo ""
        echo -e "${BOLD}TASK 2.1 — Find the Disk Hog${RESET}"
        echo "Find the largest file in ~/techflow. How big is it?"
        echo -e "${DIM}Use: find ~/techflow -type f | xargs ls -lhS 2>/dev/null | tail -10${RESET}"
        echo -e "${DIM}Use: du -sh ~/techflow/logs/* | sort -rh${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.2 — Compress the Monster Log${RESET}"
        echo "Compress old_debug.log with gzip. Check size before and after."
        echo -e "${DIM}ls -lh ~/techflow/logs/old_debug.log${RESET}"
        echo -e "${DIM}gzip ~/techflow/logs/old_debug.log${RESET}"
        echo -e "${DIM}ls -lh ~/techflow/logs/old_debug.log.gz${RESET}"
        echo -e "${DIM}How much space did you save?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.3 — Archive the Logs Directory${RESET}"
        echo "Create a tar.gz archive of the entire logs directory"
        echo -e "${DIM}tar -czvf ~/techflow/backups/logs_\$(date +%F).tar.gz ~/techflow/logs/${RESET}"
        echo -e "${DIM}List archive contents: tar -tzvf ~/techflow/backups/logs_*.tar.gz${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.4 — Fix Wrong Permissions${RESET}"
        echo "secret.conf has 777 permissions (everyone can read/write). Fix to 600."
        echo -e "${DIM}stat ~/techflow/config/secret.conf   # see current permissions${RESET}"
        echo -e "${DIM}chmod 600 ~/techflow/config/secret.conf${RESET}"
        echo -e "${DIM}stat ~/techflow/config/secret.conf   # verify it changed${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.5 — Fix Wrong Config Values${RESET}"
        echo "app.conf says 'development' everywhere. Change ALL to 'production'."
        echo -e "${DIM}grep 'development' ~/techflow/config/app.conf  # see what needs changing${RESET}"
        echo -e "${DIM}sed -i 's/development/production/g' ~/techflow/config/app.conf${RESET}"
        echo -e "${DIM}grep 'development' ~/techflow/config/app.conf  # should return nothing${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.6 — Investigate Mystery Files${RESET}"
        echo "What is each mystery file? Do not run them. Just identify."
        echo -e "${DIM}file ~/techflow/data/mystery1${RESET}"
        echo -e "${DIM}file ~/techflow/data/mystery2.gz${RESET}"
        echo -e "${DIM}file ~/techflow/data/mystery3.tar.gz${RESET}"
        echo -e "${DIM}stat ~/techflow/data/mystery1  # when was it created? how big?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.7 — Generate Checksums${RESET}"
        echo "Create SHA256 checksums for all config files. Then verify them."
        echo -e "${DIM}sha256sum ~/techflow/config/* > ~/techflow/config/CHECKSUMS.txt${RESET}"
        echo -e "${DIM}cat ~/techflow/config/CHECKSUMS.txt${RESET}"
        echo -e "${DIM}sha256sum -c ~/techflow/config/CHECKSUMS.txt${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.8 — Compare Configs${RESET}"
        echo "Compare nginx.conf with its backup. What is different?"
        echo -e "${DIM}diff ~/techflow/config/nginx.conf ~/techflow/config/nginx.conf.bak${RESET}"
        echo -e "${DIM}diff -u ~/techflow/config/nginx.conf.bak ~/techflow/config/nginx.conf${RESET}"
        echo ""
        echo -e "${BOLD}TASK 2.9 — Create a Symlink${RESET}"
        echo "Create a symlink: ~/techflow/current pointing to ~/techflow/app"
        echo -e "${DIM}ln -s ~/techflow/app ~/techflow/current${RESET}"
        echo -e "${DIM}ls -la ~/techflow/current${RESET}"
        echo -e "${DIM}ls -la ~/techflow/ | grep current${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE:${RESET}"
        echo "Do this sequence 3 times from memory:"
        echo -e "  ${DIM}find ~/techflow -name '*.conf' | xargs grep -l 'password'${RESET}"
        echo -e "  ${DIM}find ~/techflow -type f -size +1M${RESET}"
        echo -e "  ${DIM}du -sh ~/techflow/* | sort -rh | head -5${RESET}"
        echo ""
        echo -e "${GREEN}When done: techflow verify 2${RESET}"
        ;;
    3)
        echo -e "${BOLD}${CYAN}MISSION 3 — Log Investigation${RESET}"
        echo -e "${DIM}Difficulty: Medium | ~45 min | Commands: grep awk sed cut sort uniq wc tail head diff${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} The app crashed. Users complained. Dig through"
        echo "the logs. Find what happened, when, and who caused it."
        echo "All logs are in ~/techflow/logs/"
        echo ""
        echo -e "${BOLD}TASK 3.1 — Count Log Levels${RESET}"
        echo "How many ERROR, WARN, INFO, DEBUG lines in syslog.log?"
        echo -e "${DIM}grep -c 'ERROR' ~/techflow/logs/syslog.log${RESET}"
        echo -e "${DIM}grep -c 'WARN' ~/techflow/logs/syslog.log${RESET}"
        echo -e "${DIM}grep -c 'INFO' ~/techflow/logs/syslog.log${RESET}"
        echo -e "${DIM}grep -c 'DEBUG' ~/techflow/logs/syslog.log${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.2 — Find First and Last Error${RESET}"
        echo "When was the first ERROR? When was the last?"
        echo -e "${DIM}grep 'ERROR' ~/techflow/logs/syslog.log | head -1${RESET}"
        echo -e "${DIM}grep 'ERROR' ~/techflow/logs/syslog.log | tail -1${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.3 — Extract Error Timestamps${RESET}"
        echo "Print only the time portion (column 3) of all ERROR lines"
        echo -e "${DIM}grep 'ERROR' ~/techflow/logs/syslog.log | awk '{print \$3}' | head -20${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.4 — Find the Attacker${RESET}"
        echo "From access.log: top 10 IPs by request count"
        echo -e "${DIM}awk '{print \$1}' ~/techflow/logs/access.log | sort | uniq -c | sort -rn | head -10${RESET}"
        echo -e "${DIM}Question: which IP looks suspicious? How many requests did it make?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.5 — Find All 500 Errors${RESET}"
        echo "Find every HTTP 500 error. Show IP and URL."
        echo -e "${DIM}awk '\$9 == 500 {print \$1, \$7}' ~/techflow/logs/access.log${RESET}"
        echo -e "${DIM}awk '\$9 == 500' ~/techflow/logs/access.log | wc -l${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.6 — Investigate the Suspicious IP${RESET}"
        echo "1.2.3.4 is suspicious. What did it access? How many times?"
        echo -e "${DIM}grep '1.2.3.4' ~/techflow/logs/access.log | wc -l${RESET}"
        echo -e "${DIM}grep '1.2.3.4' ~/techflow/logs/access.log | awk '{print \$7}' | sort | uniq -c | sort -rn${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.7 — Top URLs Excluding Static Files${RESET}"
        echo "Find top 5 most requested URLs — ignore .js .css .png .ico"
        echo -e "${DIM}awk '{print \$7}' ~/techflow/logs/access.log | grep -v '\.\(js\|css\|png\|ico\|jpg\)' | sort | uniq -c | sort -rn | head -5${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.8 — Analyze Metrics CSV${RESET}"
        echo "Find all rows where CPU > 85% in metrics.csv"
        echo -e "${DIM}awk -F',' 'NR>1 && \$3>85 {print \$1,\$2,\$3}' ~/techflow/data/metrics.csv | head -10${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.9 — Average CPU Per Server${RESET}"
        echo "Calculate average CPU usage for each server"
        echo -e "${DIM}awk -F',' 'NR>1 {sum[\$2]+=\$3; cnt[\$2]++} END {for(s in sum) printf \"%-12s %.1f%%\n\", s, sum[s]/cnt[s]}' ~/techflow/data/metrics.csv${RESET}"
        echo ""
        echo -e "${BOLD}TASK 3.10 — Search Config Files${RESET}"
        echo "Find every config file containing the word 'password'"
        echo -e "${DIM}grep -rn 'password' ~/techflow/config/${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE — run from memory 5 times:${RESET}"
        echo -e "  ${DIM}awk '{print \$1}' ~/techflow/logs/access.log | sort | uniq -c | sort -rn | head -5${RESET}"
        echo ""
        echo -e "${GREEN}When done: techflow verify 3${RESET}"
        ;;
    4)
        echo -e "${BOLD}${CYAN}MISSION 4 — Process Crisis Management${RESET}"
        echo -e "${DIM}Difficulty: Hard | ~60 min | Commands: ps top htop kill pkill pgrep lsof nohup nice renice watch fuser ss curl${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} Server is under load. Start the app, monitor it,"
        echo "investigate it, kill it multiple ways. Master process control."
        echo ""
        echo -e "${BOLD}TASK 4.1 — Snapshot Running Processes${RESET}"
        echo "Show top 15 by CPU. Name every column."
        echo -e "${DIM}ps aux --sort=-%cpu | head -16${RESET}"
        echo -e "${DIM}Columns: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.2 — Start the App in Background${RESET}"
        echo -e "${DIM}nohup python3 ~/techflow/app/server.py > ~/techflow/logs/app.log 2>&1 &${RESET}"
        echo -e "${DIM}echo \"App PID: \$!\"${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.3 — Verify It Is Running${RESET}"
        echo -e "${DIM}pgrep -la python3${RESET}"
        echo -e "${DIM}ps aux | grep server.py${RESET}"
        echo -e "${DIM}curl http://localhost:8888/health${RESET}"
        echo -e "${DIM}curl http://localhost:8888/${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.4 — Watch the App Log Live${RESET}"
        echo "In one terminal tail the log. In another terminal hit the app."
        echo -e "${DIM}Terminal 1: tail -f ~/techflow/logs/app.log${RESET}"
        echo -e "${DIM}Terminal 2: curl http://localhost:8888/health${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.5 — See Open Files${RESET}"
        echo -e "${DIM}lsof -p \$(pgrep -f server.py)${RESET}"
        echo -e "${DIM}What files does the app have open?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.6 — Check Port Usage${RESET}"
        echo -e "${DIM}ss -tulnp | grep 8888${RESET}"
        echo -e "${DIM}fuser 8888/tcp${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.7 — Run Low Priority Background Task${RESET}"
        echo -e "${DIM}nice -n 19 find / -name '*.log' > /dev/null 2>&1 &${RESET}"
        echo -e "${DIM}ps -eo pid,ni,cmd | grep find${RESET}"
        echo -e "${DIM}What does nice value 19 mean?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.8 — Watch Processes Live${RESET}"
        echo -e "${DIM}watch -n 2 'ps aux --sort=-%cpu | head -8'${RESET}"
        echo -e "${DIM}Run for 20 seconds then Ctrl+C${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.9 — Kill the Low Priority Task${RESET}"
        echo -e "${DIM}pkill -f 'find /'${RESET}"
        echo -e "${DIM}pgrep -la find  # should return nothing${RESET}"
        echo ""
        echo -e "${BOLD}TASK 4.10 — Kill the App 3 Different Ways${RESET}"
        echo "Restart the app 3 times. Kill with a different method each time."
        echo -e "${DIM}Round 1: kill \$(pgrep -f server.py)${RESET}"
        echo -e "${DIM}Round 2: pkill -f server.py${RESET}"
        echo -e "${DIM}Round 3: kill -9 \$(pgrep -f server.py)${RESET}"
        echo -e "${DIM}After each: verify with pgrep -f server.py (should be empty)${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE:${RESET}"
        echo "Start and kill the app 5 more times using only these commands from memory:"
        echo -e "  ${DIM}nohup python3 ~/techflow/app/server.py > /dev/null 2>&1 &${RESET}"
        echo -e "  ${DIM}pgrep -la python3${RESET}"
        echo -e "  ${DIM}kill PID${RESET}"
        echo ""
        echo -e "${GREEN}When done: techflow verify 4${RESET}"
        ;;
    5)
        echo -e "${BOLD}${CYAN}MISSION 5 — Network Diagnosis${RESET}"
        echo -e "${DIM}Difficulty: Hard | ~60 min | Commands: ip ping traceroute dig nslookup curl wget nc ss netstat host${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} Users in certain regions cannot reach TechFlow."
        echo "Diagnose the full network stack from your VM."
        echo ""
        echo -e "${BOLD}TASK 5.1 — Network Interfaces${RESET}"
        echo -e "${DIM}ip addr show${RESET}"
        echo -e "${DIM}ip a  # short form${RESET}"
        echo -e "${DIM}ip route show${RESET}"
        echo -e "${DIM}Question: what is your main interface name? default gateway?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 5.2 — Connectivity Tests${RESET}"
        echo -e "${DIM}ping -c 5 8.8.8.8${RESET}"
        echo -e "${DIM}ping -c 3 1.1.1.1${RESET}"
        echo -e "${DIM}traceroute -n 8.8.8.8${RESET}"
        echo -e "${DIM}Question: how many hops? where does latency increase?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 5.3 — DNS Investigation${RESET}"
        echo "Query google.com from two different DNS servers"
        echo -e "${DIM}dig @8.8.8.8 google.com +short${RESET}"
        echo -e "${DIM}dig @1.1.1.1 google.com +short${RESET}"
        echo -e "${DIM}dig MX gmail.com${RESET}"
        echo -e "${DIM}nslookup google.com 8.8.8.8${RESET}"
        echo -e "${DIM}host -t A google.com${RESET}"
        echo ""
        echo -e "${BOLD}TASK 5.4 — Port Testing${RESET}"
        echo -e "${DIM}nc -zv google.com 80${RESET}"
        echo -e "${DIM}nc -zv google.com 443${RESET}"
        echo -e "${DIM}nc -zv google.com 22  # should fail${RESET}"
        echo ""
        echo -e "${BOLD}TASK 5.5 — HTTP Requests${RESET}"
        echo -e "${DIM}curl -I https://httpbin.org/get${RESET}"
        echo -e "${DIM}curl -s https://httpbin.org/ip | jq .${RESET}"
        echo -e "${DIM}curl -s https://httpbin.org/headers | jq .${RESET}"
        echo -e "${DIM}wget -q -O - https://httpbin.org/ip${RESET}"
        echo ""
        echo -e "${BOLD}TASK 5.6 — Connection Analysis${RESET}"
        echo -e "${DIM}ss -tn state established${RESET}"
        echo -e "${DIM}ss -tn state established | wc -l${RESET}"
        echo -e "${DIM}ss -tulnp | column -t${RESET}"
        echo ""
        echo -e "${BOLD}TASK 5.7 — Reverse DNS${RESET}"
        echo -e "${DIM}host 8.8.8.8${RESET}"
        echo -e "${DIM}dig -x 8.8.8.8 +short${RESET}"
        echo -e "${DIM}dig -x 1.1.1.1 +short${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE — from memory, no hints:${RESET}"
        echo "Do full DNS lookup for 5 domains: name, IP, MX record, TTL"
        echo "Use different tool each time: dig, nslookup, host"
        echo ""
        echo -e "${GREEN}When done: techflow verify 5${RESET}"
        ;;
    6)
        echo -e "${BOLD}${CYAN}MISSION 6 — Bash Scripting${RESET}"
        echo -e "${DIM}Difficulty: Hard | ~75 min | Commands: bash variables if for while functions trap cron heredoc read source${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} Stop doing things manually. Write production-grade scripts."
        echo "Every script: shebang + set -euo pipefail + trap + functions + logging."
        echo ""
        echo -e "${BOLD}Write these 5 scripts in ~/techflow/scripts/:${RESET}"
        echo ""
        echo -e "  ${CYAN}health_check.sh${RESET}"
        echo "  Checks: disk < 90%, python3 available, syslog.log exists"
        echo "  Prints PASS/FAIL with color for each check"
        echo "  Exit 0 if all pass, 1 if any fail"
        echo "  Has: shebang, set -euo pipefail, at least one function"
        echo ""
        echo -e "  ${CYAN}backup.sh${RESET}"
        echo "  Backs up ~/techflow/config to ~/techflow/backups"
        echo "  Filename: config_YYYY-MM-DD_HHMMSS.tar.gz"
        echo "  Keeps only last 5 backups"
        echo "  Logs start/end/size to ~/techflow/logs/backup.log"
        echo "  Has: set -euo pipefail, trap for cleanup, mktemp"
        echo ""
        echo -e "  ${CYAN}log_report.sh${RESET}"
        echo "  Reads ~/techflow/logs/syslog.log"
        echo "  Prints: total lines, ERROR count, WARN count, top 5 error messages"
        echo "  Uses: grep, awk, sort, uniq, wc"
        echo ""
        echo -e "  ${CYAN}monitor.sh${RESET}"
        echo "  Loops 10 times with 5 second sleep"
        echo "  Each loop: timestamp, load average, free memory, disk %"
        echo "  Appends to ~/techflow/logs/monitor.log"
        echo "  Uses: while loop, date, uptime, free, df, sleep"
        echo ""
        echo -e "  ${CYAN}setup_env.sh${RESET}"
        echo "  Takes argument: dev or staging or prod"
        echo "  Validates argument — exits with error if wrong"
        echo "  Creates /tmp/techflow-ENV/ structure"
        echo "  Writes a .env file using heredoc with ENV-specific values"
        echo "  Uses: case statement, mkdir, heredoc, read"
        echo ""
        echo -e "${BOLD}${YELLOW}Rules for every script:${RESET}"
        echo "  Line 1: #!/usr/bin/env bash"
        echo "  Line 2: set -euo pipefail"
        echo "  Must have: at least one function"
        echo "  Must have: at least one trap"
        echo "  Must have: logging to a file"
        echo "  Test with: bash -n script.sh (syntax check)"
        echo "  Debug with: bash -x script.sh (trace mode)"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE:${RESET}"
        echo "After each script works, break it intentionally."
        echo "Remove set -e. Remove quotes from variables."
        echo "Use bash -x to watch what breaks and why."
        echo ""
        echo -e "${GREEN}When done: techflow verify 6${RESET}"
        ;;
    7)
        echo -e "${BOLD}${CYAN}MISSION 7 — Git Operations${RESET}"
        echo -e "${DIM}Difficulty: Medium | ~60 min | Commands: git init add commit log branch checkout merge stash tag diff revert${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} TechFlow has no version control. Set it up."
        echo "Practice the full Git workflow from scratch."
        echo ""
        echo -e "${BOLD}TASK 7.1 — Initialize Repository${RESET}"
        echo -e "${DIM}cd ~/techflow${RESET}"
        echo -e "${DIM}git init${RESET}"
        echo -e "${DIM}git config user.email 'ali@techflow.com'${RESET}"
        echo -e "${DIM}git config user.name 'Ali'${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.2 — Create .gitignore${RESET}"
        echo -e "${DIM}cat > .gitignore << 'EOF'${RESET}"
        echo -e "${DIM}*.log${RESET}"
        echo -e "${DIM}*.gz${RESET}"
        echo -e "${DIM}backups/${RESET}"
        echo -e "${DIM}__pycache__/${RESET}"
        echo -e "${DIM}*.pyc${RESET}"
        echo -e "${DIM}EOF${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.3 — First Commit${RESET}"
        echo -e "${DIM}git add config/ app/ scripts/${RESET}"
        echo -e "${DIM}git status${RESET}"
        echo -e "${DIM}git commit -m 'init: add config, app, and scripts'${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.4 — Feature Branch${RESET}"
        echo -e "${DIM}git checkout -b feature/monitoring${RESET}"
        echo -e "${DIM}echo '[monitoring]' > config/monitoring.conf${RESET}"
        echo -e "${DIM}echo 'interval = 30' >> config/monitoring.conf${RESET}"
        echo -e "${DIM}git add config/monitoring.conf${RESET}"
        echo -e "${DIM}git commit -m 'feat: add monitoring config'${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.5 — Switch and Make Hotfix${RESET}"
        echo -e "${DIM}git checkout main  # or master${RESET}"
        echo -e "${DIM}# Make a change to config/app.conf${RESET}"
        echo -e "${DIM}sed -i 's/workers = 1/workers = 4/' config/app.conf${RESET}"
        echo -e "${DIM}git add config/app.conf${RESET}"
        echo -e "${DIM}git commit -m 'fix: increase worker count to 4'${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.6 — Merge Feature Branch${RESET}"
        echo -e "${DIM}git merge --no-ff feature/monitoring${RESET}"
        echo -e "${DIM}git log --oneline --graph --all${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.7 — Tag a Release${RESET}"
        echo -e "${DIM}git tag -a v1.0.0 -m 'First stable release'${RESET}"
        echo -e "${DIM}git tag -l${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.8 — Practice Stash${RESET}"
        echo "Make some changes, stash them, make another commit, pop stash"
        echo -e "${DIM}echo 'work in progress' >> config/app.conf${RESET}"
        echo -e "${DIM}git stash push -m 'WIP: testing'${RESET}"
        echo -e "${DIM}git stash list${RESET}"
        echo -e "${DIM}touch config/emergency_fix.conf && git add . && git commit -m 'fix: emergency'${RESET}"
        echo -e "${DIM}git stash pop${RESET}"
        echo ""
        echo -e "${BOLD}TASK 7.9 — Diff and History${RESET}"
        echo -e "${DIM}git diff v1.0.0 HEAD --stat${RESET}"
        echo -e "${DIM}git log --oneline --graph --all${RESET}"
        echo -e "${DIM}git log --author='Ali' --oneline${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE:${RESET}"
        echo "Create 5 more branches, make changes on each, merge them all."
        echo "After each merge read: git log --oneline --graph --all"
        echo "Until you understand the graph output without thinking."
        echo ""
        echo -e "${GREEN}When done: techflow verify 7${RESET}"
        ;;
    8)
        echo -e "${BOLD}${CYAN}MISSION 8 — Text Processing Mastery${RESET}"
        echo -e "${DIM}Difficulty: Hard | ~60 min | All text commands${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} Pure pipeline challenges. Solve each with one command or pipeline."
        echo "All data is in ~/techflow/data/ and ~/techflow/logs/"
        echo ""
        echo "  C8.1  Count unique servers in metrics.csv"
        echo -e "        ${DIM}cut -d',' -f2 ~/techflow/data/metrics.csv | sort | uniq | wc -l${RESET}"
        echo ""
        echo "  C8.2  Find all metrics rows where CPU > 90%"
        echo -e "        ${DIM}awk -F',' 'NR>1 && \$3>90 {print \$2, \$3\"%\"}' ~/techflow/data/metrics.csv${RESET}"
        echo ""
        echo "  C8.3  Count how many 404 errors in access.log"
        echo -e "        ${DIM}awk '\$9==404' ~/techflow/logs/access.log | wc -l${RESET}"
        echo ""
        echo "  C8.4  Find duplicate IPs in ips.txt and how many duplicates"
        echo -e "        ${DIM}sort ~/techflow/data/ips.txt | uniq -d | wc -l${RESET}"
        echo ""
        echo "  C8.5  Extract all unique HTTP status codes from access.log"
        echo -e "        ${DIM}awk '{print \$9}' ~/techflow/logs/access.log | sort | uniq${RESET}"
        echo ""
        echo "  C8.6  Sum all network_in values from metrics.csv for web-01 only"
        echo -e "        ${DIM}awk -F',' '\$2==\"web-01\" {sum+=\$6} END {print \"Total:\",sum}' ~/techflow/data/metrics.csv${RESET}"
        echo ""
        echo "  C8.7  Show lines 500-510 of syslog.log"
        echo -e "        ${DIM}sed -n '500,510p' ~/techflow/logs/syslog.log${RESET}"
        echo ""
        echo "  C8.8  Find lines in syslog matching BOTH 'ERROR' AND 'postgres'"
        echo -e "        ${DIM}grep 'ERROR' ~/techflow/logs/syslog.log | grep 'postgres'${RESET}"
        echo ""
        echo "  C8.9  Convert app.conf to uppercase"
        echo -e "        ${DIM}tr '[:lower:]' '[:upper:]' < ~/techflow/config/app.conf${RESET}"
        echo ""
        echo "  C8.10 Remove all comment lines from app.conf (lines starting with #)"
        echo -e "        ${DIM}grep -v '^#' ~/techflow/config/app.conf${RESET}"
        echo -e "        ${DIM}sed '/^#/d' ~/techflow/config/app.conf${RESET}"
        echo ""
        echo "  C8.11 Count words, lines, chars in syslog.log"
        echo -e "        ${DIM}wc ~/techflow/logs/syslog.log${RESET}"
        echo ""
        echo "  C8.12 Find top 5 most common error messages (not just ERROR level)"
        echo -e "        ${DIM}grep 'ERROR' ~/techflow/logs/syslog.log | awk '{for(i=7;i<=NF;i++) printf \$i\" \"; print \"\"}' | sort | uniq -c | sort -rn | head -5${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}MASTERY TEST:${RESET}"
        echo "Close terminal. Open new one. Solve C8.2, C8.6, C8.8 from memory."
        echo "If you can do it without looking, you own those commands."
        echo ""
        echo -e "${GREEN}When done: techflow verify 8${RESET}"
        ;;
    9)
        echo -e "${BOLD}${CYAN}MISSION 9 — System Administration${RESET}"
        echo -e "${DIM}Difficulty: Hard | ~60 min | Commands: useradd usermod groupadd passwd chmod chown sudo apt dpkg systemctl crontab vmstat iostat${RESET}"
        echo ""
        echo -e "${YELLOW}SITUATION:${RESET} You are the sysadmin now. Users, permissions,"
        echo "packages, services, monitoring. Everything runs through you."
        echo ""
        echo -e "${BOLD}TASK 9.1 — Create Service User${RESET}"
        echo -e "${DIM}sudo useradd -m -s /bin/bash devops-test${RESET}"
        echo -e "${DIM}id devops-test${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.2 — Create Group and Add Users${RESET}"
        echo -e "${DIM}sudo groupadd techflow-team${RESET}"
        echo -e "${DIM}sudo usermod -aG techflow-team devops-test${RESET}"
        echo -e "${DIM}sudo usermod -aG techflow-team \$USER${RESET}"
        echo -e "${DIM}groups devops-test${RESET}"
        echo -e "${DIM}id devops-test${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.3 — Shared Directory with Group Permissions${RESET}"
        echo -e "${DIM}sudo mkdir /opt/techflow-shared${RESET}"
        echo -e "${DIM}sudo chgrp techflow-team /opt/techflow-shared${RESET}"
        echo -e "${DIM}sudo chmod 770 /opt/techflow-shared${RESET}"
        echo -e "${DIM}ls -la /opt/techflow-shared${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.4 — Install Packages${RESET}"
        echo -e "${DIM}sudo apt update${RESET}"
        echo -e "${DIM}sudo apt install -y jq tree${RESET}"
        echo -e "${DIM}dpkg -l | grep jq${RESET}"
        echo -e "${DIM}which jq && jq --version${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.5 — Service Check${RESET}"
        echo -e "${DIM}systemctl list-units --type=service --state=running${RESET}"
        echo -e "${DIM}systemctl list-unit-files --state=enabled | head -20${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.6 — Collect System Stats${RESET}"
        echo -e "${DIM}vmstat 2 10 > ~/techflow/reports/vmstat.txt${RESET}"
        echo -e "${DIM}iostat -x 2 10 > ~/techflow/reports/iostat.txt${RESET}"
        echo -e "${DIM}cat ~/techflow/reports/vmstat.txt${RESET}"
        echo -e "${DIM}Question: what was peak IO wait (wa column)?${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.7 — Schedule a Cron Job${RESET}"
        echo -e "${DIM}crontab -e${RESET}"
        echo -e "${DIM}Add: */5 * * * * df -h >> ~/techflow/logs/disk_monitor.log 2>&1${RESET}"
        echo -e "${DIM}crontab -l  # verify it is there${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.8 — Generate SSH Keys${RESET}"
        echo -e "${DIM}ssh-keygen -t ed25519 -f ~/.ssh/techflow_key -N '' -C 'techflow-deploy'${RESET}"
        echo -e "${DIM}ls -la ~/.ssh/${RESET}"
        echo -e "${DIM}cat ~/.ssh/techflow_key.pub${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.9 — Lock and Unlock User${RESET}"
        echo -e "${DIM}sudo passwd -l devops-test${RESET}"
        echo -e "${DIM}sudo passwd -S devops-test${RESET}"
        echo -e "${DIM}sudo passwd -u devops-test${RESET}"
        echo -e "${DIM}sudo passwd -S devops-test${RESET}"
        echo ""
        echo -e "${BOLD}TASK 9.10 — Clean Up${RESET}"
        echo "Remove the test user and group completely"
        echo -e "${DIM}sudo userdel -r devops-test${RESET}"
        echo -e "${DIM}sudo groupdel techflow-team${RESET}"
        echo -e "${DIM}sudo rm -rf /opt/techflow-shared${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}REPEAT CHALLENGE:${RESET}"
        echo "Redo tasks 9.1-9.4 from memory. Time yourself."
        echo "Goal: under 3 minutes for the whole sequence."
        echo ""
        echo -e "${GREEN}When done: techflow verify 9${RESET}"
        ;;
    *)
        echo -e "${YELLOW}Mission $N not found. Available: 1-9${RESET}"
        echo "Run: techflow (no arguments) to see the menu"
        ;;
    esac
    echo ""
}

verify() {
    local N=$1
    header
    echo -e "${BOLD}Auto-checking Mission $N...${RESET}"
    echo ""
    local pass=0 fail=0

    chk() {
        local desc=$1; shift
        if eval "$@" > /dev/null 2>&1; then
            echo -e "  ${GREEN}[PASS]${RESET} $desc"; ((pass++)) || true
        else
            echo -e "  ${RED}[FAIL]${RESET} $desc"; ((fail++)) || true
        fi
    }

    case $N in
    1)
        chk "techflow directory exists" "[ -d $HOME/techflow ]"
        chk "logs dir exists" "[ -d $HOME/techflow/logs ]"
        chk "data dir exists" "[ -d $HOME/techflow/data ]"
        chk "config dir exists" "[ -d $HOME/techflow/config ]"
        chk "syslog.log exists and not empty" "[ -s $HOME/techflow/logs/syslog.log ]"
        chk "access.log exists" "[ -s $HOME/techflow/logs/access.log ]"
        chk "metrics.csv exists" "[ -s $HOME/techflow/data/metrics.csv ]"
        chk "mystery files exist" "[ -f $HOME/techflow/data/mystery1 ]"
        chk "app/server.py exists" "[ -f $HOME/techflow/app/server.py ]"
        chk "uname works" "uname -a"
        chk "ss works" "ss -tulnp"
        chk "ps works" "ps aux | head -3"
        ;;
    2)
        chk "old_debug.log compressed" "[ -f $HOME/techflow/logs/old_debug.log.gz ]"
        local p=$(stat -c '%a' "$HOME/techflow/config/secret.conf" 2>/dev/null || echo "000")
        chk "secret.conf permissions are 600 (currently: $p)" "[ '$p' = '600' ]"
        chk "app.conf has no 'development'" "! grep -q 'development' $HOME/techflow/config/app.conf"
        chk "CHECKSUMS.txt exists" "[ -f $HOME/techflow/config/CHECKSUMS.txt ]"
        chk "symlink 'current' exists" "[ -L $HOME/techflow/current ]"
        chk "backups directory exists" "[ -d $HOME/techflow/backups ]"
        ;;
    3)
        chk "syslog has ERROR lines" "grep -q 'ERROR' $HOME/techflow/logs/syslog.log"
        chk "access.log has content" "[ -s $HOME/techflow/logs/access.log ]"
        chk "metrics.csv has content" "[ -s $HOME/techflow/data/metrics.csv ]"
        chk "awk is available" "which awk"
        chk "sort is available" "which sort"
        chk "uniq is available" "which uniq"
        echo ""
        echo -e "  ${CYAN}Self-check — answer these:${RESET}"
        echo -e "  1. $(grep -c 'ERROR' $HOME/techflow/logs/syslog.log) ERROR lines in syslog.log"
        echo -e "  2. $(awk '{print $1}' $HOME/techflow/logs/access.log | sort | uniq -c | sort -rn | head -1) is the top IP"
        ;;
    4)
        chk "server.py exists" "[ -f $HOME/techflow/app/server.py ]"
        chk "app NOT currently running (cleanup check)" "! pgrep -f server.py > /dev/null"
        chk "kill command works" "kill --help"
        chk "pgrep works" "pgrep --help"
        ;;
    5)
        chk "internet reachable" "ping -c 1 -W 3 8.8.8.8"
        chk "dig available" "which dig || which nslookup"
        chk "nc available" "which nc"
        chk "curl works" "curl -s --max-time 5 https://httpbin.org/ip"
        chk "ss works" "ss -tulnp"
        ;;
    6)
        for s in health_check.sh backup.sh log_report.sh monitor.sh setup_env.sh; do
            chk "$s exists" "[ -f $HOME/techflow/scripts/$s ]"
            chk "$s has shebang" "head -1 $HOME/techflow/scripts/$s | grep -q bash"
            chk "$s has set -euo pipefail" "grep -q 'set -euo pipefail' $HOME/techflow/scripts/$s"
            chk "$s syntax is valid" "bash -n $HOME/techflow/scripts/$s"
        done
        ;;
    7)
        chk "git repo initialized" "[ -d $HOME/techflow/.git ]"
        chk "at least 3 commits" "[ \$(cd $HOME/techflow && git log --oneline 2>/dev/null | wc -l) -ge 3 ]"
        chk "tag v1.0.0 exists" "cd $HOME/techflow && git tag | grep -q 'v1.0.0'"
        chk ".gitignore exists" "[ -f $HOME/techflow/.gitignore ]"
        ;;
    8)
        chk "metrics.csv has data" "[ -s $HOME/techflow/data/metrics.csv ]"
        chk "access.log has data" "[ -s $HOME/techflow/logs/access.log ]"
        chk "awk available" "which awk"
        chk "sed available" "which sed"
        chk "tr available" "which tr"
        echo ""
        echo -e "  ${CYAN}Quick spot check:${RESET}"
        echo -e "  Unique servers: $(cut -d',' -f2 $HOME/techflow/data/metrics.csv | sort | uniq | grep -v server | wc -l)"
        echo -e "  404 errors: $(awk '$9==404' $HOME/techflow/logs/access.log | wc -l)"
        echo -e "  Top IP hits: $(awk '{print $1}' $HOME/techflow/logs/access.log | sort | uniq -c | sort -rn | head -1)"
        ;;
    9)
        chk "ssh key generated" "[ -f $HOME/.ssh/techflow_key ]"
        chk "reports directory has content" "ls $HOME/techflow/reports/ 2>/dev/null | grep -q '.'"
        chk "crontab has an entry" "crontab -l 2>/dev/null | grep -q techflow"
        chk "sudo works" "sudo true"
        ;;
    *)
        echo "No auto-check for mission $N. Self-verify against task list."
        ;;
    esac

    echo ""
    echo -e "  ${BOLD}Result: ${GREEN}$pass passed${RESET} | ${RED}$fail failed${RESET}${RESET}"
    echo ""
    if [ "$fail" -eq 0 ]; then
        echo -e "  ${GREEN}All checks passed! Run: techflow done $N${RESET}"
    else
        echo -e "  ${YELLOW}Fix the failing checks then run: techflow verify $N again${RESET}"
    fi
    echo ""
}

hint() {
    local N=$1
    echo -e "${YELLOW}Hints for Mission $N:${RESET}"
    echo ""
    case $N in
    1) echo "  uname -a gives everything on one line"
       echo "  Compare uptime load to: nproc (number of CPUs)"
       echo "  ss -tulnp | column -t makes output readable"
       echo "  tree -L 2 ~/techflow shows structure cleanly"
       echo "  file command reads magic bytes — works on any file" ;;
    2) echo "  find ~/techflow -type f | xargs ls -lhS shows files by size"
       echo "  gzip compresses in place — original is replaced by .gz"
       echo "  sed -i edits file in place — test without -i first"
       echo "  stat -c '%a' file gives octal permissions number"
       echo "  ln -s TARGET LINKNAME — target first, link name second" ;;
    3) echo "  grep -c counts matches — faster than | wc -l"
       echo "  awk '{print \$1}' gives first column (IP address)"
       echo "  awk '\$9==500' filters rows where column 9 equals 500"
       echo "  sort | uniq -c | sort -rn | head gives top N most frequent"
       echo "  NR>1 in awk skips the header row of CSV files" ;;
    4) echo "  nohup cmd > log 2>&1 & runs in background, survives logout"
       echo "  \$! gives PID of last background command"
       echo "  pgrep -f matches against full command line"
       echo "  nice -n 19 = lowest priority (most polite to other processes)"
       echo "  kill sends SIGTERM (polite). kill -9 sends SIGKILL (force)" ;;
    5) echo "  ip a is short for ip addr show"
       echo "  dig @8.8.8.8 domain — @ specifies which DNS server"
       echo "  nc -zv host port — z=scan only, v=verbose result"
       echo "  curl -s silences progress. -I does HEAD only"
       echo "  dig -x IP does reverse DNS lookup" ;;
    6) echo "  bash -n script.sh checks syntax without running"
       echo "  bash -x script.sh shows each command before running (debug)"
       echo "  trap 'cmd' EXIT runs cmd when script exits for any reason"
       echo "  TIMESTAMP=\$(date +%F_%H%M%S) gives sortable timestamps"
       echo "  mktemp -d creates a unique temp directory safely" ;;
    7) echo "  git log --oneline --graph --all shows everything visually"
       echo "  git checkout -b name creates AND switches in one step"
       echo "  git stash push -m 'message' saves with a label"
       echo "  git merge --no-ff always creates a merge commit"
       echo "  git diff v1.0.0 HEAD --stat shows what changed since tag" ;;
    8) echo "  awk -F',' sets comma as field separator for CSV"
       echo "  NR>1 skips the header row"
       echo "  sum[\$2] groups data by column 2 value"
       echo "  END{} block runs after all lines are processed"
       echo "  sort | uniq -c | sort -rn | head -5 = top 5 most frequent" ;;
    9) echo "  useradd -m creates home dir. -s sets shell"
       echo "  usermod -aG group user — -a means APPEND (do not replace)"
       echo "  chmod 770 = owner rwx, group rwx, others nothing"
       echo "  sudo passwd -l username LOCKS an account"
       echo "  ssh-keygen -t ed25519 -N '' creates key with no passphrase" ;;
    *) echo "  Re-read the task list carefully. Each task has command hints." ;;
    esac
    echo ""
}

CMD="${1:-help}"
ARG="${2:-}"

case "$CMD" in
    mission) mission "$ARG" ;;
    verify)  verify "$ARG" ;;
    hint)    hint "$ARG" ;;
    done)
        mark_done "$ARG"
        echo -e "${GREEN}Mission $ARG complete! Unlocked Mission $((ARG+1))${RESET}"
        echo -e "Next: ${CYAN}techflow mission $((ARG+1))${RESET}"
        ;;
    reset)
        read -p "Reset all progress? (yes/no): " c
        [ "$c" = "yes" ] && echo -e "DONE=\nCURRENT=1" > "$PROGRESS" && echo "Reset done."
        ;;
    *) menu ;;
esac
MISSIONEOF

chmod +x ~/techflow/techflow

# Add to PATH
grep -q 'techflow' ~/.bashrc 2>/dev/null || {
    echo '' >> ~/.bashrc
    echo '# TechFlow DevOps Training' >> ~/.bashrc
    echo 'export PATH="$HOME/techflow:$PATH"' >> ~/.bashrc
    echo "alias tf='techflow'" >> ~/.bashrc
}

# Apply immediately
export PATH="$HOME/techflow:$PATH"
alias tf='techflow'

echo ""
echo "==> Part 3 done. Mission runner installed."
echo ""
echo "============================================"
echo "  TechFlow Training Environment is READY"
echo "============================================"
echo ""
echo "  Run these now:"
echo "    source ~/.bashrc"
echo "    techflow"
echo ""

