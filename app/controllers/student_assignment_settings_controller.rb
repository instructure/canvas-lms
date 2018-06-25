class StudentAssignmentSettingsController < ApplicationController
  def update
    # {"value"=>"increment", "user_id"=>"1", "assignment_id"=>"2", "id"=>"max_attempts"}

    SettingsService.update_settings(
      id: {
        user_id: params[:user_id],
        assignment_id: params[:assignment_id]
      },
      setting: params[:id],
      value: params[:value],
      object: 'student_assignment'
    )
  end

  def index
    render json: SettingsService.get_settings(
      id: params[:user_id]
    )
  end
end
