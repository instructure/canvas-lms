# @API SIS Integration
#
# Includes helpers for integration with SIS systems.
#
class SisApiController < ApplicationController
  # @API Retrieve assignments enabled for grade export to SIS
  #
  # Retrieve an list of course ids and assignment ids for assignments
  # configured with the property "post_to_sis".
  #
  # @argument account_id [Integer] The unique ID of the account to search
  #
  # @example_response
  #   [
  #     {
  #       "course_id": 1,
  #       "assignment_ids": [2, 3]
  #     },
  #     {
  #       "course_id": 2,
  #       "assignment_ids": [4]
  #     }
  #   ]
  #
  def sis_assignments
    account = Account.find(params[:account_id])
    return unless authorized_action(account, @current_user, :view_all_grades)

    unless account.feature_enabled?(:bulk_sis_grade_export) || Lti::AppLaunchCollator.any?(account, [:post_grades])
      return render(
        json: {
          error: 'Bulk SIS Grade Export feature not on, or no SIS integrations configured for account'
        },
        status: :bad_request
      )
    end

    account_ids = [account.id] + Account.sub_account_ids_recursive(account.id)
    course_asmt_ids = []
    Course.not_deleted.where(account_id: account_ids).find_ids_in_batches do |course_ids|
      course_asmts = Assignment.active.where(
        context_type: 'Course',
        context_id: course_ids,
        post_to_sis: true
      ).select([:id, :context_id]).group_by(&:context_id)
      course_asmts.each do |course_id, assignments|
        course_asmt_ids << { course_id: course_id, assignment_ids: assignments.map(&:id) }
      end
    end
    render json:  course_asmt_ids
  end
end
