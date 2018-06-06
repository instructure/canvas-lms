class EnrollmentSettingsController < ApplicationController
  def update
    SettingsService.update_enrollment_setting(
      id: params[:enrollment_id],
      setting: params[:id],
      value: params[:value]
    )
    render json: {'status': 'ok'}
  end

  def index
    render json: SettingsService.get_enrollment_settings(
      id: params[:enrollment_id]
    )
  end
end
