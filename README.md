# DevOps Intern Assignment - Powerplay

---

## How to Clone

You can view, test, or reproduce the complete setup locally or in your own AWS environment.

### 🪜 1. Clone the Repository
```bash
git clone https://github.com/rohanjoshi15/Powerplay-DevopsInternAssignment.git
cd Powerplay-DevopsInternAssignment
```

## Part 1: EC2 Setup and User Configuration

### Steps:
1. **Launch an EC2 Instance**
   - Type: `t3.micro` (Free Tier) (t2 micro instance is not available in the updated versions)
   - OS: `Ubuntu 22.04`
   - Key Pair: `devopsintern.pem` RSA

2. **Connect via SSH**
   ```bash
   ssh -i /path/to/devopsintern.pem ubuntu@<EC2_PUBLIC_IP>
   ```

3. **Create a new user**
   ```bash
   sudo adduser devops_intern
   ```

4. **Grant sudo access without password**
   ```bash
   echo "devops_intern ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/devops_intern
   ```

5. **Change hostname**
   ```bash
   sudo hostnamectl set-hostname rohan-devops
   ```

6. **Verify changes**
   ```bash
   hostname
   ```

---

## Part 2: Web Server Setup (Nginx)

### Steps:
1. **Install Nginx**
   ```bash
   sudo apt update -y
   sudo apt install nginx -y
   ```

2. **Create HTML page**
   ```bash
   sudo tee /usr/local/bin/generate_index.sh > /dev/null <<'SH'
   #!/usr/bin/env bash
   NAME="ROHAN JOSHI"
   TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
   if [ -n "$TOKEN" ]; then
     INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
   else
     INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
   fi
   UPTIME=$(uptime -p)
   cat <<HTML | sudo tee /var/www/html/index.html >/dev/null
   <!doctype html>
   <html>
     <head><meta charset="utf-8"><title>DevOps Intern Page</title></head>
     <body style="font-family: Arial, sans-serif; margin: 2rem;">
       <h1>$NAME</h1>
       <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
       <p><strong>Server Uptime:</strong> $UPTIME</p>
     </body>
   </html>
   HTML
   SH
   ```

3. **Make script executable and run**
   ```bash
   sudo chmod +x /usr/local/bin/generate_index.sh
   sudo /usr/local/bin/generate_index.sh
   ```

4. **Access webpage**
   - Open: `http://<EC2_PUBLIC_IP>`

---

## Part 3: Monitoring Script and Cron Job

### Script: `/usr/local/bin/system_report.sh`
```bash
#!/usr/bin/env bash
LOGFILE="/var/log/system_report.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %z')
UPTIME=$(uptime -p)
CPU_IDLE=$(top -bn1 | awk -F'id,' -v RS=',' '/Cpu\(s\)/{print $1}' | awk '{print $NF}')
CPU_USAGE=$(awk -v idle="$CPU_IDLE" 'BEGIN{printf("%.2f",100-idle)}')
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')
MEM_PERC=$(awk -v u=$MEM_USED -v t=$MEM_TOTAL 'BEGIN{printf("%.2f",(u/t)*100)}')
DISK_PERC=$(df -h / | awk 'NR==2 {print $5}')
TOP3=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 4 | tail -n 3)

{
  echo "==== $TIMESTAMP ===="
  echo "Uptime: $UPTIME"
  echo "CPU Usage (%): $CPU_USAGE"
  echo "Memory Usage (%): $MEM_PERC"
  echo "Disk Usage (%): $DISK_PERC"
  echo "Top 3 Processes by CPU:"
  echo "$TOP3"
  echo ""
} >> "$LOGFILE"
```

### Cron Job: `/etc/cron.d/system_report`
```bash
*/5 * * * * root /usr/local/bin/system_report.sh
```

### Commands Used
```bash
sudo chmod +x /usr/local/bin/system_report.sh
sudo nano /etc/cron.d/system_report
sudo service cron start
sudo tail -n 20 /var/log/system_report.log
```

### Deliverables
- Screenshot of cron config file  
- Screenshot of `/var/log/system_report.log` after two runs

---

## Part 4: AWS CloudWatch Integration

### IAM Role
- Created IAM Role: `devopsInternCWRole`
- Attached policy: `CloudWatchLogsFullAccess`
- Attached role to EC2 instance

### Commands Used
```bash
aws logs create-log-group --log-group-name /devops/intern-metrics --region eu-north-1
aws logs create-log-stream --log-group-name /devops/intern-metrics --log-stream-name manual-upload-20251029161316 --region eu-north-1
```

### Upload Logs to CloudWatch
```bash
EVENTS_JSON="[]"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  TS=$(date +%s%3N)
  EVENTS_JSON=$(echo "$EVENTS_JSON" | jq --arg ts "$TS" --arg msg "$line" '. + [{"timestamp": ($ts|tonumber), "message": $msg}]')
done < system_report.log

aws logs put-log-events   --log-group-name "/devops/intern-metrics"   --log-stream-name "manual-upload-20251029161316"   --log-events "$(echo "$EVENTS_JSON")"   --region eu-north-1
```

### Verify
```bash
aws logs describe-log-groups --region eu-north-1
aws logs describe-log-streams --log-group-name /devops/intern-metrics --region eu-north-1
aws logs get-log-events --log-group-name /devops/intern-metrics --log-stream-name manual-upload-20251029161316 --region eu-north-1 --limit 10
```

---

**End of Documentation** 
