# Ghost Post Closer - Technical Documentation

## System Overview

The Ghost Post Closer is an automated content management utility designed to maintain post relevance in a Ghost blog installation. It identifies and marks outdated content by appending "[CLOSED]" to post titles based on configurable time-based rules and tag-based exceptions.

## Architecture

The system is built on Node.js and follows an event-driven architecture with scheduled task execution. It interfaces with the Ghost Content API and Telegram messaging services through RESTful API calls.

### Core Components

1. **Task Scheduler**: Implements cron-based scheduling to execute the main process at configurable intervals
2. **Ghost API Client**: Handles authentication and communication with the Ghost Admin API
3. **Post Processor**: Contains the business logic for determining which posts require modification
4. **Notification Service**: Manages communication with the Telegram API for status reporting
5. **Health Monitor**: Implements self-diagnostic capabilities to ensure continuous operation
6. **Logging System**: Provides comprehensive activity tracking and error reporting

## Technical Specifications

### Runtime Environment

- **Platform**: Node.js (v14+)
- **Primary Dependencies**:
    - @tryghost/admin-api: Ghost API client library
    - node-cron: Task scheduling library
    - axios: HTTP client for API communication
    - moment: Date/time manipulation library

### Data Flow

1. The scheduler triggers the main process at the configured time (default: 8 AM daily)
2. The system authenticates with the Ghost Admin API using JWT
3. All published posts with their associated tags are retrieved
4. Each post is evaluated against the closure criteria:
    - Posts with the "Resource" tag are excluded from processing
    - Posts with a `#closes-YYYY-MM-DD` tag are closed 5 days after the specified date
    - Posts without custom close dates are closed 90 days after publication
5. For posts meeting closure criteria, the system:
    - Retrieves the current version to obtain the `updated_at` timestamp
    - Updates the title with the "[CLOSED]" suffix
    - Records the modification details
6. A status report is generated and transmitted via Telegram
7. Health check data is updated

### System Interfaces

### Ghost Admin API

- **Authentication Method**: JWT (JSON Web Token)
- **API Version**: v5
- **Endpoints Used**:
    - `GET /ghost/api/v5/admin/posts`: Retrieve posts with tags
    - `GET /ghost/api/v5/admin/posts/{id}`: Get specific post details
    - `PUT /ghost/api/v5/admin/posts/{id}`: Update post title

### Telegram API

- **Authentication Method**: Bot Token
- **Endpoints Used**:
    - `POST /bot{token}/sendMessage`: Send notifications

### File Structure

```
/opt/ghost-post-closer/
├── ghost-post-closer.js    # Main application script
├── package.json            # Node.js package configuration
├── health.log              # Health check status file
├── logs/
│   ├── ghost-closer.log    # Standard operation logs
│   └── ghost-closer-error.log  # Error logs

```

### Configuration Parameters

| Parameter | Description | Default | Notes |
| --- | --- | --- | --- |
| ghost.url | Ghost blog URL | - | Required |
| ghost.key | Admin API key | - | Format: id:secret |
| ghost.version | API version | v5 | Must match Ghost installation |
| telegram.botToken | Telegram bot token | - | Required |
| telegram.chatId | Telegram chat ID | - | Required |
| schedule | Cron schedule expression | 0 8 * * * | Daily at 8 AM |
| healthCheck.enabled | Enable health monitoring | true | Boolean |
| healthCheck.interval | Hours between checks | 24 | Integer |
| excludedTags | Tags that exempt posts | ["Resource"] | Array of strings |

## Operational Procedures

### Deployment Process

1. **Server Preparation**:
    - Ensure Node.js v14+ is installed
    - Create the application directory structure
    - Set appropriate file permissions
2. **Application Installation**:
    - Copy the application script to the server
    - Install required dependencies
    - Configure environment-specific parameters
3. **Process Management Setup**:
    - Install PM2 process manager
    - Configure the application as a managed service
    - Enable automatic startup on system boot

### Monitoring and Maintenance

### Health Monitoring

The system implements a self-diagnostic mechanism that:

- Records successful operation timestamps
- Verifies operational status at regular intervals
- Sends alerts if operational anomalies are detected

### Log Management

- Standard operation logs are stored in `ghost-closer.log`
- Error conditions are recorded in `ghost-closer-error.log`
- Log rotation should be implemented to prevent file size issues

### Performance Considerations

- The script's execution time scales linearly with the number of posts
- Memory usage is typically minimal (<100MB)
- Network bandwidth requirements depend on the number of posts processed

### Error Handling and Recovery

The system implements multiple error handling mechanisms:

1. **API Communication Errors**:
    - Failed API calls are logged with detailed error information
    - The system continues processing remaining posts when possible
    - Error notifications are sent via Telegram
2. **Process Failures**:
    - PM2 automatically restarts the process if it crashes
    - The health check system detects extended periods of inactivity
3. **Recovery Procedures**:
    - System automatically resumes operation after temporary failures
    - Manual intervention may be required for persistent API authentication issues

## Security Considerations

### Authentication

- Ghost Admin API key provides full administrative access
- Telegram bot token allows sending messages to the configured chat

### Data Protection

- No user data is stored persistently
- API credentials are stored in plaintext in the script
- File permissions should be restricted to prevent unauthorized access

### Network Security

- All API communication occurs over HTTPS
- No inbound network connections are required
- Firewall rules should allow outbound HTTPS connections

## Customization and Extension

### Modifying Closure Rules

- The default 90-day closure period can be adjusted in the `shouldClosePost()` function
- The 5-day grace period for custom close dates can be modified in the same function

### Adding Excluded Tags

- Additional tags can be added to the `excludedTags` array in the configuration
- Tag matching is case-insensitive

### Custom Notification Formats

- Telegram message templates can be modified in the `processOldPosts()` function
- HTML formatting is supported for enhanced message presentation

## Troubleshooting Guide

### Common Issues and Resolutions

| Issue | Possible Causes | Resolution |
| --- | --- | --- |
| Authentication failures | Invalid API key, expired token | Regenerate Ghost Admin API key |
| Posts not being closed | Incorrect tag format, excluded tags | Verify tag format and exclusion rules |
| Missing notifications | Invalid Telegram credentials, bot permissions | Verify bot token and chat ID, ensure bot has permission to post |
| Script not running | PM2 configuration, system resources | Check PM2 status, verify system resource availability |
| Excessive log growth | Missing log rotation | Implement logrotate configuration |

### Diagnostic Procedures

1. **Verify API Connectivity**:
    
    ```bash
    curl -I <https://your-ghost-blog-url.com/ghost/api/v5/admin/>
    
    ```
    
2. **Test Telegram Integration**:
    
    ```bash
    curl -X POST "<https://api.telegram.org/bot><TOKEN>/sendMessage" -d "chat_id=<CHAT_ID>&text=Test"
    
    ```
    
3. **Check Process Status**:
    
    ```bash
    pm2 status ghost-post-closer
    
    ```
    
4. **Review Recent Logs**:
    
    ```bash
    tail -n 100 /opt/ghost-post-closer/logs/ghost-closer.log
    
    ```
    
5. **Verify Health Check**:
    
    ```bash
    cat /opt/ghost-post-closer/health.log
    
    ```
    

---

---

## Installation

### Prerequisites

- Node.js (v14 or higher)
- npm (Node Package Manager)
- A Ghost blog with Admin API access
- A Telegram bot and group/channel

### Setup on Digital Ocean VPS

1. **Create the application directory structure**:
    
    ```bash
    mkdir -p /opt/ghost-post-closer/logs
    cd /opt/ghost-post-closer
    
    ```
    
2. **Create the script file**:
    
    ```bash
    nano ghost-post-closer.js
    
    ```
    
    Paste the script code and update the configuration section.
    
3. **Make the script executable**:
    
    ```bash
    chmod +x ghost-post-closer.js
    
    ```
    
4. **Initialize npm and install dependencies**:
    
    ```bash
    npm init -y
    npm install @tryghost/admin-api node-cron axios moment
    
    ```
    

## Configuration

Edit the CONFIG object in the script to customize its behavior:

```jsx
const CONFIG = {
  ghost: {
    url: '<https://your-ghost-blog-url.com>', // Your Ghost blog URL
    key: 'your-admin-api-key',              // Your Ghost Admin API key
    version: 'v5'                           // Ghost API version
  },
  telegram: {
    botToken: 'your-telegram-bot-token',    // Telegram bot token
    chatId: 'your-telegram-chat-id'         // Telegram chat/group ID
  },
  schedule: '0 8 * * *',                    // Cron schedule (8 AM daily)
  healthCheck: {
    enabled: true,                          // Enable health monitoring
    interval: 24,                           // Hours between health checks
    logPath: path.join(__dirname, 'health.log') // Health log file path
  }
};

```

## Running the Script

### Manual Execution

To run the script manually:

```bash
node ghost-post-closer.js

```

### Using PM2 (Recommended for Production)

1. **Install PM2 globally**:
    
    ```bash
    sudo npm install -g pm2
    
    ```
    
2. **Start the script with PM2**:
    
    ```bash
    pm2 start ghost-post-closer.js --name ghost-post-closer
    
    ```
    
3. **Configure PM2 to start on system boot**:
    
    ```bash
    pm2 startup
    pm2 save
    
    ```
    

## PM2 Management Commands

- **Check status**:
    
    ```bash
    pm2 status
    
    ```
    
- **View logs**:
    
    ```bash
    pm2 logs ghost-post-closer
    
    ```
    
- **Restart the script**:
    
    ```bash
    pm2 restart ghost-post-closer
    
    ```
    
- **Stop the script**:
    
    ```bash
    pm2 stop ghost-post-closer
    
    ```
    
- **Delete from PM2**:
    
    ```bash
    pm2 delete ghost-post-closer
    no
    ```
    

## Using Cron (Alternative to PM2)

If you prefer using cron instead of PM2:

1. **Edit the crontab**:
    
    ```bash
    crontab -e
    
    ```
    
2. **Add the following line**:
    
    ```
    0 8 * * * cd /opt/ghost-post-closer && /usr/bin/node ghost-post-closer.js >> /opt/ghost-post-closer/logs/cron.log 2>&1
    
    ```
    

## Log Files

The script maintains several log files:

- **Main log**: `/opt/ghost-post-closer/logs/ghost-closer.log`
- **Error log**: `/opt/ghost-post-closer/logs/ghost-closer-error.log`
- **Health check**: `/opt/ghost-post-closer/health.log`

To view logs:

```bash
# View main log
tail -f /opt/ghost-post-closer/logs/ghost-closer.log

# View error log
tail -f /opt/ghost-post-closer/logs/ghost-closer-error.log

```

## Maintenance Tasks

### Updating the Script

1. **Edit the script file**:
    
    ```bash
    nano /opt/ghost-post-closer/ghost-post-closer.js
    
    ```
    
2. **Restart the script**:
    
    ```bash
    pm2 restart ghost-post-closer
    
    ```
    

### Checking Disk Space

Monitor log file sizes:

```bash
du -sh /opt/ghost-post-closer/logs/

```

### Log Rotation

Set up log rotation to prevent logs from consuming too much disk space:

```bash
sudo nano /etc/logrotate.d/ghost-post-closer

```

Add the following configuration:

```
/opt/ghost-post-closer/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
}

```

## Troubleshooting

### Script Not Running

1. **Check PM2 status**:
    
    ```bash
    pm2 status
    
    ```
    
2. **Check for errors in logs**:
    
    ```bash
    pm2 logs ghost-post-closer
    
    ```
    
3. **Verify health check file**:
    
    ```bash
    cat /opt/ghost-post-closer/health.log
    
    ```
    

### API Connection Issues

1. **Verify Ghost URL and API key**:
    - Check if you can access the Ghost Admin panel
    - Regenerate the API key if necessary
2. **Check network connectivity**:
    
    ```bash
    curl -I <https://your-ghost-blog-url.com>
    
    ```
    

### Telegram Notification Issues

1. **Verify bot token and chat ID**:
    - Send a test message using curl:
    
    ```bash
    curl -X POST "<https://api.telegram.org/bot><YOUR_BOT_TOKEN>/sendMessage" -d "chat_id=<YOUR_CHAT_ID>&text=Test message"
    
    ```
    
2. **Check if the bot has permission to post in the group**

## Custom Tags Usage

To set a custom close date for a post:

1. In Ghost Admin, add a tag to the post in the format `#closes-YYYY-MM-DD`
2. The script will close the post 5 days after the specified date
3. For example, a tag of `#closes-2023-12-31` will close the post on January 5, 2024

## Backup and Recovery

### Backing Up the Script

```bash
tar -czvf ghost-post-closer-backup.tar.gz /opt/ghost-post-closer

```

### Restoring from Backup

```bash
tar -xzvf ghost-post-closer-backup.tar.gz -C /
cd /opt/ghost-post-closer
npm install
pm2 restart ghost-post-closer

```

## Security Considerations

- The script contains sensitive API keys and tokens in plain text
- Ensure the script directory has restricted permissions:
    
    ```bash
    chmod 700 /opt/ghost-post-closer
    chmod 600 /opt/ghost-post-closer/ghost-post-closer.js
    
    ```
    
- Consider using environment variables for sensitive information in more security-conscious environments

## Version History

- v1.0.0: Initial production release
- v1.1.0: Added custom close dates via tags
- v1.2.0: Added health monitoring and Telegram notifications

## Support and Maintenance

For issues or questions:

1. Check the error logs
2. Verify configuration settings
3. Ensure Ghost API is accessible
4. Update dependencies if needed:
    
    ```bash
    cd /opt/ghost-post-closer
    npm update
    
    ```