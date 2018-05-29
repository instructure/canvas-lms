class EnrollmentSettingsController < ApplicationController
  def update
    SettingsService.update_enrollment_setting(
      id: params[:enrollment_id],
      setting: params[:id],
      value: params[:value]
    )
  end
end
