class Api::V1::AgentShiftsController < Api::V1::BaseController
  before_action :set_shift, only: [:show, :update, :destroy]

  # GET /api/v1/accounts/:account_id/shifts
  def index
    @shifts = AgentShift.where(account_id: @current_account.id)

    # Filter by user
    @shifts = @shifts.where(user_id: params[:user_id]) if params[:user_id].present?

    # Filter by day of week
    @shifts = @shifts.where(day_of_week: params[:day_of_week]) if params[:day_of_week].present?

    # Order by day and start time
    @shifts = @shifts.order(:day_of_week, :shift_start)

    render json: {
      data: @shifts.map { |shift| shift_json(shift) }
    }
  end

  # GET /api/v1/accounts/:account_id/shifts/:id
  def show
    authorize @shift

    render json: {
      shift: shift_json(@shift)
    }
  end

  # POST /api/v1/accounts/:account_id/shifts
  def create
    @shift = AgentShift.new(shift_params)
    @shift.account_id = @current_account.id
    authorize @shift

    if @shift.save
      render json: { shift: shift_json(@shift) }, status: :created
    else
      render json: { errors: @shift.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/shifts/:id
  def update
    authorize @shift

    if @shift.update(shift_params)
      render json: { shift: shift_json(@shift) }
    else
      render json: { errors: @shift.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/shifts/:id
  def destroy
    authorize @shift

    @shift.destroy
    render json: { message: 'Shift deleted successfully' }
  end

  # GET /api/v1/accounts/:account_id/shifts/current
  # Get current active shifts
  def current
    current_time = Time.current.in_time_zone(params[:timezone] || 'UTC')
    current_day = current_time.wday
    current_time_of_day = current_time.strftime('%H:%M:%S')

    @shifts = AgentShift.where(account_id: @current_account.id)
                       .where(day_of_week: current_day)
                       .where('shift_start <= ? AND shift_end >= ?', current_time_of_day, current_time_of_day)

    render json: {
      current_time: current_time,
      day_of_week: current_day,
      active_shifts: @shifts.map { |shift| shift_json(shift) },
      agents_on_duty: @shifts.map { |s| { id: s.user_id, name: s.user&.name } }.uniq
    }
  end

  # GET /api/v1/accounts/:account_id/shifts/weekly/:user_id
  # Get weekly schedule for an agent
  def weekly
    user_id = params[:user_id]

    @shifts = AgentShift.where(account_id: @current_account.id, user_id: user_id)
                       .order(:day_of_week, :shift_start)

    # Group by day of week
    weekly_schedule = (0..6).map do |day|
      {
        day: Date::DAYNAMES[day],
        day_number: day,
        shifts: @shifts.select { |s| s.day_of_week == day }.map { |s| shift_json(s) }
      }
    end

    render json: {
      user_id: user_id,
      user_name: User.find(user_id)&.name,
      weekly_schedule: weekly_schedule
    }
  end

  private

  def set_shift
    @shift = AgentShift.find(params[:id])
  end

  def shift_params
    params.require(:shift).permit(
      :user_id, :shift_start, :shift_end, :day_of_week, :timezone
    )
  end

  def shift_json(shift)
    {
      id: shift.id,
      user_id: shift.user_id,
      user_name: shift.user&.name,
      shift_start: shift.shift_start,
      shift_end: shift.shift_end,
      day_of_week: shift.day_of_week,
      day_name: Date::DAYNAMES[shift.day_of_week],
      timezone: shift.timezone,
      created_at: shift.created_at,
      updated_at: shift.updated_at
    }
  end
end
