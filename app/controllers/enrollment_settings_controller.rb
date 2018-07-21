class EnrollmentSettingsController < ApplicationController
  def update
    if params[:id] == 'sequence_control'
      params[:value] = ActiveRecord::Type::Boolean.new.deserialize(params[:value])
    end
    SettingsService.update_settings(
      id: params[:enrollment_id],
      setting: params[:id],
      value: params[:value],
      object: :enrollment
    )
    render json: {'status': 'ok'}
  end

  def index
    render json: SettingsService.get_settings(
      id: params[:enrollment_id],
      object: :enrollment
    )
  end
end
