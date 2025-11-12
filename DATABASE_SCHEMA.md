# CRM Database Schema Documentation

Complete database schema for the social media CRM with WhatsApp, Facebook, and Instagram integrations.

## 📊 Overview

**Total Tables:** 19
**Migration Files:** 19
**Relationships:** Fully normalized with foreign keys

---

## 🏗️ Core Tables

### 1. **accounts**
Multi-tenancy foundation - each organization gets its own account.

```sql
- id (primary key)
- name (string, required)
- locale (integer, default: 0)
- domain (string, 100 chars)
- support_email (string, 100 chars)
- feature_flags (bigint, default: 0)
- auto_resolve_duration (integer)
- limits (jsonb)
- custom_attributes (jsonb)
- status (integer, default: 0)
- settings (jsonb)
- timestamps
```

**Indexes:**
- `status`

**Use Cases:**
- Multi-tenant isolation
- Feature toggles per account
- Per-account configuration
- Usage limits

---

### 2. **users**
Authentication and user management (Devise-compatible).

```sql
- id (primary key)
- email (string, unique, required)
- encrypted_password (string, required)
- reset_password_token (string, unique)
- reset_password_sent_at (datetime)
- remember_created_at (datetime)
- sign_in_count (integer, default: 0)
- current_sign_in_at (datetime)
- last_sign_in_at (datetime)
- current_sign_in_ip (string)
- last_sign_in_ip (string)
- confirmation_token (string, unique)
- confirmed_at (datetime)
- confirmation_sent_at (datetime)
- unconfirmed_email (string)
- tokens (text) - for JWT/API tokens
- provider (string, default: 'email')
- uid (string, default: '')
- name (string, required)
- display_name (string)
- avatar_url (string)
- type (integer, default: 0)
- custom_attributes (jsonb)
- ui_settings (jsonb)
- timestamps
```

**Indexes:**
- `email` (unique)
- `reset_password_token` (unique)
- `confirmation_token` (unique)
- `[uid, provider]` (unique)

**Features:**
- ✅ Devise authentication
- ✅ JWT token support
- ✅ OAuth provider support
- ✅ User preferences storage

---

### 3. **account_users**
Many-to-many relationship between accounts and users (roles & permissions).

```sql
- id (primary key)
- account_id (foreign key → accounts)
- user_id (foreign key → users)
- role (integer, default: 0) # 0: agent, 1: admin, 2: owner
- inviter_id (bigint)
- active_at (datetime)
- availability (integer, default: 0) # 0: offline, 1: online, 2: busy
- auto_offline (boolean, default: true)
- timestamps
```

**Indexes:**
- `[account_id, user_id]` (unique)
- `user_id`

**Roles:**
- 0: Agent (can handle conversations)
- 1: Admin (can manage settings)
- 2: Owner (full access)

---

## 👥 Contact Management

### 4. **contacts**
Customer/contact profiles.

```sql
- id (primary key)
- account_id (foreign key → accounts)
- name (string)
- email (string)
- phone_number (string)
- identifier (string) - custom ID
- additional_attributes (jsonb)
- custom_attributes (jsonb)
- last_activity_at (datetime)
- contact_type (string)
- blocked (integer, default: 0)
- timestamps
```

**Indexes:**
- `account_id`
- `email`
- `phone_number`
- `[account_id, email]` (where email NOT NULL)
- `[account_id, phone_number]` (where phone_number NOT NULL)

---

### 5. **contact_inboxes**
Links contacts to specific channels/inboxes with platform-specific IDs.

```sql
- id (primary key)
- contact_id (foreign key → contacts)
- inbox_id (foreign key → inboxes)
- source_id (string, required) # Platform-specific user ID
- hmac_verified (jsonb)
- pubsub_token (string, unique)
- timestamps
```

**Indexes:**
- `[inbox_id, source_id]` (unique)
- `source_id`
- `pubsub_token` (unique)

**Source ID Examples:**
- WhatsApp: `+1234567890`
- Facebook: `1234567890123456`
- Instagram: `instagram_user_id_123`

---

## 📬 Inbox & Channel Management

### 6. **inboxes**
Polymorphic container for all communication channels.

```sql
- id (primary key)
- account_id (foreign key → accounts)
- name (string, required)
- channel_type (string) # 'Channel::Whatsapp', 'Channel::FacebookPage', etc.
- channel_id (bigint, required)
- email_address (string)
- enable_auto_assignment (boolean, default: true)
- greeting_message (string)
- greeting_enabled (boolean, default: false)
- out_of_office_message (string)
- timezone (string, default: 'UTC')
- working_hours_enabled (boolean, default: false)
- enable_email_collect (boolean, default: true)
- csat_survey_enabled (boolean, default: false)
- csat_config (jsonb)
- allow_messages_after_resolved (boolean, default: true)
- auto_assignment_config (jsonb)
- lock_to_single_conversation (boolean, default: false)
- sender_name_type (integer, default: 0)
- business_name (string)
- timestamps
```

**Indexes:**
- `account_id`
- `[channel_id, channel_type]`

**Polymorphic Relationship:**
```ruby
belongs_to :channel, polymorphic: true
# channel_type: 'Channel::Whatsapp'
# channel_id: 123 (points to channel_whatsapp.id)
```

---

### 7. **channel_whatsapp**
WhatsApp-specific channel configuration.

```sql
- id (primary key)
- account_id (integer, required)
- phone_number (string, unique, required)
- provider (string, default: 'default') # 'whatsapp_cloud' or 'default' (360dialog)
- provider_config (jsonb) # API keys, webhook tokens, etc.
- message_templates (jsonb) # Cached WhatsApp templates
- message_templates_last_updated (datetime)
- timestamps
```

**Indexes:**
- `phone_number` (unique)
- `account_id`

**Provider Config Structure:**
```json
{
  "api_key": "your_api_key",
  "business_account_id": "123456789",
  "webhook_verify_token": "secure_token"
}
```

---

### 8. **channel_facebook_pages**
Facebook Page channel configuration.

```sql
- id (primary key)
- account_id (integer, required)
- page_id (string, required)
- page_access_token (string, required) # Encrypted in production
- user_access_token (string, required) # Encrypted in production
- instagram_id (string) # For cross-platform support
- timestamps
```

**Indexes:**
- `page_id`
- `[page_id, account_id]` (unique)

**Note:** Tokens should be encrypted using Rails encrypted attributes.

---

### 9. **channel_instagram**
Instagram Direct Messages channel configuration.

```sql
- id (primary key)
- account_id (integer, required)
- instagram_id (string, unique, required)
- access_token (string, required) # Encrypted
- expires_at (datetime, required) # Token expiration
- timestamps
```

**Indexes:**
- `instagram_id` (unique)
- `account_id`

**Token Refresh:**
Instagram tokens expire every 60 days and need refresh via `Instagram::RefreshOauthTokenService`.

---

### 10. **inbox_members**
Assigns agents to specific inboxes.

```sql
- id (primary key)
- inbox_id (foreign key → inboxes)
- user_id (foreign key → users)
- timestamps
```

**Indexes:**
- `[inbox_id, user_id]` (unique)

---

## 💬 Conversation & Message Management

### 11. **conversations**
Message threads/tickets.

```sql
- id (primary key)
- account_id (foreign key → accounts)
- inbox_id (foreign key → inboxes)
- contact_id (foreign key → contacts)
- assignee_id (foreign key → users)
- team_id (foreign key → teams)
- status (integer, default: 0) # 0: open, 1: resolved, 2: pending, 3: snoozed
- display_id (integer, required) # Human-readable ID per account
- uuid (uuid, unique, required)
- identifier (string)
- last_activity_at (datetime, required)
- agent_last_seen_at (datetime)
- assignee_last_seen_at (datetime)
- contact_last_seen_at (datetime)
- first_reply_created_at (datetime) # For SLA tracking
- priority (integer) # 0: low, 1: medium, 2: high, 3: urgent
- snoozed_until (datetime)
- waiting_since (datetime) # Customer waiting for response
- additional_attributes (jsonb)
- custom_attributes (jsonb)
- timestamps
```

**Indexes:**
- `uuid` (unique)
- `[account_id, display_id]` (unique)
- `[account_id, inbox_id, status, assignee_id]`
- `[assignee_id, account_id]`
- `[status, account_id]`
- `first_reply_created_at`
- `waiting_since`
- `priority`

**Status Values:**
- 0: Open (active conversation)
- 1: Resolved (closed)
- 2: Pending (waiting for customer)
- 3: Snoozed (temporarily hidden)

---

### 12. **messages**
Individual messages within conversations.

```sql
- id (primary key)
- account_id (foreign key → accounts)
- inbox_id (foreign key → inboxes)
- conversation_id (foreign key → conversations)
- content (text)
- content_type (integer, default: 0) # 0: text, 1: input_text, etc.
- message_type (integer, required) # 0: incoming, 1: outgoing, 2: activity, 3: template
- status (integer, default: 0) # 0: sent, 1: delivered, 2: read, 3: failed
- private (boolean, default: false) # Internal note
- sender_type (string) # 'User', 'Contact', 'AgentBot'
- sender_id (bigint)
- source_id (string) # Platform message ID
- content_attributes (jsonb) # Rich message data
- additional_attributes (jsonb)
- external_source_ids (jsonb)
- sentiment (jsonb) # AI sentiment analysis
- processed_message_content (text)
- timestamps
```

**Indexes:**
- `[sender_type, sender_id]`
- `source_id`
- `[account_id, inbox_id]`
- `[conversation_id, account_id, message_type, created_at]`
- `[account_id, created_at, message_type]`
- `[account_id, content_type, created_at]`

**Message Types:**
- 0: Incoming (from customer)
- 1: Outgoing (from agent)
- 2: Activity (system message)
- 3: Template (WhatsApp template)

---

## 👥 Team Management

### 13. **teams**
Agent teams for organizing support staff.

```sql
- id (primary key)
- account_id (foreign key → accounts)
- name (string, required)
- description (text)
- allow_auto_assign (boolean, default: true)
- timestamps
```

**Indexes:**
- `account_id`

---

## 📈 SLA Management

### 14. **sla_policies**
Service Level Agreement definitions.

```sql
- id (primary key)
- account_id (foreign key → accounts)
- name (string, required)
- description (string)
- first_response_time_threshold (float) # In minutes
- next_response_time_threshold (float) # In minutes
- resolution_time_threshold (float) # In minutes
- only_during_business_hours (boolean, default: false)
- timestamps
```

**Indexes:**
- `account_id`

**Example:**
- First response: 15 minutes
- Resolution: 240 minutes (4 hours)

---

### 15. **applied_slas**
Tracks SLA status for each conversation.

```sql
- id (primary key)
- account_id (foreign key → accounts)
- sla_policy_id (foreign key → sla_policies)
- conversation_id (foreign key → conversations)
- sla_status (integer, default: 0) # 0: active, 1: hit, 2: missed
- timestamps
```

**Indexes:**
- `sla_policy_id`
- `conversation_id`
- `[account_id, sla_policy_id, conversation_id]` (unique)

**Status Values:**
- 0: Active (in progress)
- 1: Hit (SLA met)
- 2: Missed (SLA violated)

---

### 16. **platform_sla_configs**
Platform-specific SLA settings (custom feature).

```sql
- id (primary key)
- account_id (foreign key → accounts)
- channel_type (string, required) # 'Channel::Whatsapp', etc.
- first_response_minutes (integer, default: 30)
- resolution_hours (integer, default: 24)
- enabled (boolean, default: true)
- additional_config (jsonb)
- timestamps
```

**Indexes:**
- `[account_id, channel_type]` (unique)
- `channel_type`
- `enabled`

**Use Case:**
Different SLAs for different platforms:
- WhatsApp: 5 min first response
- Facebook: 15 min first response
- Instagram: 30 min first response

---

## 👤 Agent Management (Custom Features)

### 17. **agent_shifts**
Agent work schedule management.

```sql
- id (primary key)
- user_id (foreign key → users)
- account_id (foreign key → accounts)
- shift_start (time, required) # e.g., '09:00:00'
- shift_end (time, required) # e.g., '17:00:00'
- day_of_week (integer, required) # 0-6 (Sunday-Saturday)
- timezone (string, default: 'UTC')
- active (boolean, default: true)
- timestamps
```

**Indexes:**
- `[user_id, account_id]`
- `[account_id, day_of_week]`
- `active`

**Example:**
```ruby
AgentShift.create!(
  user: agent,
  account: account,
  shift_start: '09:00',
  shift_end: '17:00',
  day_of_week: 1, # Monday
  timezone: 'America/New_York'
)
```

---

### 18. **agent_availability_logs**
Track agent online/offline/busy status changes.

```sql
- id (primary key)
- user_id (foreign key → users)
- account_id (foreign key → accounts)
- status (integer, required) # 0: offline, 1: online, 2: busy
- changed_at (datetime, required)
- reason (string)
- ip_address (string)
- metadata (jsonb)
- timestamps
```

**Indexes:**
- `[user_id, changed_at]`
- `[account_id, changed_at]`
- `status`

**Use Cases:**
- Track agent productivity
- Calculate online time
- Audit trail

---

### 19. **agent_metrics**
Daily performance metrics per agent.

```sql
- id (primary key)
- user_id (foreign key → users)
- account_id (foreign key → accounts)
- metric_date (date, required)
- avg_first_response_time (float) # seconds
- avg_response_time (float) # seconds
- avg_resolution_time (float) # seconds
- conversations_handled (integer, default: 0)
- messages_sent (integer, default: 0)
- conversations_resolved (integer, default: 0)
- sla_met_count (integer, default: 0)
- sla_missed_count (integer, default: 0)
- online_duration (integer, default: 0) # seconds
- busy_duration (integer, default: 0) # seconds
- offline_duration (integer, default: 0) # seconds
- timestamps
```

**Indexes:**
- `[user_id, metric_date]` (unique)
- `[account_id, metric_date]`
- `metric_date`

**Use Cases:**
- Agent performance dashboards
- Response time tracking
- SLA compliance reporting
- Productivity analytics

---

## 🔗 Relationships Diagram

```
Account
├── Users (via account_users)
├── Contacts
├── Inboxes
│   ├── WhatsApp Channels
│   ├── Facebook Channels
│   └── Instagram Channels
├── Conversations
│   ├── Messages
│   └── Applied SLAs
├── Teams
├── SLA Policies
├── Platform SLA Configs
├── Agent Shifts
├── Agent Availability Logs
└── Agent Metrics

Contact
├── Contact Inboxes (links to specific channels)
└── Conversations

Inbox
├── Inbox Members (assigned agents)
├── Conversations
└── Messages

Conversation
├── Messages
├── Contact
├── Assigned Agent (User)
├── Team
└── Applied SLAs
```

---

## 🚀 Migration Commands

### Running Migrations

```bash
# Create database
bin/rails db:create

# Run all migrations
bin/rails db:migrate

# Check status
bin/rails db:migrate:status

# Rollback last migration
bin/rails db:rollback

# Reset database (dangerous!)
bin/rails db:reset
```

### Seeding Data

```bash
# Run seeds
bin/rails db:seed

# Reset and seed
bin/rails db:reset
```

---

## 📊 Key Performance Indexes

High-traffic queries are optimized with these indexes:

1. **Message Lookup:**
   - `[conversation_id, account_id, message_type, created_at]`
   - `[account_id, inbox_id]`

2. **Conversation Queries:**
   - `[account_id, inbox_id, status, assignee_id]`
   - `[status, account_id]`

3. **Contact Search:**
   - `[account_id, email]` (where email NOT NULL)
   - `[account_id, phone_number]` (where phone NOT NULL)

4. **Agent Performance:**
   - `[user_id, metric_date]`
   - `[account_id, changed_at]` (availability logs)

---

## 🔒 Data Integrity

**Foreign Keys Enforced:**
- All relationships use proper foreign keys
- Cascade deletes configured where appropriate
- Orphan prevention through database constraints

**JSONB Columns:**
Used for flexible data storage:
- `custom_attributes` - User-defined fields
- `additional_attributes` - Platform-specific data
- `provider_config` - Channel configuration
- `settings` - Account preferences

---

## 📝 Notes

1. **UUIDs:** Conversations use UUIDs for external references
2. **Display IDs:** Human-readable IDs per account (e.g., #1, #2, #3)
3. **Soft Deletes:** Not implemented - use status flags instead
4. **Time Zones:** All timestamps stored in UTC, converted at display time
5. **JSONB:** PostgreSQL JSONB provides indexing and querying capabilities

---

## ✅ Ready to Use

All migrations are ready to run. Simply execute:

```bash
bin/rails db:create db:migrate
```

Total tables: **19**
Total indexes: **60+**
Total foreign keys: **20**

