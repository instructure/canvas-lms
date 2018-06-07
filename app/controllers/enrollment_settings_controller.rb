class EnrollmentSettingsController < ApplicationController
  def update
    if params[:id] == 'sequence_control'
      params[:value] = ActiveRecord::Type::Boolean.new.deserialize(params[:value])
    end
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
