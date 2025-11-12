# Database Seed Script
# Run with: rails db:seed

puts "🌱 Starting database seed..."
puts "=" * 60

# Clear existing data (optional - comment out in production)
puts "\n🧹 Cleaning existing data..."
AppliedSla.delete_all
Message.delete_all
Conversation.delete_all
ContactInbox.delete_all
Contact.delete_all
InboxMember.delete_all
Inbox.delete_all
Channel::Whatsapp.delete_all
Channel::FacebookPage.delete_all
Channel::Instagram.delete_all
TeamMember.delete_all
Team.delete_all
AgentShift.delete_all
AgentAvailabilityLog.delete_all
AgentMetric.delete_all
SlaPolicy.delete_all
PlatformSlaConfig.delete_all
AccountUser.delete_all
User.delete_all
Account.delete_all

puts "✅ Cleanup complete"

# ===========================================================================
# 1. Create Accounts
# ===========================================================================
puts "\n📊 Creating accounts..."

account1 = Account.create!(
  name: "Acme Corporation",
  settings: {
    business_hours: {
      monday: { enabled: true, open: "09:00", close: "17:00" },
      tuesday: { enabled: true, open: "09:00", close: "17:00" },
      wednesday: { enabled: true, open: "09:00", close: "17:00" },
      thursday: { enabled: true, open: "09:00", close: "17:00" },
      friday: { enabled: true, open: "09:00", close: "17:00" }
    },
    timezone: "America/New_York"
  },
  limits: {
    agents: 50,
    inboxes: 10
  },
  status: 0
)

account2 = Account.create!(
  name: "Tech Startup Inc",
  settings: {
    timezone: "America/Los_Angeles"
  },
  limits: {
    agents: 25,
    inboxes: 5
  },
  status: 0
)

puts "✅ Created #{Account.count} accounts"

# ===========================================================================
# 2. Create Users
# ===========================================================================
puts "\n👥 Creating users..."

# Account 1 Users
admin1 = User.create!(
  name: "Alice Admin",
  email: "admin@acme.com",
  password: "password123",
  password_confirmation: "password123",
  display_name: "Alice"
)

supervisor1 = User.create!(
  name: "Bob Supervisor",
  email: "supervisor@acme.com",
  password: "password123",
  password_confirmation: "password123",
  display_name: "Bob"
)

agent1 = User.create!(
  name: "Charlie Agent",
  email: "charlie@acme.com",
  password: "password123",
  password_confirmation: "password123",
  display_name: "Charlie"
)

agent2 = User.create!(
  name: "Diana Agent",
  email: "diana@acme.com",
  password: "password123",
  password_confirmation: "password123",
  display_name: "Diana"
)

agent3 = User.create!(
  name: "Eve Agent",
  email: "eve@acme.com",
  password: "password123",
  password_confirmation: "password123",
  display_name: "Eve"
)

# Account 2 Users
admin2 = User.create!(
  name: "Frank Admin",
  email: "admin@techstartup.com",
  password: "password123",
  password_confirmation: "password123",
  display_name: "Frank"
)

agent4 = User.create!(
  name: "Grace Agent",
  email: "grace@techstartup.com",
  password: "password123",
  password_confirmation: "password123",
  display_name: "Grace"
)

puts "✅ Created #{User.count} users"

# ===========================================================================
# 3. Create AccountUsers (Assign users to accounts)
# ===========================================================================
puts "\n🔗 Assigning users to accounts..."

# Account 1
AccountUser.create!(account: account1, user: admin1, role: :administrator, availability: :online)
AccountUser.create!(account: account1, user: supervisor1, role: :supervisor, availability: :online)
AccountUser.create!(account: account1, user: agent1, role: :agent, availability: :online)
AccountUser.create!(account: account1, user: agent2, role: :agent, availability: :busy)
AccountUser.create!(account: account1, user: agent3, role: :agent, availability: :offline)

# Account 2
AccountUser.create!(account: account2, user: admin2, role: :administrator, availability: :online)
AccountUser.create!(account: account2, user: agent4, role: :agent, availability: :online)

puts "✅ Created #{AccountUser.count} account user assignments"

# ===========================================================================
# 4. Create Teams
# ===========================================================================
puts "\n👨‍👩‍👧‍👦 Creating teams..."

support_team = Team.create!(
  account: account1,
  name: "Support Team",
  description: "Customer support and technical assistance",
  allow_auto_assign: true
)

sales_team = Team.create!(
  account: account1,
  name: "Sales Team",
  description: "Pre-sales and sales inquiries",
  allow_auto_assign: true
)

# Add team members
TeamMember.create!(team: support_team, user: agent1)
TeamMember.create!(team: support_team, user: agent2)
TeamMember.create!(team: sales_team, user: agent3)

puts "✅ Created #{Team.count} teams with #{TeamMember.count} members"

# ===========================================================================
# 5. Create Channels & Inboxes
# ===========================================================================
puts "\n📱 Creating channels and inboxes..."

# WhatsApp Channel
whatsapp_channel = Channel::Whatsapp.create!(
  phone_number: "+15551234567",
  provider: "whatsapp_cloud",
  provider_config: {
    api_key: "demo_api_key",
    phone_number_id: "123456789"
  }
)

whatsapp_inbox = Inbox.create!(
  account: account1,
  channel: whatsapp_channel,
  name: "WhatsApp: +15551234567",
  greeting_enabled: true,
  greeting_message: "Hi! Thanks for contacting Acme Corporation. How can we help you today?",
  enable_auto_assignment: true,
  working_hours_enabled: true,
  timezone: "America/New_York"
)

# Facebook Channel
facebook_channel = Channel::FacebookPage.create!(
  page_id: "fb_page_123",
  name: "Acme Corporation",
  page_access_token: "encrypted_token_placeholder"
)

facebook_inbox = Inbox.create!(
  account: account1,
  channel: facebook_channel,
  name: "Facebook: Acme Corporation",
  greeting_enabled: true,
  greeting_message: "Hello! Welcome to Acme Corporation on Facebook.",
  enable_auto_assignment: true
)

# Instagram Channel
instagram_channel = Channel::Instagram.create!(
  instagram_id: "ig_account_456",
  username: "acmecorp",
  access_token: "encrypted_token_placeholder",
  token_expires_at: 60.days.from_now
)

instagram_inbox = Inbox.create!(
  account: account1,
  channel: instagram_channel,
  name: "Instagram: @acmecorp",
  greeting_enabled: true,
  greeting_message: "Hi! Thanks for reaching out on Instagram! 👋",
  enable_auto_assignment: true
)

# Add inbox members
InboxMember.create!(inbox: whatsapp_inbox, user: agent1)
InboxMember.create!(inbox: whatsapp_inbox, user: agent2)
InboxMember.create!(inbox: facebook_inbox, user: agent1)
InboxMember.create!(inbox: instagram_inbox, user: agent3)

puts "✅ Created #{Inbox.count} inboxes (WhatsApp, Facebook, Instagram)"

# ===========================================================================
# 6. Create Contacts
# ===========================================================================
puts "\n👤 Creating contacts..."

contacts = []

contacts << Contact.create!(
  account: account1,
  name: "John Customer",
  email: "john@customer.com",
  phone_number: "+15559876543",
  identifier: "CUST001",
  custom_attributes: {
    customer_tier: "premium",
    signup_date: "2024-01-15",
    ltv: 5000
  }
)

contacts << Contact.create!(
  account: account1,
  name: "Sarah Johnson",
  email: "sarah@example.com",
  phone_number: "+15558765432",
  identifier: "CUST002",
  custom_attributes: {
    customer_tier: "standard",
    signup_date: "2024-03-20"
  }
)

contacts << Contact.create!(
  account: account1,
  name: "Mike Brown",
  email: "mike@example.com",
  phone_number: "+15557654321",
  identifier: "CUST003",
  custom_attributes: {
    customer_tier: "premium",
    signup_date: "2023-11-10",
    ltv: 12000
  }
)

contacts << Contact.create!(
  account: account1,
  name: "Lisa Anderson",
  phone_number: "+15556543210",
  identifier: "CUST004"
)

contacts << Contact.create!(
  account: account1,
  name: "David Wilson",
  email: "david@example.com",
  phone_number: "+15555432109",
  identifier: "CUST005"
)

puts "✅ Created #{Contact.count} contacts"

# ===========================================================================
# 7. Create Contact Inboxes
# ===========================================================================
puts "\n📞 Linking contacts to inboxes..."

ContactInbox.create!(
  contact: contacts[0],
  inbox: whatsapp_inbox,
  source_id: "whatsapp_#{contacts[0].phone_number}"
)

ContactInbox.create!(
  contact: contacts[1],
  inbox: facebook_inbox,
  source_id: "fb_#{contacts[1].id}"
)

ContactInbox.create!(
  contact: contacts[2],
  inbox: instagram_inbox,
  source_id: "ig_#{contacts[2].id}"
)

ContactInbox.create!(
  contact: contacts[3],
  inbox: whatsapp_inbox,
  source_id: "whatsapp_#{contacts[3].phone_number}"
)

ContactInbox.create!(
  contact: contacts[4],
  inbox: facebook_inbox,
  source_id: "fb_#{contacts[4].id}"
)

puts "✅ Created #{ContactInbox.count} contact-inbox links"

# ===========================================================================
# 8. Create SLA Policies
# ===========================================================================
puts "\n⏱️  Creating SLA policies..."

standard_sla = SlaPolicy.create!(
  account: account1,
  name: "Standard SLA",
  description: "Standard response time for regular customers",
  first_response_time_threshold: 300,      # 5 minutes
  next_response_time_threshold: 600,       # 10 minutes
  resolution_time_threshold: 86400,        # 24 hours
  only_during_business_hours: false
)

premium_sla = SlaPolicy.create!(
  account: account1,
  name: "Premium SLA",
  description: "Faster response for premium customers",
  first_response_time_threshold: 120,      # 2 minutes
  next_response_time_threshold: 300,       # 5 minutes
  resolution_time_threshold: 43200,        # 12 hours
  only_during_business_hours: false
)

puts "✅ Created #{SlaPolicy.count} SLA policies"

# ===========================================================================
# 9. Create Platform SLA Configs
# ===========================================================================
puts "\n⚙️  Creating platform SLA configs..."

PlatformSlaConfig.create!(
  account: account1,
  channel_type: "Channel::Whatsapp",
  first_response_minutes: 5,
  resolution_hours: 24,
  enabled: true
)

PlatformSlaConfig.create!(
  account: account1,
  channel_type: "Channel::FacebookPage",
  first_response_minutes: 10,
  resolution_hours: 48,
  enabled: true
)

PlatformSlaConfig.create!(
  account: account1,
  channel_type: "Channel::Instagram",
  first_response_minutes: 15,
  resolution_hours: 48,
  enabled: true
)

puts "✅ Created #{PlatformSlaConfig.count} platform SLA configs"

# ===========================================================================
# 10. Create Conversations & Messages
# ===========================================================================
puts "\n💬 Creating conversations and messages..."

conversation_data = [
  {
    inbox: whatsapp_inbox,
    contact: contacts[0],
    assignee: agent1,
    team: support_team,
    status: :open,
    priority: :high,
    messages: [
      { type: :incoming, content: "Hi, I need help with my recent order #12345", sender: contacts[0] },
      { type: :outgoing, content: "Hello! I'd be happy to help you with order #12345. Can you tell me what the issue is?", sender: agent1 },
      { type: :incoming, content: "I haven't received it yet, it's been 5 days", sender: contacts[0] }
    ]
  },
  {
    inbox: facebook_inbox,
    contact: contacts[1],
    assignee: agent1,
    team: support_team,
    status: :resolved,
    priority: :medium,
    messages: [
      { type: :incoming, content: "What are your business hours?", sender: contacts[1] },
      { type: :outgoing, content: "We're open Monday-Friday, 9 AM - 5 PM EST. How can we help you?", sender: agent1 },
      { type: :incoming, content: "Perfect, thank you!", sender: contacts[1] }
    ]
  },
  {
    inbox: instagram_inbox,
    contact: contacts[2],
    assignee: agent3,
    team: sales_team,
    status: :open,
    priority: :urgent,
    messages: [
      { type: :incoming, content: "Do you offer bulk discounts?", sender: contacts[2] },
      { type: :outgoing, content: "Yes! We offer discounts for orders over 100 units. How many are you looking to order?", sender: agent3 }
    ]
  },
  {
    inbox: whatsapp_inbox,
    contact: contacts[3],
    assignee: agent2,
    team: support_team,
    status: :pending,
    priority: :low,
    messages: [
      { type: :incoming, content: "Can I cancel my subscription?", sender: contacts[3] },
      { type: :outgoing, content: "I can help you with that. May I have your account email?", sender: agent2 },
      { type: :incoming, content: "It's lisa@example.com", sender: contacts[3] },
      { type: :outgoing, content: "Let me check that for you. One moment please.", sender: agent2 }
    ]
  },
  {
    inbox: facebook_inbox,
    contact: contacts[4],
    assignee: agent1,
    team: support_team,
    status: :resolved,
    priority: :medium,
    messages: [
      { type: :incoming, content: "Great product! Just wanted to say thanks!", sender: contacts[4] },
      { type: :outgoing, content: "Thank you so much for the kind words! We're thrilled you're happy with your purchase! 😊", sender: agent1 }
    ]
  }
]

conversation_data.each_with_index do |data, index|
  conversation = Conversation.create!(
    account: account1,
    inbox: data[:inbox],
    contact: data[:contact],
    assignee: data[:assignee],
    team: data[:team],
    status: data[:status],
    priority: data[:priority],
    custom_attributes: {},
    created_at: (5 - index).days.ago
  )

  data[:messages].each_with_index do |msg_data, msg_index|
    message = Message.create!(
      account: account1,
      inbox: data[:inbox],
      conversation: conversation,
      message_type: msg_data[:type],
      content_type: :text,
      content: msg_data[:content],
      sender: msg_data[:sender],
      created_at: (5 - index).days.ago + (msg_index * 5).minutes
    )

    # Set first reply timestamp
    if msg_data[:type] == :outgoing && conversation.first_reply_created_at.nil?
      conversation.update(first_reply_created_at: message.created_at)
    end
  end

  # Create SLA for this conversation
  sla = contacts.index(data[:contact]) < 2 ? premium_sla : standard_sla
  sla_status = [:hit, :missed].sample

  AppliedSla.create!(
    account: account1,
    sla_policy: sla,
    conversation: conversation,
    sla_status: sla_status
  )
end

puts "✅ Created #{Conversation.count} conversations with #{Message.count} messages"

# ===========================================================================
# 11. Create Agent Shifts
# ===========================================================================
puts "\n📅 Creating agent shifts..."

# Charlie - Monday to Friday, 9-5
(1..5).each do |day|
  AgentShift.create!(
    account: account1,
    user: agent1,
    shift_start: "09:00",
    shift_end: "17:00",
    day_of_week: day,
    timezone: "America/New_York"
  )
end

# Diana - Tuesday to Saturday, 10-6
(2..6).each do |day|
  AgentShift.create!(
    account: account1,
    user: agent2,
    shift_start: "10:00",
    shift_end: "18:00",
    day_of_week: day,
    timezone: "America/New_York"
  )
end

# Eve - Wednesday to Sunday, 12-8 (evening shift)
[3, 4, 5, 6, 0].each do |day|
  AgentShift.create!(
    account: account1,
    user: agent3,
    shift_start: "12:00",
    shift_end: "20:00",
    day_of_week: day,
    timezone: "America/New_York"
  )
end

puts "✅ Created #{AgentShift.count} agent shifts"

# ===========================================================================
# 12. Create Agent Metrics
# ===========================================================================
puts "\n📈 Creating agent metrics..."

# Last 7 days of metrics for agent1
(0..6).each do |days_ago|
  date = days_ago.days.ago.to_date
  AgentMetric.create!(
    account: account1,
    user: agent1,
    metric_date: date,
    conversations_handled: rand(10..20),
    avg_first_response_time: rand(60..300).to_f,
    sla_met_count: rand(8..18),
    online_duration: rand(20000..28800)
  )
end

# Last 7 days of metrics for agent2
(0..6).each do |days_ago|
  date = days_ago.days.ago.to_date
  AgentMetric.create!(
    account: account1,
    user: agent2,
    metric_date: date,
    conversations_handled: rand(8..15),
    avg_first_response_time: rand(80..350).to_f,
    sla_met_count: rand(6..14),
    online_duration: rand(18000..26000)
  )
end

puts "✅ Created #{AgentMetric.count} agent metric records"

# ===========================================================================
# 13. Create Availability Logs
# ===========================================================================
puts "\n⏰ Creating availability logs..."

# Recent availability changes
AgentAvailabilityLog.create!(
  account: account1,
  user: agent1,
  status: :online,
  logged_at: 2.hours.ago
)

AgentAvailabilityLog.create!(
  account: account1,
  user: agent2,
  status: :busy,
  logged_at: 1.hour.ago
)

AgentAvailabilityLog.create!(
  account: account1,
  user: agent3,
  status: :offline,
  logged_at: 30.minutes.ago
)

puts "✅ Created #{AgentAvailabilityLog.count} availability logs"

# ===========================================================================
# Summary
# ===========================================================================
puts "\n" + "=" * 60
puts "🎉 Seed completed successfully!"
puts "=" * 60

puts "\n📊 Summary:"
puts "  • Accounts: #{Account.count}"
puts "  • Users: #{User.count}"
puts "  • Account Users: #{AccountUser.count}"
puts "  • Teams: #{Team.count}"
puts "  • Team Members: #{TeamMember.count}"
puts "  • Inboxes: #{Inbox.count}"
puts "    - WhatsApp: #{Channel::Whatsapp.count}"
puts "    - Facebook: #{Channel::FacebookPage.count}"
puts "    - Instagram: #{Channel::Instagram.count}"
puts "  • Contacts: #{Contact.count}"
puts "  • Conversations: #{Conversation.count}"
puts "  • Messages: #{Message.count}"
puts "  • SLA Policies: #{SlaPolicy.count}"
puts "  • Applied SLAs: #{AppliedSla.count}"
puts "  • Agent Shifts: #{AgentShift.count}"
puts "  • Agent Metrics: #{AgentMetric.count}"

puts "\n🔑 Test Credentials:"
puts "  Admin (Account 1):     admin@acme.com / password123"
puts "  Supervisor:            supervisor@acme.com / password123"
puts "  Agents:                charlie@acme.com / password123"
puts "                         diana@acme.com / password123"
puts "                         eve@acme.com / password123"
puts "  Admin (Account 2):     admin@techstartup.com / password123"

puts "\n🚀 Next Steps:"
puts "  1. Start the server: bin/rails server"
puts "  2. Test authentication: POST /api/v1/auth/login"
puts "  3. Get access token and explore API endpoints"
puts "  4. View unified inbox: GET /api/v1/accounts/1/conversations"

puts "\n" + "=" * 60
puts "✅ Database is ready for testing!"
puts "=" * 60
