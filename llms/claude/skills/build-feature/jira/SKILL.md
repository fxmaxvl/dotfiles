---
name: jira
description: Interact with Jira tickets — read, transition, and comment. Discovers available Jira MCP tools dynamically.
disable-model-invocation: true
---

## Purpose

Provide Jira operations for the `build-feature` workflow. All Jira MCP tool names are discovered at runtime — never hardcode a specific tool namespace.

## Tool Discovery

Jira MCP tool names vary by user setup. The namespace prefix is not predictable.

**On first use**, discover the available Jira tools:
1. Look at the available tools list for any tool whose name contains `jira` and ends with `get-issues`
2. From the matched tool name, extract the full prefix (everything before `get-issues`)
3. If no Jira tools are found, report to the caller: "No Jira MCP tools available. Please configure a Jira MCP server and try again."

Once the prefix is known, the following operations map to these tool suffixes:
- **get-issues** — fetch ticket details (description, comments, status)
- **get-available-transitions** — list valid status transitions for a ticket
- **transition-issue** — move a ticket to a new status
- **comment-on-issue** — add a comment to a ticket
- **get-issue-changelog** — view ticket history

## Operations

### `read-ticket(ticket_key)`
1. Call `<prefix>get-issues` with the ticket key
2. Return the ticket's summary, description, comments, and current status

### `transition-to(ticket_key, target_status_name)`
1. Call `<prefix>get-available-transitions` for the ticket
2. Find the transition whose target status name matches `target_status_name` (case-insensitive, partial match OK — e.g., "in progress" matches "In Progress")
3. If no match found, list the available transitions and ask the user which one to use
4. Call `<prefix>transition-issue` with the matched transition ID

### `add-comment(ticket_key, comment_body)`
1. Call `<prefix>comment-on-issue` with the ticket key and comment body

### `ask-author(ticket_key, questions)`
1. Call `<prefix>get-issues` with the ticket key to identify the ticket's reporter/author
2. Format the comment: tag the author (mention them) and list the clarifying questions
3. Call `<prefix>comment-on-issue` with the formatted comment

### `check-for-answers(ticket_key, pending_questions)`
1. Call `<prefix>get-issues` with the ticket key to fetch the latest comments
2. Look for new comments added after the questions were posted
3. Try to match answers to the pending questions
4. Return which questions were answered (with the answers) and which are still pending

## Error Handling

- If a Jira API call fails, report the error clearly and ask the user how to proceed
- Never silently skip a Jira operation — the user needs to know if their ticket wasn't updated
