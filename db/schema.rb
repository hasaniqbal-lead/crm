# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_01_12_000019) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "locale", default: 0
    t.string "domain", limit: 100
    t.string "support_email", limit: 100
    t.bigint "feature_flags", default: 0, null: false
    t.integer "auto_resolve_duration"
    t.jsonb "limits", default: {}
    t.jsonb "custom_attributes", default: {}
    t.integer "status", default: 0
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.integer "role", default: 0
    t.bigint "inviter_id"
    t.datetime "active_at"
    t.integer "availability", default: 0, null: false
    t.boolean "auto_offline", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "user_id"], name: "uniq_user_id_per_account_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "agent_availability_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.integer "status", null: false
    t.datetime "changed_at", null: false
    t.string "reason"
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "changed_at"], name: "index_agent_availability_logs_on_account_id_and_changed_at"
    t.index ["account_id"], name: "index_agent_availability_logs_on_account_id"
    t.index ["status"], name: "index_agent_availability_logs_on_status"
    t.index ["user_id", "changed_at"], name: "index_agent_availability_logs_on_user_id_and_changed_at"
    t.index ["user_id"], name: "index_agent_availability_logs_on_user_id"
  end

  create_table "agent_metrics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.date "metric_date", null: false
    t.float "avg_first_response_time"
    t.float "avg_response_time"
    t.float "avg_resolution_time"
    t.integer "conversations_handled", default: 0
    t.integer "messages_sent", default: 0
    t.integer "conversations_resolved", default: 0
    t.integer "sla_met_count", default: 0
    t.integer "sla_missed_count", default: 0
    t.integer "online_duration", default: 0
    t.integer "busy_duration", default: 0
    t.integer "offline_duration", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "metric_date"], name: "index_agent_metrics_on_account_id_and_metric_date"
    t.index ["account_id"], name: "index_agent_metrics_on_account_id"
    t.index ["metric_date"], name: "index_agent_metrics_on_metric_date"
    t.index ["user_id", "metric_date"], name: "index_agent_metrics_on_user_id_and_metric_date", unique: true
    t.index ["user_id"], name: "index_agent_metrics_on_user_id"
  end

  create_table "agent_shifts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.time "shift_start", null: false
    t.time "shift_end", null: false
    t.integer "day_of_week", null: false
    t.string "timezone", default: "UTC"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "day_of_week"], name: "index_agent_shifts_on_account_id_and_day_of_week"
    t.index ["account_id"], name: "index_agent_shifts_on_account_id"
    t.index ["active"], name: "index_agent_shifts_on_active"
    t.index ["user_id", "account_id"], name: "index_agent_shifts_on_user_id_and_account_id"
    t.index ["user_id"], name: "index_agent_shifts_on_user_id"
  end

  create_table "applied_slas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "sla_policy_id", null: false
    t.bigint "conversation_id", null: false
    t.integer "sla_status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "sla_policy_id", "conversation_id"], name: "index_applied_slas_on_account_sla_policy_conversation", unique: true
    t.index ["account_id"], name: "index_applied_slas_on_account_id"
    t.index ["conversation_id"], name: "index_applied_slas_on_conversation_id"
    t.index ["sla_policy_id"], name: "index_applied_slas_on_sla_policy_id"
  end

  create_table "channel_facebook_pages", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "page_id", null: false
    t.string "page_access_token", null: false
    t.string "user_access_token", null: false
    t.string "instagram_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id", "account_id"], name: "index_channel_facebook_pages_on_page_id_and_account_id", unique: true
    t.index ["page_id"], name: "index_channel_facebook_pages_on_page_id"
  end

  create_table "channel_instagram", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "instagram_id", null: false
    t.string "access_token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_channel_instagram_on_account_id"
    t.index ["instagram_id"], name: "index_channel_instagram_on_instagram_id", unique: true
  end

  create_table "channel_whatsapp", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.jsonb "message_templates", default: {}
    t.datetime "message_templates_last_updated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_channel_whatsapp_on_account_id"
    t.index ["phone_number"], name: "index_channel_whatsapp_on_phone_number", unique: true
  end

  create_table "contact_inboxes", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.bigint "inbox_id", null: false
    t.string "source_id", null: false
    t.jsonb "hmac_verified", default: {}
    t.string "pubsub_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_inboxes_on_contact_id"
    t.index ["inbox_id", "source_id"], name: "index_contact_inboxes_on_inbox_id_and_source_id", unique: true
    t.index ["inbox_id"], name: "index_contact_inboxes_on_inbox_id"
    t.index ["pubsub_token"], name: "index_contact_inboxes_on_pubsub_token", unique: true
    t.index ["source_id"], name: "index_contact_inboxes_on_source_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.string "identifier"
    t.jsonb "additional_attributes", default: {}
    t.jsonb "custom_attributes", default: {}
    t.datetime "last_activity_at"
    t.string "contact_type"
    t.integer "blocked", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "email"], name: "index_contacts_on_account_id_and_email", where: "(email IS NOT NULL)"
    t.index ["account_id", "phone_number"], name: "index_contacts_on_account_id_and_phone_number", where: "(phone_number IS NOT NULL)"
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["phone_number"], name: "index_contacts_on_phone_number"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "assignee_id"
    t.bigint "team_id"
    t.integer "status", default: 0, null: false
    t.integer "display_id", null: false
    t.uuid "uuid", null: false
    t.string "identifier"
    t.datetime "last_activity_at", null: false
    t.datetime "agent_last_seen_at"
    t.datetime "assignee_last_seen_at"
    t.datetime "contact_last_seen_at"
    t.datetime "first_reply_created_at"
    t.integer "priority"
    t.datetime "snoozed_until"
    t.datetime "waiting_since"
    t.jsonb "additional_attributes", default: {}
    t.jsonb "custom_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "display_id"], name: "index_conversations_on_account_id_and_display_id", unique: true
    t.index ["account_id", "inbox_id", "status", "assignee_id"], name: "conv_acid_inbid_stat_asgnid_idx"
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["assignee_id", "account_id"], name: "index_conversations_on_assignee_id_and_account_id"
    t.index ["assignee_id"], name: "index_conversations_on_assignee_id"
    t.index ["contact_id"], name: "index_conversations_on_contact_id"
    t.index ["first_reply_created_at"], name: "index_conversations_on_first_reply_created_at"
    t.index ["inbox_id"], name: "index_conversations_on_inbox_id"
    t.index ["priority"], name: "index_conversations_on_priority"
    t.index ["status", "account_id"], name: "index_conversations_on_status_and_account_id"
    t.index ["team_id"], name: "index_conversations_on_team_id"
    t.index ["uuid"], name: "index_conversations_on_uuid", unique: true
    t.index ["waiting_since"], name: "index_conversations_on_waiting_since"
  end

  create_table "inbox_members", force: :cascade do |t|
    t.bigint "inbox_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inbox_id", "user_id"], name: "index_inbox_members_on_inbox_id_and_user_id", unique: true
    t.index ["inbox_id"], name: "index_inbox_members_on_inbox_id"
    t.index ["user_id"], name: "index_inbox_members_on_user_id"
  end

  create_table "inboxes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "channel_type"
    t.bigint "channel_id", null: false
    t.string "email_address"
    t.boolean "enable_auto_assignment", default: true
    t.string "greeting_message"
    t.boolean "greeting_enabled", default: false
    t.string "out_of_office_message"
    t.string "timezone", default: "UTC"
    t.boolean "working_hours_enabled", default: false
    t.boolean "enable_email_collect", default: true
    t.boolean "csat_survey_enabled", default: false
    t.jsonb "csat_config", default: {}, null: false
    t.boolean "allow_messages_after_resolved", default: true
    t.jsonb "auto_assignment_config", default: {}
    t.boolean "lock_to_single_conversation", default: false, null: false
    t.integer "sender_name_type", default: 0, null: false
    t.string "business_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_inboxes_on_account_id"
    t.index ["channel_id", "channel_type"], name: "index_inboxes_on_channel_id_and_channel_type"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "conversation_id", null: false
    t.text "content"
    t.integer "content_type", default: 0, null: false
    t.integer "message_type", null: false
    t.integer "status", default: 0
    t.boolean "private", default: false, null: false
    t.string "sender_type"
    t.bigint "sender_id"
    t.string "source_id"
    t.jsonb "content_attributes", default: {}
    t.jsonb "additional_attributes", default: {}
    t.jsonb "external_source_ids", default: {}
    t.jsonb "sentiment", default: {}
    t.text "processed_message_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "content_type", "created_at"], name: "idx_messages_account_content_created"
    t.index ["account_id", "created_at", "message_type"], name: "index_messages_on_account_created_type"
    t.index ["account_id", "inbox_id"], name: "index_messages_on_account_id_and_inbox_id"
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["conversation_id", "account_id", "message_type", "created_at"], name: "index_messages_on_conversation_account_type_created"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["inbox_id"], name: "index_messages_on_inbox_id"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender_type_and_sender_id"
    t.index ["source_id"], name: "index_messages_on_source_id"
  end

  create_table "platform_sla_configs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "channel_type", null: false
    t.integer "first_response_minutes", default: 30
    t.integer "resolution_hours", default: 24
    t.boolean "enabled", default: true
    t.jsonb "additional_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "channel_type"], name: "index_platform_sla_configs_on_account_id_and_channel_type", unique: true
    t.index ["account_id"], name: "index_platform_sla_configs_on_account_id"
    t.index ["channel_type"], name: "index_platform_sla_configs_on_channel_type"
    t.index ["enabled"], name: "index_platform_sla_configs_on_enabled"
  end

  create_table "sla_policies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "description"
    t.float "first_response_time_threshold"
    t.float "next_response_time_threshold"
    t.float "resolution_time_threshold"
    t.boolean "only_during_business_hours", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sla_policies_on_account_id"
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "allow_auto_assign", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_teams_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.text "tokens"
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "name", null: false
    t.string "display_name"
    t.string "avatar_url"
    t.integer "type", default: 0
    t.jsonb "custom_attributes", default: {}
    t.jsonb "ui_settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "account_users", "accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "agent_availability_logs", "accounts"
  add_foreign_key "agent_availability_logs", "users"
  add_foreign_key "agent_metrics", "accounts"
  add_foreign_key "agent_metrics", "users"
  add_foreign_key "agent_shifts", "accounts"
  add_foreign_key "agent_shifts", "users"
  add_foreign_key "applied_slas", "accounts"
  add_foreign_key "applied_slas", "conversations"
  add_foreign_key "applied_slas", "sla_policies"
  add_foreign_key "contact_inboxes", "contacts"
  add_foreign_key "contact_inboxes", "inboxes"
  add_foreign_key "contacts", "accounts"
  add_foreign_key "conversations", "accounts"
  add_foreign_key "conversations", "contacts"
  add_foreign_key "conversations", "inboxes"
  add_foreign_key "conversations", "teams"
  add_foreign_key "conversations", "users", column: "assignee_id"
  add_foreign_key "inbox_members", "inboxes"
  add_foreign_key "inbox_members", "users"
  add_foreign_key "inboxes", "accounts"
  add_foreign_key "messages", "accounts"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "inboxes"
  add_foreign_key "platform_sla_configs", "accounts"
  add_foreign_key "sla_policies", "accounts"
  add_foreign_key "teams", "accounts"
end
