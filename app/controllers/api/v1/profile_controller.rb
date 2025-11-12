class Api::V1::ProfileController < Api::V1::BaseController
  # GET /api/v1/profile
  def show
    render json: {
      user: user_json(current_user),
      accounts: current_user.account_users.map { |au| account_summary_json(au) }
    }
  end

  # PATCH /api/v1/profile
  def update
    if current_user.update(profile_params)
      render json: {
        user: user_json(current_user),
        message: 'Profile updated successfully'
      }
    else
      render json: {
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/profile/update_availability
  def update_availability
    # Update availability across all accounts
    current_user.account_users.update_all(availability: params[:availability])

    # Log availability change
    current_user.account_users.each do |account_user|
      AgentAvailabilityLog.create!(
        user_id: current_user.id,
        account_id: account_user.account_id,
        status: params[:availability],
        logged_at: Time.current
      )
    end

    render json: {
      message: 'Availability updated successfully',
      availability: params[:availability]
    }
  end

  private

  def profile_params
    params.require(:user).permit(:name, :display_name, :avatar_url)
  end

  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      display_name: user.display_name,
      avatar_url: user.avatar_url,
      created_at: user.created_at
    }
  end

  def account_summary_json(account_user)
    {
      account_id: account_user.account_id,
      account_name: account_user.account&.name,
      role: account_user.role,
      availability: account_user.availability
    }
  end
end
