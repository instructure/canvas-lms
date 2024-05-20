# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class OutcomesController < ApplicationController
  include Api::V1::Outcome
  include Api::V1::Role

  before_action :require_context, except: [:build_outcomes]
  add_crumb(proc { t "#crumbs.outcomes", "Outcomes" }, except: [:destroy, :build_outcomes]) { |c| c.send :named_context_url, c.instance_variable_get(:@context), :context_outcomes_path }
  before_action { |c| c.active_tab = "outcomes" }
  before_action :rce_js_env, only: [:show, :index]

  include K5Mode

  def index
    return unless authorized_action(@context, @current_user, :read)
    return unless tab_enabled?(@context.class::TAB_OUTCOMES)

    log_asset_access(["outcomes", @context], "outcomes", "other")

    @root_outcome_group = @context.root_outcome_group

    js_env(
      ROOT_OUTCOME_GROUP: outcome_group_json(@root_outcome_group, @current_user, session),
      CONTEXT_URL_ROOT: polymorphic_path([@context]),
      ACCOUNT_CHAIN_URL: polymorphic_path([:api_v1, @context, :account_chain]),
      # Don't display state standards, global outcomes if in the context of a Course. Only at Account level.
      STATE_STANDARDS_URL: @context.is_a?(Course) ? nil : api_v1_global_redirect_path,
      GLOBAL_ROOT_OUTCOME_GROUP_ID:
        @context.is_a?(Course) ? nil : LearningOutcomeGroup.global_root_outcome_group.id,
      PERMISSIONS: {
        manage_outcomes: @context.grants_right?(@current_user, session, :manage_outcomes),
        manage_rubrics: @context.grants_right?(@current_user, session, :manage_rubrics),
        can_manage_courses: @context.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin),
        import_outcomes: @context.grants_right?(@current_user, session, :import_outcomes),
        manage_proficiency_scales:
          @context.grants_right?(@current_user, session, :manage_proficiency_scales),
        manage_proficiency_calculations:
          @context.grants_right?(@current_user, session, :manage_proficiency_calculations)
      },
      OUTCOMES_FRIENDLY_DESCRIPTION: Account.site_admin.feature_enabled?(:outcomes_friendly_description),
      OUTCOME_AVERAGE_CALCULATION: @context.root_account.feature_enabled?(:outcome_average_calculation),
      MENU_OPTION_FOR_OUTCOME_DETAILS_PAGE: Account.site_admin.feature_enabled?(:menu_option_for_outcome_details_page),
      OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION: @context.root_account.feature_enabled?(:outcomes_new_decaying_average_calculation),
      ARCHIVE_OUTCOMES: Account.site_admin.feature_enabled?(:archive_outcomes),
      PREVENT_DELETION_OUTCOMES_WITH_OS_ALIGNMENTS: Account.site_admin.feature_enabled?(:prevent_deletion_outcomes_with_os_alignments)
    )

    set_tutorial_js_env
    mastery_scales_js_env
    proficiency_roles_js_env
    improved_outcomes_management_js_env
  end

  def show
    if @context.respond_to?(:large_roster?) && @context.large_roster?
      flash[:notice] = t "#application.notices.page_disabled_for_course", "That page has been disabled for this course"
      redirect_to named_context_url(@context, :context_outcomes_path)
      return
    end

    @outcome = @context.linked_learning_outcomes.find(params[:id])
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    log_asset_access(@outcome, "outcomes", "outcomes")

    codes = [@context].map(&:asset_string)
    if @context.is_a?(Account)
      codes = if @context == @outcome.context
                "all"
              else
                @context.all_courses.pluck(:id).map { |id| "course_#{id}" }
              end
    end
    @alignments = @outcome.alignments.active.for_context(@context)
    add_crumb(@outcome.short_description, named_context_url(@context, :context_outcome_url, @outcome.id))
    @results = @outcome.learning_outcome_results.active.for_context_codes(codes).custom_ordering(params[:sort]).paginate(page: params[:page], per_page: 10)

    js_env({
             PERMISSIONS: {
               manage_outcomes: @context.grants_right?(@current_user, session, :manage_outcomes)
             }
           })
  end

  def details
    @outcome = @context.linked_learning_outcomes.find(params[:outcome_id])
    return unless authorized_action(@context, @current_user, :read)

    @outcome.tie_to(@context)
    render json: @outcome.as_json(
      methods: :artifacts_count_for_tied_context,
      user_content: %w[description]
    )
  end

  def outcome_results
    @outcome = @context.linked_learning_outcomes.find(params[:outcome_id])
    return unless authorized_action(@context, @current_user, :read)

    codes = [@context].map(&:asset_string)
    if @context.is_a?(Account)
      codes = if @context == @outcome.context
                "all"
              else
                @context.all_courses.pluck(:id).map { |id| "course_#{id}" }
              end
    end
    @results = @outcome.learning_outcome_results.active.for_context_codes(codes).custom_ordering(params[:sort])
    render json: Api.paginate(@results, self, polymorphic_url([@context, :outcome_results]))
  end

  def user_outcome_results
    user_id = params[:user_id]
    @user = case @context
            when User
              @context
            when Course
              @context.users.find(user_id)
            else
              @context.all_users.find_by!(id: user_id)
            end

    return unless authorized_action(@context, @current_user, :manage)

    @outcomes = if @user == @context
                  LearningOutcome.has_result_for(@user).active
                else
                  @context.available_outcomes
                end
    @results = LearningOutcomeResult.active.for_user(@user).for_outcome_ids(@outcomes.map(&:id)).order(assessed_at: :asc) # .for_context_codes(@codes)

    @results_for_outcome = @results.group_by(&:learning_outcome_id)

    @page_title = t :outcomes_for, "Outcomes for %{user_name}", user_name: @user.name

    css_bundle :learning_outcomes
    js_bundle :rubric_assessment

    render stream: can_stream_template?
  end

  def list
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    @account_contexts = @context.associated_accounts rescue []
    @current_outcomes = @context.linked_learning_outcomes
    @outcomes = Canvas::ICU.collate_by(@context.available_outcomes, &:title)
    if params[:unused]
      @outcomes -= @current_outcomes
    end
    render json: @outcomes.map { |o| o.as_json(methods: :cached_context_short_name) }
  end

  # as in, add existing outcome from another context to this context
  def add_outcome
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    @account_contexts = @context.associated_accounts.uniq rescue []
    codes = @account_contexts.map(&:asset_string)
    @outcome = LearningOutcome.for_context_codes(codes).find(params[:learning_outcome_id])
    @group = @context.learning_outcome_groups.find(params[:learning_outcome_group_id])
    # this is silly. there should be different actions for moving a link
    # (adopt_outcome_link) and adding a new link (add_outcome). as is, you
    # can't add a second link to the same outcome under a new group. but just
    # refactoring the model layer for now...
    if (outcome_link = @group.child_outcome_links.where(content_id: @outcome.id).first)
      @group.adopt_outcome_link(outcome_link)
    else
      @group.add_outcome(@outcome)
    end
    render json: @outcome.as_json(methods: :cached_context_short_name, permissions: { user: @current_user, session: })
  end

  def align
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    @outcome = @context.linked_learning_outcomes.find(params[:outcome_id])
    @asset = @context.find_asset(params[:asset_string])
    mastery_type = @asset.is_a?(Assignment) ? "points" : "none"
    @alignment = @outcome.align(@asset, @context, mastery_type:) if @asset
    render json: @alignment.as_json(include: :learning_outcome)
  end

  def alignment_redirect
    return unless authorized_action(@context, @current_user, :read)

    @outcome = @context.available_outcome(params[:outcome_id].to_i)
    @alignment = @outcome.alignments.find(params[:id])
    content_tag_redirect(@context, @alignment, :context_outcomes_url)
  end

  def remove_alignment
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    @outcome = @context.available_outcome(params[:outcome_id].to_i)
    @outcome.remove_alignment(params[:id], @context)
    render json: @alignment.as_json(include: :learning_outcome)
  end

  def outcome_result
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    @outcome = @context.linked_learning_outcomes.find(params[:outcome_id])
    @result = @outcome.learning_outcome_results.active.find(params[:id])

    return unless authorized_action(@result.context, @current_user, :manage_outcomes)

    if @result.artifact.is_a?(Submission)
      @submission = @result.artifact
      redirect_to named_context_url(@result.context, :context_assignment_submission_url, @submission.assignment_id, @submission.user_id)
    elsif @result.artifact.is_a?(RubricAssessment) && @result.artifact.artifact && @result.artifact.artifact.is_a?(Submission)
      @submission = @result.artifact.artifact
      redirect_to named_context_url(@result.context, :context_assignment_submission_url, @submission.assignment_id, @submission.user_id)
    elsif @result.artifact.is_a?(Quizzes::QuizSubmission) && @result.associated_asset
      @submission = @result.artifact
      @asset = @result.associated_asset
      @submission_version = if @submission.attempt <= @result.attempt
                              @submission
                            else
                              @submission.submitted_attempts.detect { |s| s.attempt >= @result.attempt }
                            end
      if @asset.is_a?(Quizzes::Quiz) && @result.alignment && @result.alignment.content_type == "AssessmentQuestionBank"
        # anchor to first question in aligned bank
        question_bank_id = @result.alignment.content_id
        first_aligned_question = Quizzes::QuizQuestion.where(quiz_id: @asset.id)
                                                      .joins(:assessment_question)
                                                      .where(assessment_questions: { assessment_question_bank_id: question_bank_id })
                                                      .order(:position).first
        anchor = first_aligned_question ? "question_#{first_aligned_question.id}" : nil
      elsif @asset.is_a? AssessmentQuestion
        question = @submission.quiz_data.detect { |q| q["assessment_question_id"] == @asset.data[:id] }
        question_id = (question && question["id"]) || @asset.data[:id]
        anchor = "question_#{question_id}"
      end
      redirect_to named_context_url(
        @result.context,
        :context_quiz_history_url,
        @submission.quiz_id,
        quiz_submission_id: @submission.id,
        version: @submission_version.version_number,
        anchor:
      )
    else
      flash[:error] = "Unrecognized artifact type: #{@result.try(:artifact_type) || "nil"}"
      redirect_to named_context_url(@context, :context_outcome_url, @outcome.id)
    end
  end

  def create
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    if params[:learning_outcome_group_id].present?
      @outcome_group = @context.learning_outcome_groups.find(params[:learning_outcome_group_id])
    end
    @outcome_group ||= @context.root_outcome_group
    @outcome = @context.created_learning_outcomes.build(learning_outcome_params)

    respond_to do |format|
      if @outcome.save
        @outcome_group.add_outcome(@outcome)
        flash[:notice] = t :successful_outcome_creation, "Outcome successfully created!"
        format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
        format.json { render json: @outcome }
      else
        flash[:error] = t :failed_outcome_creation, "Outcome creation failed"
        format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
        format.json { render json: @outcome.errors, status: :bad_request }
      end
    end
  end

  def update
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    @outcome = @context.created_learning_outcomes.find(params[:id])

    respond_to do |format|
      if @outcome.update(learning_outcome_params)
        flash[:notice] = t :successful_outcome_update, "Outcome successfully updated!"
        format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
        format.json { render json: @outcome }
      else
        flash[:error] = t :failed_outcome_update, "Outcome update failed"
        format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
        format.json { render json: @outcome.errors, statue: :bad_request }
      end
    end
  end

  def destroy
    return unless authorized_action(@context, @current_user, :manage_outcomes)

    respond_to do |format|
      # TODO: params[:id] is overloaded to be either a native outcome id or
      # the id of a link to a foreign outcome. therefore it's possible to
      # intend to delete a link to a foreign but accidentally delete a
      # completely unrelated native outcome. needs to be decoupled.
      if params[:id].present? && (@outcome = @context.created_learning_outcomes.where(id: params[:id]).first)
        @outcome.destroy
        flash[:notice] = t :successful_outcome_delete, "Outcome successfully deleted"
        format.json { render json: @outcome }
      elsif params[:id].present? && (@link = @context.learning_outcome_links.where(id: params[:id]).first)
        @link.destroy
        flash[:notice] = t :successful_outcome_removal, "Outcome successfully removed"
        format.json { render json: @link.learning_outcome }
      else
        flash[:notice] = t :missing_outcome, "Couldn't find that learning outcome"
        format.json { render json: { errors: { base: t(:missing_outcome, "Couldn't find that learning outcome") } }, status: :bad_request }
      end
      format.html { redirect_to named_context_url(@context, :context_outcomes_url) }
    end
  end

  protected

  def learning_outcome_params
    params.require(:learning_outcome).permit(:description, :short_description, :title, :display_name, :vendor_guid)
  end

  private

  def proficiency_roles_js_env
    if @context.is_a?(Account) && @context.root_account.feature_enabled?(:account_level_mastery_scales)
      proficiency_calculation_roles = []
      if @context.grants_right? @current_user, :manage_proficiency_calculations
        @context.roles_with_enabled_permission(:manage_proficiency_calculations).each do |role|
          proficiency_calculation_roles << role_json(@context, role, @current_user, session, skip_permissions: true)
        end
      end
      proficiency_scales_roles = []
      if @context.grants_right? @current_user, :manage_proficiency_scales
        @context.roles_with_enabled_permission(:manage_proficiency_scales).each do |role|
          proficiency_scales_roles << role_json(@context, role, @current_user, session, skip_permissions: true)
        end
      end
      js_env(
        PROFICIENCY_CALCULATION_METHOD_ENABLED_ROLES: proficiency_calculation_roles,
        PROFICIENCY_SCALES_ENABLED_ROLES: proficiency_scales_roles
      )
    end
  end
end
