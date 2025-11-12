# CRM API Documentation

Complete REST API reference for the Social Media CRM platform.

## Table of Contents

1. [Authentication](#authentication)
2. [Conversations](#conversations)
3. [Messages](#messages)
4. [Contacts](#contacts)
5. [Inboxes & Channels](#inboxes--channels)
6. [Agents](#agents)
7. [Teams](#teams)
8. [Agent Shifts](#agent-shifts)
9. [SLA Policies](#sla-policies)
10. [Reports & Analytics](#reports--analytics)
11. [Error Handling](#error-handling)

---

## Base URL

```
http://localhost:3000/api/v1
```

## Authentication

All API endpoints (except signup/login) require JWT authentication.

**Header Format:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

### POST /auth/signup

Create a new user account.

**Request:**
```json
{
  "user": {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!"
  },
  "account_name": "My Company"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "display_name": null,
    "created_at": "2025-11-12T10:00:00Z"
  },
  "account": {
    "id": 1,
    "name": "My Company",
    "created_at": "2025-11-12T10:00:00Z"
  },
  "tokens": {
    "access_token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "message": "Registration successful"
}
```

### POST /auth/login

Authenticate and receive JWT tokens.

**Request:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "display_name": "John",
    "avatar_url": null,
    "created_at": "2025-11-12T10:00:00Z"
  },
  "accounts": [
    {
      "id": 1,
      "name": "My Company",
      "role": "administrator",
      "availability": "online"
    }
  ],
  "tokens": {
    "access_token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "message": "Login successful"
}
```

### POST /auth/refresh

Refresh expired access token using refresh token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Response:** `200 OK`
```json
{
  "tokens": {
    "access_token": "eyJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "message": "Token refreshed successfully"
}
```

### DELETE /auth/logout

Logout (client-side token removal).

**Response:** `200 OK`
```json
{
  "message": "Logout successful. Please remove the token from client storage."
}
```

---

## Conversations

Unified inbox for all messages across WhatsApp, Facebook, and Instagram.

### GET /accounts/:account_id/conversations

List all conversations with filtering and search.

**Query Parameters:**
- `status` - Filter by status: `open`, `resolved`, `pending`, `snoozed`
- `inbox_id` - Filter by specific inbox/channel
- `assignee_id` - Filter by assigned agent
- `team_id` - Filter by team
- `priority` - Filter by priority: `low`, `medium`, `high`, `urgent`
- `q` - Search by contact name or phone number
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 100)

**Example Request:**
```bash
GET /accounts/1/conversations?status=open&priority=high&page=1&per_page=25
```

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 1,
      "status": "open",
      "priority": "high",
      "inbox_id": 5,
      "inbox_name": "WhatsApp: +1234567890",
      "channel_type": "Channel::Whatsapp",
      "contact_id": 10,
      "contact_name": "Jane Smith",
      "assignee_id": 2,
      "assignee_name": "John Doe",
      "team_id": 3,
      "team_name": "Support Team",
      "unread_count": 2,
      "first_reply_created_at": "2025-11-12T10:15:00Z",
      "waiting_since": "2025-11-12T10:30:00Z",
      "created_at": "2025-11-12T10:00:00Z",
      "updated_at": "2025-11-12T10:30:00Z",
      "last_message": "Can you help me with my order?"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 125,
    "per_page": 25
  }
}
```

### GET /accounts/:account_id/conversations/:id

Get conversation details with all messages.

**Response:** `200 OK`
```json
{
  "conversation": {
    "id": 1,
    "status": "open",
    "priority": "high",
    "inbox_id": 5,
    "inbox_name": "WhatsApp: +1234567890",
    "channel_type": "Channel::Whatsapp",
    "contact_id": 10,
    "contact_name": "Jane Smith",
    "assignee_id": 2,
    "assignee_name": "John Doe",
    "unread_count": 2,
    "created_at": "2025-11-12T10:00:00Z",
    "updated_at": "2025-11-12T10:30:00Z"
  },
  "messages": [
    {
      "id": 1,
      "content": "Hi, I need help with my order",
      "message_type": "incoming",
      "content_type": "text",
      "sender_type": "Contact",
      "sender_id": 10,
      "created_at": "2025-11-12T10:00:00Z",
      "attachments": []
    },
    {
      "id": 2,
      "content": "Hello! I'd be happy to help. What's your order number?",
      "message_type": "outgoing",
      "content_type": "text",
      "sender_type": "User",
      "sender_id": 2,
      "created_at": "2025-11-12T10:05:00Z",
      "attachments": []
    }
  ],
  "contact": {
    "id": 10,
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone_number": "+1234567890",
    "avatar_url": null,
    "custom_attributes": {}
  }
}
```

### POST /accounts/:account_id/conversations/:id/assign

Assign conversation to an agent.

**Request:**
```json
{
  "user_id": 5
}
```

**Response:** `200 OK`
```json
{
  "conversation": { /* conversation object */ },
  "message": "Agent assigned successfully"
}
```

### POST /accounts/:account_id/conversations/:id/resolve

Mark conversation as resolved.

**Response:** `200 OK`
```json
{
  "conversation": { /* conversation with status: "resolved" */ },
  "message": "Conversation resolved"
}
```

### POST /accounts/:account_id/conversations/:id/reopen

Reopen a resolved conversation.

**Response:** `200 OK`
```json
{
  "conversation": { /* conversation with status: "open" */ },
  "message": "Conversation reopened"
}
```

### POST /accounts/:account_id/conversations/:id/update_priority

Update conversation priority.

**Request:**
```json
{
  "priority": "urgent"
}
```

**Response:** `200 OK`
```json
{
  "conversation": { /* conversation with updated priority */ },
  "message": "Priority updated"
}
```

---

## Messages

Send and receive messages across multiple platforms.

### POST /accounts/:account_id/conversations/:conversation_id/messages

Send a message (WhatsApp, Facebook, or Instagram).

**Request:**
```json
{
  "message": {
    "content": "Thank you for your message. How can I help you today?",
    "content_type": "text",
    "private": false,
    "attachments": []
  }
}
```

**Response:** `201 Created`
```json
{
  "message": {
    "id": 15,
    "content": "Thank you for your message. How can I help you today?",
    "message_type": "outgoing",
    "content_type": "text",
    "sender_type": "User",
    "sender_id": 2,
    "sender_name": "John Doe",
    "conversation_id": 1,
    "created_at": "2025-11-12T10:35:00Z",
    "updated_at": "2025-11-12T10:35:00Z",
    "attachments": [],
    "source_id": "whatsapp_msg_abc123",
    "private": false
  },
  "status": "Message sent successfully"
}
```

**Note:** The API automatically sends via the correct channel (WhatsApp/Facebook/Instagram) based on the conversation's inbox.

### GET /accounts/:account_id/conversations/:conversation_id/messages

List all messages in a conversation.

**Query Parameters:**
- `page` - Page number
- `per_page` - Items per page

**Response:** `200 OK`
```json
{
  "data": [
    { /* message object */ },
    { /* message object */ }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 35,
    "per_page": 25
  }
}
```

---

## Contacts

Manage customer contacts.

### GET /accounts/:account_id/contacts

List all contacts with search.

**Query Parameters:**
- `q` - Search by name, email, or phone
- `page` - Page number
- `per_page` - Items per page

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 10,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "phone_number": "+1234567890",
      "avatar_url": null,
      "identifier": "customer_12345",
      "custom_attributes": {
        "customer_tier": "premium",
        "signup_date": "2024-01-15"
      },
      "created_at": "2025-01-15T08:00:00Z",
      "updated_at": "2025-11-12T10:00:00Z",
      "conversations_count": 8
    }
  ],
  "meta": { /* pagination */ }
}
```

### GET /accounts/:account_id/contacts/:id

Get contact details.

**Response:** `200 OK`
```json
{
  "contact": { /* contact object */ },
  "contact_inboxes": [
    {
      "id": 5,
      "inbox_id": 2,
      "inbox_name": "WhatsApp: +1234567890",
      "source_id": "whatsapp_contact_id",
      "created_at": "2025-01-15T08:00:00Z"
    }
  ]
}
```

### POST /accounts/:account_id/contacts

Create a new contact.

**Request:**
```json
{
  "contact": {
    "name": "New Customer",
    "email": "customer@example.com",
    "phone_number": "+1234567890",
    "custom_attributes": {
      "source": "website",
      "product_interest": "premium_plan"
    }
  }
}
```

**Response:** `201 Created`
```json
{
  "contact": { /* created contact object */ }
}
```

### PATCH /accounts/:account_id/contacts/:id

Update contact information.

**Request:**
```json
{
  "contact": {
    "name": "Updated Name",
    "custom_attributes": {
      "customer_tier": "enterprise"
    }
  }
}
```

**Response:** `200 OK`
```json
{
  "contact": { /* updated contact object */ }
}
```

### GET /accounts/:account_id/contacts/:id/conversations

Get all conversations for a contact.

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 1,
      "status": "resolved",
      "inbox_name": "WhatsApp: +1234567890",
      "assignee_name": "John Doe",
      "last_message": "Thank you for your help!",
      "updated_at": "2025-11-11T15:00:00Z"
    }
  ],
  "meta": { /* pagination */ }
}
```

---

## Inboxes & Channels

Manage communication channels.

### GET /accounts/:account_id/inboxes

List all inboxes.

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 1,
      "name": "WhatsApp: +1234567890",
      "channel_type": "Channel::Whatsapp",
      "channel_id": 5,
      "greeting_enabled": true,
      "greeting_message": "Hi! How can we help you today?",
      "enable_auto_assignment": true,
      "working_hours_enabled": false,
      "out_of_office_message": null,
      "timezone": "UTC",
      "created_at": "2025-01-10T00:00:00Z",
      "updated_at": "2025-11-10T10:00:00Z"
    }
  ]
}
```

### POST /accounts/:account_id/channels/whatsapp

Create WhatsApp channel.

**Request:**
```json
{
  "channel": {
    "phone_number": "+1234567890",
    "provider": "whatsapp_cloud",
    "provider_config": {
      "api_key": "your_api_key",
      "phone_number_id": "123456789"
    }
  }
}
```

**Response:** `201 Created`
```json
{
  "channel": {
    "id": 5,
    "phone_number": "+1234567890",
    "provider": "whatsapp_cloud",
    "provider_config": { /* config */ },
    "created_at": "2025-11-12T10:00:00Z"
  },
  "inbox": {
    "id": 1,
    "name": "WhatsApp: +1234567890",
    "account_id": 1
  }
}
```

### POST /accounts/:account_id/channels/facebook

Create Facebook Messenger channel.

**Request:**
```json
{
  "channel": {
    "page_id": "facebook_page_id",
    "name": "My Business Page",
    "page_access_token": "page_token",
    "user_access_token": "user_token"
  }
}
```

**Response:** `201 Created`

### POST /accounts/:account_id/channels/instagram

Create Instagram Direct Message channel.

**Request:**
```json
{
  "channel": {
    "instagram_id": "instagram_account_id",
    "username": "mybusiness",
    "access_token": "access_token",
    "token_expires_at": "2025-12-12T00:00:00Z"
  }
}
```

**Response:** `201 Created`

### POST /accounts/:account_id/channels/instagram/:id/refresh_token

Refresh Instagram access token (expires every 60 days).

**Response:** `200 OK`
```json
{
  "channel": { /* channel with updated token */ },
  "message": "Token refreshed successfully",
  "new_expiry": "2026-01-12T00:00:00Z"
}
```

---

## Agents

Manage agents and track performance.

### GET /accounts/:account_id/agents

List all agents.

**Query Parameters:**
- `role` - Filter by role: `administrator`, `supervisor`, `agent`
- `availability` - Filter by availability: `online`, `offline`, `busy`

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 2,
      "user_id": 5,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "agent",
      "availability": "online",
      "active_at": "2025-11-12T10:00:00Z",
      "created_at": "2025-01-10T00:00:00Z",
      "updated_at": "2025-11-12T10:00:00Z"
    }
  ]
}
```

### GET /accounts/:account_id/agents/:id

Get agent details with metrics.

**Response:** `200 OK`
```json
{
  "agent": { /* agent object */ },
  "metrics": [
    {
      "date": "2025-11-12",
      "conversations_handled": 15,
      "avg_first_response_time": 120.5,
      "sla_met_count": 14,
      "online_duration": 28800
    }
  ],
  "current_shift": {
    "id": 10,
    "shift_start": "09:00:00",
    "shift_end": "17:00:00",
    "day_of_week": 2,
    "timezone": "America/New_York"
  }
}
```

### POST /accounts/:account_id/agents

Add agent to account.

**Request:**
```json
{
  "email": "newagent@example.com",
  "role": "agent",
  "availability": "online"
}
```

**Response:** `201 Created`
```json
{
  "agent": { /* created agent object */ }
}
```

### POST /accounts/:account_id/agents/:id/update_availability

Update agent availability status.

**Request:**
```json
{
  "availability": "busy"
}
```

**Response:** `200 OK`
```json
{
  "agent": { /* agent with updated availability */ },
  "message": "Availability updated from online to busy"
}
```

### GET /accounts/:account_id/agents/:id/performance

Get detailed agent performance metrics.

**Query Parameters:**
- `start_date` - Start date (default: 30 days ago)
- `end_date` - End date (default: today)

**Response:** `200 OK`
```json
{
  "agent": { /* agent object */ },
  "period": {
    "start_date": "2025-10-13",
    "end_date": "2025-11-12"
  },
  "metrics": {
    "total_conversations": 145,
    "resolved_conversations": 130,
    "resolution_rate": 89.66,
    "avg_first_response_seconds": 180,
    "avg_first_response_minutes": 3.0,
    "sla_compliance_rate": 92.5,
    "sla_met_count": 134,
    "sla_total_count": 145
  }
}
```

---

## Teams

Manage agent teams.

### GET /accounts/:account_id/teams

List all teams.

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 3,
      "name": "Support Team",
      "description": "Customer support team",
      "allow_auto_assign": true,
      "created_at": "2025-01-10T00:00:00Z",
      "updated_at": "2025-11-10T00:00:00Z",
      "members_count": 8
    }
  ]
}
```

### GET /accounts/:account_id/teams/:id

Get team details with members.

**Response:** `200 OK`
```json
{
  "team": { /* team object */ },
  "members": [
    {
      "id": 5,
      "user_id": 10,
      "user_name": "Jane Agent",
      "user_email": "jane@example.com",
      "created_at": "2025-01-15T00:00:00Z"
    }
  ],
  "conversations_count": 45
}
```

### POST /accounts/:account_id/teams

Create a new team.

**Request:**
```json
{
  "team": {
    "name": "Sales Team",
    "description": "Sales and pre-sales support",
    "allow_auto_assign": true
  }
}
```

**Response:** `201 Created`

### POST /accounts/:account_id/teams/:id/add_member

Add member to team.

**Request:**
```json
{
  "user_id": 15
}
```

**Response:** `200 OK`
```json
{
  "message": "Member added successfully",
  "member": { /* team member object */ }
}
```

### DELETE /accounts/:account_id/teams/:id/remove_member

Remove member from team.

**Request:**
```json
{
  "user_id": 15
}
```

**Response:** `200 OK`
```json
{
  "message": "Member removed successfully"
}
```

---

## Agent Shifts

Schedule and manage agent working hours.

### GET /accounts/:account_id/shifts

List all shifts.

**Query Parameters:**
- `user_id` - Filter by specific agent
- `day_of_week` - Filter by day (0=Sunday, 6=Saturday)

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 10,
      "user_id": 5,
      "user_name": "John Doe",
      "shift_start": "09:00:00",
      "shift_end": "17:00:00",
      "day_of_week": 1,
      "day_name": "Monday",
      "timezone": "America/New_York",
      "created_at": "2025-01-10T00:00:00Z",
      "updated_at": "2025-01-10T00:00:00Z"
    }
  ]
}
```

### POST /accounts/:account_id/shifts

Create agent shift.

**Request:**
```json
{
  "shift": {
    "user_id": 5,
    "shift_start": "09:00",
    "shift_end": "17:00",
    "day_of_week": 1,
    "timezone": "America/New_York"
  }
}
```

**Response:** `201 Created`

### GET /accounts/:account_id/shifts/current

Get currently active shifts.

**Query Parameters:**
- `timezone` - Timezone for calculation (default: UTC)

**Response:** `200 OK`
```json
{
  "current_time": "2025-11-12T14:30:00-05:00",
  "day_of_week": 2,
  "active_shifts": [ /* list of active shifts */ ],
  "agents_on_duty": [
    { "id": 5, "name": "John Doe" },
    { "id": 8, "name": "Jane Agent" }
  ]
}
```

### GET /accounts/:account_id/shifts/weekly/:user_id

Get weekly schedule for an agent.

**Response:** `200 OK`
```json
{
  "user_id": 5,
  "user_name": "John Doe",
  "weekly_schedule": [
    {
      "day": "Monday",
      "day_number": 1,
      "shifts": [
        {
          "id": 10,
          "shift_start": "09:00:00",
          "shift_end": "17:00:00",
          "timezone": "America/New_York"
        }
      ]
    },
    { "day": "Tuesday", "day_number": 2, "shifts": [...] }
  ]
}
```

---

## SLA Policies

Manage Service Level Agreement policies.

### GET /accounts/:account_id/sla_policies

List all SLA policies.

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 1,
      "name": "Standard SLA",
      "description": "Standard response time for all channels",
      "first_response_time_threshold": 300,
      "next_response_time_threshold": 600,
      "resolution_time_threshold": 86400,
      "only_during_business_hours": false,
      "created_at": "2025-01-10T00:00:00Z",
      "updated_at": "2025-01-10T00:00:00Z"
    }
  ]
}
```

### GET /accounts/:account_id/sla_policies/:id

Get SLA policy with compliance stats.

**Response:** `200 OK`
```json
{
  "sla_policy": { /* SLA policy object */ },
  "stats": {
    "applied_count": 1000,
    "sla_met_count": 920,
    "compliance_rate": 92.0
  }
}
```

### POST /accounts/:account_id/sla_policies

Create SLA policy.

**Request:**
```json
{
  "sla_policy": {
    "name": "Premium SLA",
    "description": "Faster response for premium customers",
    "first_response_time_threshold": 120,
    "next_response_time_threshold": 300,
    "resolution_time_threshold": 43200,
    "only_during_business_hours": false
  }
}
```

**Response:** `201 Created`

### GET /accounts/:account_id/sla_policies/compliance_report

Get SLA compliance report.

**Query Parameters:**
- `start_date` - Start date
- `end_date` - End date

**Response:** `200 OK`
```json
{
  "period": {
    "start_date": "2025-10-13",
    "end_date": "2025-11-12"
  },
  "overall": {
    "total": 500,
    "hit": 450,
    "missed": 50,
    "compliance_rate": 90.0
  },
  "by_policy": [
    {
      "policy_id": 1,
      "policy_name": "Standard SLA",
      "total": 300,
      "hit": 270,
      "missed": 30,
      "compliance_rate": 90.0
    }
  ],
  "by_inbox": [
    {
      "inbox_id": 1,
      "inbox_name": "WhatsApp: +1234567890",
      "channel_type": "Channel::Whatsapp",
      "total": 200,
      "hit": 185,
      "missed": 15,
      "compliance_rate": 92.5
    }
  ]
}
```

### GET /accounts/:account_id/platform_sla_configs

Platform-specific SLA configurations.

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": 1,
      "channel_type": "Channel::Whatsapp",
      "channel_name": "WhatsApp",
      "first_response_minutes": 5,
      "resolution_hours": 24,
      "enabled": true,
      "additional_config": {},
      "created_at": "2025-01-10T00:00:00Z",
      "updated_at": "2025-11-10T00:00:00Z"
    }
  ]
}
```

---

## Reports & Analytics

### GET /accounts/:account_id/reports/overview

Get overall account performance.

**Query Parameters:**
- `start_date` - Start date (default: 30 days ago)
- `end_date` - End date (default: today)

**Response:** `200 OK`
```json
{
  "period": {
    "start_date": "2025-10-13",
    "end_date": "2025-11-12"
  },
  "conversations": {
    "total": 500,
    "resolved": 450,
    "open": 40,
    "pending": 10,
    "resolution_rate": 90.0
  },
  "response_time": {
    "avg_first_response_seconds": 180,
    "avg_first_response_minutes": 3.0
  },
  "messages": {
    "incoming": 2500,
    "outgoing": 3000,
    "total": 5500
  },
  "sla": {
    "total": 500,
    "met": 450,
    "missed": 50,
    "compliance_rate": 90.0
  }
}
```

### GET /accounts/:account_id/reports/agent_performance

Agent performance comparison.

**Query Parameters:**
- `start_date`, `end_date`

**Response:** `200 OK`
```json
{
  "period": { /* date range */ },
  "agents": [
    {
      "agent_id": 2,
      "user_id": 5,
      "name": "John Doe",
      "email": "john@example.com",
      "conversations_handled": 145,
      "conversations_resolved": 130,
      "resolution_rate": 89.66,
      "avg_first_response_minutes": 3.0,
      "sla_compliance_rate": 92.5,
      "sla_met": 134,
      "sla_total": 145
    }
  ]
}
```

### GET /accounts/:account_id/reports/channel_performance

Channel/inbox performance.

**Response:** `200 OK`
```json
{
  "period": { /* date range */ },
  "channels": [
    {
      "inbox_id": 1,
      "inbox_name": "WhatsApp: +1234567890",
      "channel_type": "Channel::Whatsapp",
      "conversations": 200,
      "resolved": 180,
      "resolution_rate": 90.0,
      "messages_received": 1000,
      "messages_sent": 1200,
      "avg_first_response_minutes": 2.5
    }
  ]
}
```

### GET /accounts/:account_id/reports/conversation_trends

Daily conversation trends.

**Response:** `200 OK`
```json
{
  "period": { /* date range */ },
  "daily_trends": [
    {
      "date": "2025-11-12",
      "total": 50,
      "resolved": 45,
      "open": 3,
      "pending": 2
    }
  ]
}
```

---

## Error Handling

### Error Response Format

All errors follow this format:

```json
{
  "error": "Error Type",
  "message": "Detailed error message"
}
```

### HTTP Status Codes

- `200 OK` - Success
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Authentication required or failed
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

### Common Error Responses

**401 Unauthorized:**
```json
{
  "error": "Unauthorized",
  "message": "Missing token"
}
```

**401 Token Expired:**
```json
{
  "error": "Token Expired",
  "message": "Your session has expired. Please login again."
}
```

**403 Forbidden:**
```json
{
  "error": "Forbidden",
  "message": "You are not authorized to perform this action"
}
```

**404 Not Found:**
```json
{
  "error": "Not Found",
  "message": "Account not found or access denied"
}
```

**422 Validation Error:**
```json
{
  "error": "Validation failed",
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 6 characters)"
  ]
}
```

---

## Rate Limiting

**Coming Soon:** Rate limiting will be implemented to prevent API abuse.

**Planned Limits:**
- 1000 requests per hour per account
- 100 requests per minute per user

---

## Webhooks

External platforms (WhatsApp, Facebook, Instagram) send webhooks to:

- `POST /webhooks/:phone_number` - WhatsApp events
- `POST /webhooks/facebook` - Facebook events
- `POST /webhooks/instagram` - Instagram events

These are handled automatically by the system. You don't need to call these endpoints.

---

## Postman Collection

Import this into Postman for easy testing:

[Download Postman Collection](./CRM_API.postman_collection.json) *(To be created)*

---

## Support

For questions or issues:
- Check the [JWT Authentication Guide](./JWT_AUTHENTICATION.md)
- Review [Database Schema](./DATABASE_SCHEMA.md)
- See [Social Media Integrations](./SOCIAL_MEDIA_INTEGRATIONS.md)

---

**Last Updated:** 2025-11-12
**API Version:** 1.0
**Total Endpoints:** 100+
