# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Lti
  class AssetProcessorController < ApplicationController
    before_action { require_feature_enabled :lti_asset_processor }
    before_action :require_user
    before_action :require_asset_processor, except: [:resubmit_discussion_notices_all]
    before_action :require_context
    before_action :require_access_to_context
    before_action :require_submission

    def resubmit_notice
      submission_to_notify = if submission.group_id.present?
                               Lti::AssetProcessorNotifier.get_original_submission_for_group(submission)
                             else
                               submission
                             end
      Lti::AssetProcessorNotifier.notify_asset_processors(
        submission_to_notify,
        asset_processor
      )
      head :no_content
    rescue Lti::AssetProcessorNotifier::MissingGroupmateSubmissionError
      render json: {
               errors: {
                 error_code: "groupmate_submission_not_found",
                 message: "Groupmate submission could not be found"
               }
             },
             status: :not_found
    end

    def resubmit_discussion_notices_all
      topic = assignment.discussion_topic
      return render json: { error: "Not a discussion assignment" }, status: :unprocessable_entity unless topic
      return render status: :forbidden, plain: "invalid_request" unless context.grants_any_right?(@current_user, session, :manage_grades)

      entry_ids = topic.discussion_entries.active.where(user_id: student.id).pluck(:id)
      return head :no_content if entry_ids.empty?

      submission = assignment.submission_for_student(student)

      GuardRail.activate(:secondary) do
        DiscussionEntryVersion
          .where(discussion_entry_id: entry_ids)
          .select("DISTINCT ON (discussion_entry_id) discussion_entry_versions.*")
          .order(:discussion_entry_id, version: :desc)
          .preload(:discussion_entry, :user, :root_account)
          .find_in_batches(batch_size: 100) do |versions|
          Lti::AssetProcessorDiscussionNotifier.delay_if_production.notify_asset_processors_of_discussion(
            assignment:,
            submission:,
            discussion_entry_versions: versions,
            contribution_status: Lti::Pns::LtiAssetProcessorContributionNoticeBuilder::SUBMITTED,
            current_user: student,
            asset_processor: nil,
            tool_id: nil
          )
        end
      end

      head :no_content
    end

    def assignment_id
      params[:assignment_id] || asset_processor&.assignment_id
    end

    def assignment
      @assignment ||= if params[:assignment_id]
                        Assignment.find(params[:assignment_id])
                      else
                        asset_processor.assignment
                      end
    end

    def asset_processor_id
      params.require(:asset_processor_id)
    end

    def asset_processor
      @asset_processor ||= Lti::AssetProcessor.find(asset_processor_id)
    end

    def require_asset_processor
      not_found unless asset_processor
    end

    def context
      @context ||= assignment.context
    end

    def require_context
      not_found unless assignment&.context
    end

    def require_access_to_context
      return if context.is_a?(Course) && context.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)

      render status: :forbidden, plain: "invalid_request"
    end

    # Format: <student_id> or "anonymous:<anonymous_id>"
    def student_id
      params.require(:student_id)
    end

    def anonymous_student_id?
      student_id.to_s.start_with?("anonymous:")
    end

    def extract_anonymous_id
      student_id.to_s.sub("anonymous:", "")
    end

    def student
      @student ||= if anonymous_student_id?
                     @current_submission ||= assignment.submissions.find_by(anonymous_id: extract_anonymous_id)
                     @current_submission&.user
                   else
                     User.find_by(id: student_id)
                   end
    end

    # "latest", 0, or any invalid value will be treated as latest
    def attempt
      @attempt ||= params[:attempt].to_i
    end

    def submission
      @submission ||=
        begin
          @current_submission ||= assignment.submission_for_student(student)

          if @current_submission && attempt.positive?
            version = @current_submission.versions.find { |s| s.model.attempt == attempt }&.model
          end

          version || @current_submission
        end
    end

    def require_submission
      not_found unless student && assignment.assigned?(student)
    end
  end
end
