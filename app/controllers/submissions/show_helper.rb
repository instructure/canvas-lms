module Submissions
  module ShowHelper
    def render_user_not_found
      respond_to do |format|
        format.html do
          flash[:error] = t("The specified user is not a student in this course")
          redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
        end
        format.json do
          render json: {
            errors: t("The specified user (%{id}) is not a student in this course", {
              id: params[:id]
            })
          }
        end
      end
    end
  end
end
