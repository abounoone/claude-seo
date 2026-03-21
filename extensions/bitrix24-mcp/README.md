# Bitrix24 MCP Extension

Integrates Claude with Bitrix24 CRM API via Model Context Protocol (MCP), allowing Claude
to read and manage CRM data, tasks, deals, and contacts directly from chat.

**Applicable when:** Your project uses Bitrix24 (cloud or self-hosted box) alongside or
instead of 1C-Bitrix Site Management.

---

## What This Extension Enables

With the MCP server connected, Claude can:
- List and create CRM deals, contacts, companies
- Read and update task statuses
- Query Bitrix24 calendar events
- Manage leads and pipelines
- Access Bitrix24 users and departments

---

## Setup: Community MCP Server

Uses the open-source server: **github.com/gunnit/bitrix24-mcp-server**

### Step 1: Get Bitrix24 Webhook URL

1. Log in to your Bitrix24 (cloud.bitrix24.ru or your domain)
2. Go to: **Developer resources → Other → Inbound webhook**
3. Select permissions: CRM, Tasks, Calendar (as needed)
4. Copy the webhook URL — it looks like:
   `https://yourdomain.bitrix24.ru/rest/1/your_webhook_token/`

**Security:** Keep this URL secret. It provides API access to your Bitrix24.

### Step 2: Install the MCP Server

```bash
# Clone the server
git clone https://github.com/gunnit/bitrix24-mcp-server.git
cd bitrix24-mcp-server

# Install dependencies
npm install

# Build
npm run build
```

### Step 3: Configure Claude Desktop

Add to `~/.claude/mcp_servers.json` or `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "bitrix24": {
      "command": "node",
      "args": ["/path/to/bitrix24-mcp-server/build/index.js"],
      "env": {
        "BITRIX24_WEBHOOK_URL": "https://yourdomain.bitrix24.ru/rest/1/your_token/"
      }
    }
  }
}
```

Replace `/path/to/bitrix24-mcp-server/` with actual path and your webhook URL.

### Step 4: Restart Claude Desktop

After saving the config, restart Claude Desktop. The Bitrix24 tools will appear automatically.

---

## Alternative: viaSocket (No-Code)

If you don't want to self-host the MCP server, use viaSocket:

1. Go to viasocket.com/mcp/bitrix24
2. Connect your Bitrix24 account
3. Get a unique MCP URL
4. Add to Claude Desktop config:

```json
{
  "mcpServers": {
    "bitrix24-viasocket": {
      "url": "https://mcp.viasocket.com/your-unique-url"
    }
  }
}
```

---

## Alternative: Native Bitrix24 MCP (Official)

Bitrix24 now has an official MCP server (announced Sept 2025):

1. In Bitrix24: **AI → CoPilot → MCP Settings**
2. Enable MCP and generate connection URL
3. Add to Claude Desktop config

Documentation: helpdesk.bitrix24.com/open/25846367/

---

## Security Best Practices

- **Rotate webhook tokens** if you suspect exposure
- **Use minimum permissions** — only enable CRM/Tasks scopes you actually need
- **Don't commit webhook URLs** to git — use environment variables
- The MCP server enforces **rate limiting** (2 req/sec) to respect Bitrix24 API limits

---

## Example Usage After Setup

Once connected, you can ask Claude:

- "Show me all open deals in Bitrix24"
- "Create a new contact for Ivan Petrov, phone +7-999-123-45-67"
- "What tasks are assigned to me this week?"
- "Change deal #123 status to Won"
- "List all companies in the CRM"
