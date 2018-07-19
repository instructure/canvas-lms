class UserSettingsController < ApplicationController
  def update
    SettingsService.update_setting(
      id: params[:user_id],
      setting: params[:id],
      value: params[:value],
      noun: user
    )
  end

  def index
    render json: SettingsService.get_settings(
      id: params[:user_id],
      object: :user
    )
  end
end
