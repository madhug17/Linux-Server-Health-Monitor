# Linux Server Health Monitor

A Bash-based Linux system monitoring tool that tracks CPU usage, memory utilization, disk space, and TCP port availability. It records timestamped health logs, checks configurable thresholds, and supports email alerts for critical resource usage.

## Features

- **CPU monitoring:** Calculates CPU utilization using Linux system statistics.
- **Memory monitoring:** Measures memory usage from `/proc/meminfo`.
- **Disk monitoring:** Checks root filesystem utilization.
- **Port monitoring:** Checks whether configured TCP ports are listening.
- **Threshold alerts:** Supports configurable warning and critical levels.
- **Logging:** Records timestamped results in a log file.
- **Email alerts:** Supports email notifications for critical threshold events through the system mail utility.
- **Automation:** Supports scheduled execution with cron.
- **Testing:** Includes Bash syntax checks and threshold behavior tests.

## Tech Stack

- Bash
- Linux / Ubuntu
- `/proc` and `df`
- `ss`
- cron
- Postfix and `mail`
- Git and GitHub

## Project Structure

```text
server-health-monitor/
├── config/
│   └── monitor.conf
├── logs/
├── scripts/
│   ├── health_monitor.sh
│   └── thresholds.sh
├── tests/
│   └── test_health_monitor.sh
├── .gitignore
└── README.md
```

## Setup

Clone the repository and enter the project directory:

```bash
git clone https://github.com/madhug17/Linux-Server-Health-Monitor.git
cd Linux-Server-Health-Monitor
```

Ensure the scripts are executable:

```bash
chmod +x scripts/health_monitor.sh
chmod +x tests/test_health_monitor.sh
```

Review `config/monitor.conf` and adjust the warning thresholds, critical thresholds, monitored TCP ports, and alert email settings.

## Run the Monitor

```bash
./scripts/health_monitor.sh
```

View recent logs:

```bash
tail -n 20 logs/health_monitor.log
```

## Run Tests

```bash
bash -n scripts/health_monitor.sh
bash -n scripts/thresholds.sh
bash tests/test_health_monitor.sh
```

## Schedule with Cron

Open the user's crontab:

```bash
crontab -e
```

Add the following line, replacing the path if your project is installed elsewhere:

```cron
*/5 * * * * /home/goundlamadhugoud/projects/server-health-monitor/scripts/health_monitor.sh
```

Verify the schedule:

```bash
crontab -l
```

Cron requires the Linux environment to be running. In WSL, scheduled execution depends on WSL and the cron service remaining active.

## Configuration

Resource warning and critical thresholds and monitored TCP ports are configured in `config/monitor.conf`.

Do not store SMTP passwords, app passwords, or other secrets in this repository. Configure email delivery securely on the host.

## Example Output

```text
[2026-10-19 06:59:23] [OK      ] CPU usage is 0%
[2026-10-19 06:59:23] [OK      ] Memory usage is 7%
[2026-10-19 06:59:23] [OK      ] Root disk usage is 1%
[2026-10-19 06:59:23] [OK      ] TCP port 22 is LISTENING
[2026-10-19 06:59:23] [WARNING ] TCP port 8000 is NOT LISTENING
```

The values above are illustrative examples from a test run; results vary by system.

## Future Improvements

- Add disk and port alert policies.
- Add monitoring for multiple filesystems and services.
- Improve automated integration testing.
- Add structured metrics and a dashboard.
