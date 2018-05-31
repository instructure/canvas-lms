class UserSettingsController < ApplicationController
  def update
    SettingsService.update_user_setting(
      id: params[:user_id],
      setting: params[:id],
      value: params[:value]
    )
  end

  def index
    render json: SettingsService.get_user_settings(
      id: params[:user_id]
    )
  end


end
