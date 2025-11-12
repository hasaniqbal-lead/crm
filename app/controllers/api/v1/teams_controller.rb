class Api::V1::TeamsController < Api::V1::BaseController
  before_action :set_team, only: [:show, :update, :destroy, :add_member, :remove_member]

  # GET /api/v1/accounts/:account_id/teams
  def index
    @teams = @current_account.teams
                             .order(created_at: :desc)

    render json: {
      data: @teams.map { |team| team_json(team) }
    }
  end

  # GET /api/v1/accounts/:account_id/teams/:id
  def show
    authorize @team

    render json: {
      team: team_json(@team),
      members: @team.team_members.map { |tm| team_member_json(tm) },
      conversations_count: @team.conversations.count
    }
  end

  # POST /api/v1/accounts/:account_id/teams
  def create
    @team = @current_account.teams.build(team_params)
    authorize @team

    if @team.save
      render json: { team: team_json(@team) }, status: :created
    else
      render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/teams/:id
  def update
    authorize @team

    if @team.update(team_params)
      render json: { team: team_json(@team) }
    else
      render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/teams/:id
  def destroy
    authorize @team

    @team.destroy
    render json: { message: 'Team deleted successfully' }
  end

  # POST /api/v1/accounts/:account_id/teams/:id/add_member
  def add_member
    authorize @team

    user = @current_account.users.find(params[:user_id])
    team_member = @team.team_members.create!(user: user)

    render json: {
      message: 'Member added successfully',
      member: team_member_json(team_member)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /api/v1/accounts/:account_id/teams/:id/remove_member
  def remove_member
    authorize @team

    team_member = @team.team_members.find_by!(user_id: params[:user_id])
    team_member.destroy

    render json: { message: 'Member removed successfully' }
  end

  private

  def set_team
    @team = @current_account.teams.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :description, :allow_auto_assign)
  end

  def team_json(team)
    {
      id: team.id,
      name: team.name,
      description: team.description,
      allow_auto_assign: team.allow_auto_assign,
      created_at: team.created_at,
      updated_at: team.updated_at,
      members_count: team.team_members.count
    }
  end

  def team_member_json(member)
    {
      id: member.id,
      user_id: member.user_id,
      user_name: member.user&.name,
      user_email: member.user&.email,
      created_at: member.created_at
    }
  end
end
