# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

class SubmissionsBaseController < ApplicationController
  include GradebookSettingsHelpers
  include AssignmentsHelper
  include AssessmentRequestHelper

  include Api::V1::Rubric
  include Api::V1::SubmissionComment

  def show
    return unless authorized_action(@submission.context, @current_user, :read)

    @visible_rubric_assessments = @submission.visible_rubric_assessments_for(@current_user)
    @assessment_request = @submission.assessment_requests.where(assessor_id: @current_user).first

    if @submission&.user_id == @current_user.id
      @submission&.mark_read(@current_user)
    end

    respond_to do |format|
      @submission.limit_comments(@current_user, session)
      format.html do
        rubric_association = @assignment&.rubric_association
        rubric_association_json = rubric_association&.as_json
        unless rubric_association_json.nil?
          rubric_association_json["rubric_association"]["hide_points"] = rubric_association.hide_points(@current_user)
        end
        rubric = rubric_association&.rubric
        js_env({
                 nonScoringRubrics: @domain_root_account.feature_enabled?(:non_scoring_rubrics),
                 outcome_extra_credit_enabled: @context.feature_enabled?(:outcome_extra_credit),
                 rubric: rubric ? rubric_json(rubric, @current_user, session, style: "full") : nil,
                 rubricAssociation: rubric_association_json ? rubric_association_json["rubric_association"] : nil,
                 outcome_proficiency:,
                 media_comment_asset_string: @current_user.asset_string,
                 EMOJIS_ENABLED: @context.feature_enabled?(:submission_comment_emojis),
                 EMOJI_DENY_LIST: @context.root_account.settings[:emoji_deny_list]
               })

        js_bundle :submissions
        css_bundle :submission

        add_crumb(t("crumbs.assignments", "Assignments"), context_url(@context, :context_assignments_url))
        add_crumb(@assignment.title, context_url(@context, :context_assignment_url, @assignment.id))
        add_crumb(user_crumb_name)

        set_active_tab "assignments"

        render "submissions/show", stream: can_stream_template?
      end

      format.json do
        submission_json_exclusions = []

        if @submission.submission_type == "online_quiz" &&
           @submission.hide_grade_from_student? &&
           !@assignment.grants_right?(@current_user, :grade)
          submission_json_exclusions << :body
        end

        @submission.limit_comments(@current_user, session)

        render json: @submission.as_json(
          Submission.json_serialization_full_parameters(
            except: %i[quiz_submission submission_history]
          ).merge({
                    except: submission_json_exclusions,
                    permissions: {
                      user: @current_user,
                      session:,
                      include_permissions: false
                    }
                  })
        )
      end
    end
  end

  def update
    permissions = { user: @current_user, session:, include_permissions: false }
    provisional = @assignment.moderated_grading? && params[:submission][:provisional]
    submission_json_exclusions = []

    if @assignment.anonymous_peer_reviews && @submission.peer_reviewer?(@current_user)
      submission_json_exclusions << :user_id
    end

    if @submission.submission_type == "online_quiz" &&
       @submission.hide_grade_from_student? &&
       !@assignment.grants_right?(@current_user, :grade)

      submission_json_exclusions << :body
    end

    if params[:submission][:student_entered_score] && @submission.grants_right?(@current_user, session, :comment)
      update_student_entered_score(params[:submission][:student_entered_score])

      render json: @submission.as_json(except: submission_json_exclusions, permissions:)
      return
    end

    if authorized_action(@submission, @current_user, :comment)
      params[:submission][:commenter] = @current_user
      admin_in_context = !@context_enrollment || @context_enrollment.admin?

      error = nil
      if params[:attachments]
        params[:submission][:comment_attachments] = params[:attachments].keys.map do |idx|
          attachment_json = params[:attachments][idx].permit(Attachment.permitted_attributes)
          attachment_json[:user] = @current_user
          attachment = @assignment.attachments.new(attachment_json.except(:uploaded_data))
          Attachments::Storage.store_for_attachment(attachment, attachment_json[:uploaded_data])
          attachment.save!
          attachment
        end
      end
      unless @submission.grants_right?(@current_user, session, :submit)
        @request = @submission.assessment_requests.where(assessor_id: @current_user).first if @current_user
        params[:submission] = {
          attempt: params[:submission][:attempt],
          comment: params[:submission][:comment],
          comment_attachments: params[:submission][:comment_attachments],
          media_comment_id: params[:submission][:media_comment_id],
          media_comment_type: params[:submission][:media_comment_type],
          commenter: @current_user,
          assessment_request: @request,
          group_comment: params[:submission][:group_comment],
          hidden: @submission.hide_grade_from_student? && admin_in_context,
          provisional:,
          final: params[:submission][:final],
          draft_comment: Canvas::Plugin.value_to_boolean(params[:submission][:draft_comment])
        }
        params[:submission].delete(:attempt) unless @context.feature_enabled?(:assignments_2_student)
      end
      begin
        @submissions = @assignment.update_submission(@user, params[:submission].to_unsafe_h)
      rescue => e
        Canvas::Errors.capture_exception(:submissions, e)
        logger.error(e)
        error = e
      end
      respond_to do |format|
        if @submissions
          @submissions = @submissions.select { |s| s.grants_right?(@current_user, session, :read) }
          is_final = provisional && params[:submission][:final] && @assignment.permits_moderation?(@current_user)
          @submissions.each do |s|
            s.limit_comments(@current_user, session) unless @submission.grants_right?(@current_user, session, :submit)
            s.apply_provisional_grade_filter!(s.provisional_grade(@current_user, final: is_final)) if provisional
          end

          flash[:notice] = t("assignment_submitted", "Assignment submitted.")

          format.html { redirect_to course_assignment_url(@context, @assignment) }

          json_args = Submission.json_serialization_full_parameters({
                                                                      except: [:quiz_submission, :submission_history]
                                                                    }).merge(except: submission_json_exclusions, permissions:)
          json_args[:methods] << :provisional_grade_id if provisional

          submissions_json = @submissions.map do |submission|
            submission_json = submission.as_json(json_args)
            submission_json[:submission][:submission_comments] = anonymous_moderated_submission_comments_json(
              assignment: @assignment,
              avatars: service_enabled?(:avatars),
              submissions: @submissions,
              submission_comments: submission.visible_submission_comments_for(@current_user),
              current_user: @current_user,
              course: @context
            )
            submission_json
          end

          format.json { render json: submissions_json, status: :created, location: course_gradebook_url(@submission.assignment.context) }
          format.text { render json: submissions_json, status: :created, location: course_gradebook_url(@submission.assignment.context) }
        else
          @error_message = t("errors_update_failed", "Update Failed")
          flash[:error] = @error_message

          error_json = { base: @error_message }
          error_json[:error_code] = error.error_code if error
          error_status = error&.status_code || :bad_request

          format.html { render :show, id: @assignment.context.id }
          format.json { render json: { errors: error_json }, status: error_status }
          format.text { render json: { errors: error_json }, status: error_status }
        end
      end
    end
  end

  def redo_submission
    if !(@assignment.can_reassign?(@current_user) && @submission.cached_due_date)
      render_unauthorized_action
    elsif @assignment.locked_for?(@submission.user)
      render json: {
               errors: {
                 message: "Assignment is locked for student.",
                 error_code: "ASSIGNMENT_LOCKED"
               }
             },
             status: :unprocessable_entity
    else
      @submission.update!(redo_request: true)
      head :no_content
    end
  end

  def turnitin_report
    plagiarism_report("turnitin")
  end

  def resubmit_to_turnitin
    resubmit_to_plagiarism("turnitin")
  end

  def vericite_report
    plagiarism_report("vericite")
  end

  def resubmit_to_vericite
    resubmit_to_plagiarism("vericite")
  end

  def originality_report
    plagiarism_report("originality_report")
  end

  private

  def update_student_entered_score(score)
    new_score = (score.present? && score != "null") ? score.to_f.round(2) : nil
    # TODO: fix this by making the callback optional
    # intentionally skipping callbacks here to fix a bug where entering a
    # what-if grade for a quiz can put the submission back in a 'pending review' state
    @submission.update_column(:student_entered_score, new_score)
  end

  def outcome_proficiency
    if @context.root_account.feature_enabled?(:non_scoring_rubrics)
      @context.account.resolved_outcome_proficiency&.as_json
    end
  end

  def legacy_plagiarism_report(submission, asset_string, type)
    plag_data = (type == "vericite") ? submission.vericite_data : submission.turnitin_data

    if plag_data.dig(asset_string, :report_url).present?
      polymorphic_url(
        [:retrieve, @context, :external_tools],
        url: plag_data[asset_string][:report_url],
        # Hack because turnitin supports only 1.1 here, but they have 1.3 tools
        # with the same domain that we will find because we prefer 1.3 tools:
        prefer_1_1: type == "turnitin",
        display: "borderless"
      )
    elsif type == "vericite"
      # VeriCite URL
      submission.vericite_report_url(asset_string, @current_user, session)
    else
      # Turnitin URL
      submission.turnitin_report_url(asset_string, @current_user)
    end
  rescue
    # vericite_report_url or turnitin_report_url may throw an error
    nil
  end

  protected

  def plagiarism_report(type)
    return head(:bad_request) if @submission.blank?

    @asset_string = params[:asset_string]
    if authorized_action(@submission, @current_user, :read)
      url = if type == "originality_report"
              @submission.originality_report_url(@asset_string, @current_user, params[:attempt])
            else
              legacy_plagiarism_report(@submission, @asset_string, type)
            end

      if url
        redirect_to url
      else
        flash[:error] = t("errors.no_report", "Couldn't find a report for that submission item")
        redirect_to default_plagiarism_redirect_url
      end
    end
  end

  def resubmit_to_plagiarism(type)
    return head(:bad_request) if @submission.blank?

    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      Canvas::LiveEvents.plagiarism_resubmit(@submission)

      if type == "vericite"
        # VeriCite
        @submission.resubmit_to_vericite
        message = t("Successfully resubmitted to VeriCite.")
      else
        # turnitin
        @submission.resubmit_to_turnitin
        message = t("Successfully resubmitted to turnitin.")
      end
      respond_to do |format|
        format.html do
          flash[:notice] = message
          redirect_to default_plagiarism_redirect_url
        end
        format.json { head :no_content }
      end
    end
  end

  def default_plagiarism_redirect_url
    named_context_url(@context, :context_assignment_submission_url, @assignment.id, @submission.user_id)
  end
end
