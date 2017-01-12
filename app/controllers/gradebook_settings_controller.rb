class GradebookSettingsController < ApplicationController
  before_action :require_user
  before_action :require_context
  before_action :authorize

  def update
    @current_user.preferences[:gradebook_settings] = {
      @context.id => gradebook_settings_params.to_h
    }
    respond_to do |format|
      if @current_user.save
        format.json do
          render json: { gradebook_settings: gradebook_settings }, status: :ok
        end
      else
        format.json { render json: @current_user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def gradebook_settings_params
    params.require(:gradebook_settings).permit(:show_inactive_enrollments, :show_concluded_enrollments)
  end

  def authorize
    authorized_action(@context, @current_user, :view_all_grades)
  end

  def gradebook_settings
    @current_user.preferences.fetch(:gradebook_settings)
  end
end
