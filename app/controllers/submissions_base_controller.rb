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
  include Api::V1::Rubric

  def show
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
        rubric = rubric_association&.rubric
        js_env({
          nonScoringRubrics: @domain_root_account.feature_enabled?(:non_scoring_rubrics),
          outcome_extra_credit_enabled: @context.feature_enabled?(:outcome_extra_credit),
          rubric: rubric ? rubric_json(rubric, @current_user, session, style: 'full') : nil,
          rubricAssociation: rubric_association_json ? rubric_association_json['rubric_association'] : nil,
          outcome_proficiency: outcome_proficiency
        })
         render 'submissions/show'
      end
      format.json do
        @submission.limit_comments(@current_user, session)
        render :json => @submission.as_json(
          Submission.json_serialization_full_parameters(
            except: %i(quiz_submission submission_history)
          ).merge(permissions: {
            user: @current_user,
            session: session,
            include_permissions: false
          })
        )
      end
    end
  end

  def update
    provisional = @assignment.moderated_grading? && params[:submission][:provisional]

    if params[:submission][:student_entered_score] && @submission.grants_right?(@current_user, session, :comment)
      update_student_entered_score(params[:submission][:student_entered_score])

      render json: @submission.as_json(permissions: {
        user: @current_user,
        session: session,
        include_permissions: false
      })
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
          :comment => params[:submission][:comment],
          :comment_attachments => params[:submission][:comment_attachments],
          :media_comment_id => params[:submission][:media_comment_id],
          :media_comment_type => params[:submission][:media_comment_type],
          :commenter => @current_user,
          :assessment_request => @request,
          :group_comment => params[:submission][:group_comment],
          :hidden => @assignment.muted? && admin_in_context,
          :provisional => provisional,
          :final => params[:submission][:final],
          :draft_comment => Canvas::Plugin.value_to_boolean(params[:submission][:draft_comment])
        }
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
          @submissions = @submissions.select{|s| s.grants_right?(@current_user, session, :read) }
          is_final = provisional && params[:submission][:final] && @context.grants_right?(@current_user, :moderate_grades)
          @submissions.each do |s|
            s.limit_comments(@current_user, session) unless @submission.grants_right?(@current_user, session, :submit)
            s.apply_provisional_grade_filter!(s.provisional_grade(@current_user, final: is_final)) if provisional
          end

          flash[:notice] = t('assignment_submitted', 'Assignment submitted.')

          format.html { redirect_to course_assignment_url(@context, @assignment) }

          # TODO: the serialization here needs to be abstracted and shared with speed_grader.rb
          comments_include = if @assignment.can_view_other_grader_comments?(@current_user)
            :all_submission_comments
          elsif admin_in_context
            :submission_comments
          else
            :visible_submission_comments
          end

          json_args = Submission.json_serialization_full_parameters({
            :except => [:quiz_submission,:submission_history],
            :comments => comments_include
          }).merge(:permissions => { :user => @current_user, :session => session, :include_permissions => false })
          json_args[:methods] << :provisional_grade_id if provisional

          submissions_json = @submissions.map do |submission|
            submission_json = submission.as_json(json_args)
            submission_json[:submission][:submission_comments] = submission_comments_to_json(submission_json[:submission].delete(comments_include))
            submission_json
          end

          format.json { render json: submissions_json, status: :created, location: course_gradebook_url(@submission.assignment.context) }
          format.text { render json: submissions_json, status: :created, location: course_gradebook_url(@submission.assignment.context) }
        else
          @error_message = t('errors_update_failed', "Update Failed")
          flash[:error] = @error_message

          error_json = {base: @error_message}
          error_json[:error_code] = error.error_code if error
          error_status = error&.status_code || :bad_request

          format.html { render :show, id: @assignment.context.id }
          format.json { render json: {errors: error_json}, status: error_status }
          format.text { render json: {errors: error_json}, status: error_status }
        end
      end
    end
  end

  private

  def update_student_entered_score(score)
    new_score = score.present? && score != "null" ? score.to_f.round(2) : nil
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

  def submission_comments_to_json(submission_comments)
    @submission_comment_methods ||= avatars ? [:avatar_path] : []
    @submission_comment_fields ||= %i(attachments author_id author_name cached_attachments comment
                                      created_at draft group_comment_id id media_comment_id
                                      media_comment_type)

    visible_submission_comments(submission_comments).map do |submission_comment|
      json = submission_comment.as_json(include_root: false,
                                        methods: @submission_comment_methods,
                                        only: @submission_comment_fields)
      author_id = submission_comment.author_id.to_s

      json[:publishable] = submission_comment.publishable_for?(@current_user)
      if anonymous_students? && student_ids_to_anonymous_ids.key?(author_id)
        json.delete(:author_id)
        json.delete(:author_name)
        json[:anonymous_id] = student_ids_to_anonymous_ids[author_id]
        json[:avatar_path] = User.default_avatar_fallback if avatars
      elsif anonymous_graders? && grader_ids_to_anonymous_ids.key?(author_id)
        json.delete(:author_id)
        json[:anonymous_id] = grader_ids_to_anonymous_ids[author_id]
        unless author_id == @current_user.id.to_s
          json[:avatar_path] = User.default_avatar_fallback if avatars
          json.delete(:author_name)
        end
      end

      json
    end
  end

  def anonymous_students?
    return @anonymous_students if defined? @anonymous_students
    @anonymous_students = !@assignment.can_view_student_names?(@current_user)
  end

  def anonymous_graders?
    return @anonymous_graders if defined? @anonymous_graders
    @anonymous_graders = !@assignment.can_view_other_grader_identities?(@current_user)
  end

  def grader_comments_hidden?
    return @grader_comments_hidden if defined? @grader_comments_hidden
    @grader_comments_hidden = !@assignment.can_view_other_grader_comments?(@current_user)
  end

  def visible_submission_comments(submission_comments)
    return submission_comments unless grader_comments_hidden?
    submission_comments.reject {|submission_comment| other_grader?(submission_comment.author_id)}
  end

  def student_ids_to_anonymous_ids
    return @student_ids_to_anonymous_ids if defined? @student_ids_to_anonymous_ids
    # ensure each student has membership, even without a submission
    @student_ids_to_anonymous_ids = students.each_with_object({}) {|student, map| map[student.id.to_s] = nil}
    @submissions.each do |submission|
      @student_ids_to_anonymous_ids[submission.user_id.to_s] = submission.anonymous_id
    end
    @student_ids_to_anonymous_ids
  end

  def students
    @students ||= begin
      includes = gradebook_includes(user: @current_user, course: @context)
      @assignment.representatives(@current_user, includes: includes) do |rep, others|
        others.each { |s| res[:context][:rep_for_student][s.id] = rep.id }
      end
    end
  end

  def grader_ids_to_anonymous_ids
    @assignment.grader_ids_to_anonymous_ids
  end

  def other_grader?(user_id)
    !student_ids_to_anonymous_ids.key?(user_id.to_s) && user_id != @current_user.id
  end

  def avatars
    @avatars ||= service_enabled?(:avatars) && !@assignment.grade_as_group?
  end
end
