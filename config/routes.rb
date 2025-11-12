Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Webhooks - External platform callbacks
  namespace :webhooks do
    # WhatsApp webhooks
    post ':phone_number', to: 'whatsapp#events', constraints: { phone_number: /[^\/]+/ }
    get ':phone_number', to: 'whatsapp#verify', constraints: { phone_number: /[^\/]+/ }

    # Instagram webhooks
    post 'instagram', to: 'instagram#events'
    get 'instagram', to: 'instagram#verify'

    # Facebook webhooks (shares same controller as Instagram for Meta verification)
    post 'facebook', to: 'facebook#events'
    get 'facebook', to: 'facebook#verify'
  end

  # API v1 - Main application API
  namespace :api do
    namespace :v1 do
      # Authentication endpoints
      namespace :auth do
        post 'login', to: 'sessions#create'
        post 'refresh', to: 'sessions#refresh'
        delete 'logout', to: 'sessions#destroy'
        post 'signup', to: 'registrations#create'
        post 'forgot_password', to: 'passwords#create'
        post 'reset_password', to: 'passwords#update'
        get 'validate_token', to: 'sessions#validate'
      end

      # Account scoped resources
      scope '/accounts/:account_id' do
        # Conversations - Core messaging
        resources :conversations, only: [:index, :show, :create, :update] do
          member do
            post 'assign', to: 'conversations#assign_agent'
            post 'resolve', to: 'conversations#resolve'
            post 'reopen', to: 'conversations#reopen'
            post 'snooze', to: 'conversations#snooze'
            patch 'priority', to: 'conversations#update_priority'
          end

          # Messages within conversations
          resources :messages, only: [:index, :create, :update] do
            collection do
              post 'send_template', to: 'messages#send_template'
            end
          end
        end

        # Contacts - Customer management
        resources :contacts, only: [:index, :show, :create, :update, :destroy] do
          collection do
            get 'search', to: 'contacts#search'
          end
          member do
            get 'conversations', to: 'contacts#conversations'
            patch 'block', to: 'contacts#block'
            patch 'unblock', to: 'contacts#unblock'
          end
        end

        # Inboxes - Channel management
        resources :inboxes, only: [:index, :show, :create, :update, :destroy] do
          member do
            post 'add_agent', to: 'inboxes#add_agent'
            delete 'remove_agent/:user_id', to: 'inboxes#remove_agent'
            get 'agents', to: 'inboxes#agents'
          end
        end

        # Channels - Platform connections
        namespace :channels do
          resources :whatsapp, only: [:create, :update, :destroy] do
            member do
              post 'sync_templates', to: 'whatsapp#sync_templates'
              get 'health', to: 'whatsapp#health'
            end
          end

          resources :facebook, only: [:create, :update, :destroy] do
            member do
              post 'reauthorize', to: 'facebook#reauthorize'
            end
          end

          resources :instagram, only: [:create, :update, :destroy] do
            member do
              post 'refresh_token', to: 'instagram#refresh_token'
            end
          end
        end

        # Agents - User management within account
        resources :agents, controller: 'account_users', only: [:index, :show, :create, :update, :destroy] do
          member do
            patch 'availability', to: 'account_users#update_availability'
            get 'metrics', to: 'account_users#metrics'
            get 'conversations', to: 'account_users#conversations'
          end
        end

        # Teams - Agent grouping
        resources :teams, only: [:index, :show, :create, :update, :destroy] do
          member do
            post 'add_agent', to: 'teams#add_agent'
            delete 'remove_agent/:user_id', to: 'teams#remove_agent'
            get 'agents', to: 'teams#agents'
          end
        end

        # Shifts - Agent scheduling
        resources :agent_shifts, path: 'shifts', only: [:index, :show, :create, :update, :destroy] do
          collection do
            get 'calendar', to: 'agent_shifts#calendar'
            get 'current', to: 'agent_shifts#current_shifts'
          end
        end

        # SLA Management
        resources :sla_policies, only: [:index, :show, :create, :update, :destroy] do
          member do
            get 'compliance', to: 'sla_policies#compliance_report'
          end
        end

        resources :platform_sla_configs, path: 'platform_slas', only: [:index, :show, :create, :update, :destroy]

        # Reports & Analytics
        namespace :reports do
          get 'overview', to: 'dashboard#overview'
          get 'agent_performance', to: 'agents#performance'
          get 'conversation_metrics', to: 'conversations#metrics'
          get 'sla_compliance', to: 'slas#compliance'
          get 'response_times', to: 'response_times#index'
          get 'channel_breakdown', to: 'channels#breakdown'
        end

        # Admin specific endpoints
        namespace :admin do
          resources :accounts, only: [:show, :update] do
            member do
              patch 'settings', to: 'accounts#update_settings'
              get 'usage', to: 'accounts#usage_stats'
            end
          end
        end
      end

      # Current user endpoints (not account scoped)
      namespace :profile do
        get '/', to: 'users#show'
        patch '/', to: 'users#update'
        get 'accounts', to: 'users#accounts'
        get 'notifications', to: 'users#notifications'
        patch 'preferences', to: 'users#update_preferences'
      end
    end
  end

  # Root route
  root to: proc { [200, {}, ['CRM API - See /api/v1 for endpoints']] }
end
