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

class Quizzes::QuizzesController < ApplicationController
  include Api::V1::Quiz
  include Api::V1::QuizzesNext::Quiz
  include Api::V1::AssignmentOverride
  include KalturaHelper
  include ::Filters::Quizzes
  include SubmittablesGradingPeriodProtection
  include QuizMathDataFixup

  # If Quiz#one_time_results is on, this flag must be set whenever we've
  # rendered the submission results to the student so that the results can be
  # locked down.
  attr_reader :lock_results_if_needed

  before_action :require_context
  before_action :rce_js_env, only: %i[show new edit]

  include K5Mode

  add_crumb(proc { t("#crumbs.quizzes", "Quizzes") }) { |c| c.send :named_context_url, c.instance_variable_get(:@context), :context_quizzes_url }
  before_action { |c| c.active_tab = "quizzes" }
  before_action :require_quiz, only: %i[
    statistics
    edit
    show
    history
    update
    destroy
    moderate
    read_only
    managed_quiz_data
    submission_versions
    submission_html
  ]
  before_action :set_download_submission_dialog_title, only: [:show, :statistics]
  after_action :lock_results, only: [:show, :submission_html]
  # The number of questions that can display "details". After this number, the "Show details" option is disabled
  # and the data is not even loaded.
  QUIZ_QUESTIONS_DETAIL_LIMIT = 25
  QUIZ_MAX_COMBINATION_COUNT = 200

  QUIZ_TYPE_ASSIGNMENT = "assignment"
  QUIZ_TYPE_PRACTICE = "practice_quiz"
  QUIZ_TYPE_SURVEYS = ["survey", "graded_survey"].freeze

  def index
    GuardRail.activate(:secondary) do
      return unless authorized_action(@context, @current_user, :read)
      return unless tab_enabled?(@context.class::TAB_QUIZZES)

      can_manage = @context.grants_any_right?(@current_user, session, :manage_assignments, :manage_assignments_edit)

      quiz_index = scoped_quizzes_index
      quiz_index += scoped_new_quizzes_index if quiz_lti_enabled?

      quiz_options = Rails.cache.fetch(
        [
          "quiz_user_permissions",
          @context.id,
          @current_user,
          quiz_index.map(&:id), # invalidate on add/delete of quizzes
          quiz_index.map(&:updated_at).max # invalidate on modifications
        ].cache_key
      ) do
        if can_manage
          Quizzes::Quiz.preload_can_unpublish(scoped_quizzes_index)
        end
        quiz_index.each_with_object({}) do |quiz, quiz_user_permissions|
          quiz_user_permissions[quiz.id] = {
            can_update: can_manage,
            can_unpublish: can_manage && quiz.can_unpublish?
          }
        end
      end

      practice_quizzes   = scoped_quizzes_index.select { |q| q.quiz_type == QUIZ_TYPE_PRACTICE }
      surveys            = scoped_quizzes_index.select { |q| QUIZ_TYPE_SURVEYS.include?(q.quiz_type) }
      if scoped_new_quizzes_index.any? && @context.grants_any_right?(@current_user, session, *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS)
        mc_status = setup_master_course_restrictions(scoped_new_quizzes_index, @context)
      end
      serializer_options = [@context,
                            @current_user,
                            session,
                            {
                              permissions: quiz_options,
                              master_course_status: mc_status,
                              skip_date_overrides: true,
                              skip_lock_tests: true
                            }]
      max_name_length = AssignmentUtil.assignment_max_name_length(@context)
      sis_name = AssignmentUtil.post_to_sis_friendly_name(@context)
      due_date_required_for_account = AssignmentUtil.due_date_required_for_account?(@context)
      max_name_length_required_for_account = AssignmentUtil.name_length_required_for_account?(@context)
      sis_integration_settings_enabled = AssignmentUtil.sis_integration_settings_enabled?(@context)

      hash = {
        QUIZZES: {
          assignment: assignment_quizzes_json(serializer_options),
          open: quizzes_json(practice_quizzes, *serializer_options),
          surveys: quizzes_json(surveys, *serializer_options),
          options: quiz_options
        },
        URLS: {
          new_assignment_url: new_polymorphic_url([@context, :assignment]),
          new_quiz_url: context_url(@context, :context_quizzes_new_url, fresh: 1),
          new_quizzes_selection: api_v1_course_new_quizzes_selection_update_url(@context),
          question_banks_url: context_url(@context, :context_question_banks_url),
          assignment_overrides: api_v1_course_quiz_assignment_overrides_url(@context),
          new_quizzes_assignment_overrides: api_v1_course_new_quizzes_assignment_overrides_url(@context)
        },
        PERMISSIONS: {
          create: can_do(@context.quizzes.temp_record, @current_user, :create),
          manage: can_manage,
          read_question_banks: can_manage || can_do(@context, @current_user, :read_question_banks)
        },
        FLAGS: {
          question_banks: feature_enabled?(:question_banks),
          post_to_sis_enabled: Assignment.sis_grade_export_enabled?(@context),
          quiz_lti_enabled: quiz_lti_on_quizzes_page?,
          migrate_quiz_enabled: quiz_lti_enabled?,
          show_additional_speed_grader_link: Account.site_admin.feature_enabled?(:additional_speedgrader_links),
          # TODO: remove this since it's set in application controller
          # Will need to update consumers of this in the UI to bring down
          # this permissions check as well
          DIRECT_SHARE_ENABLED: @context.grants_right?(@current_user, session, :direct_share)
        },
        quiz_menu_tools: external_tools_display_hashes(:quiz_menu),
        quiz_index_menu_tools: external_tools_display_hashes(:quiz_index_menu),
        SIS_NAME: sis_name,
        MAX_NAME_LENGTH: max_name_length,
        DUE_DATE_REQUIRED_FOR_ACCOUNT: due_date_required_for_account,
        MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT: max_name_length_required_for_account,
        SIS_INTEGRATION_SETTINGS_ENABLED: sis_integration_settings_enabled,
        NEW_QUIZZES_SELECTED: quiz_engine_selection,
        SHOW_SPEED_GRADER_LINK: @current_user.present? && context.allows_speed_grader? && context.grants_any_right?(@current_user, :manage_grades, :view_all_grades),
      }
      if @context.is_a?(Course) && @context.grants_right?(@current_user, session, :read)
        hash[:COURSE_ID] = @context.id.to_s
      end
      js_env(hash)

      set_tutorial_js_env

      conditional_release_js_env(includes: :active_rules)
    end

    if @current_user.present?
      Quizzes::OutstandingQuizSubmissionManager.delay_if_production
                                               .grade_by_course(@context)
    end

    log_asset_access(["quizzes", @context], "quizzes", "other")
  end

  def show
    if @quiz.deleted?
      flash[:error] = t("errors.quiz_deleted", "That quiz has been deleted")
      redirect_to named_context_url(@context, :context_quizzes_url)
      return
    end

    if authorized_action(@quiz, @current_user, :read)
      # optionally force auth even for public courses
      return if value_to_boolean(params[:force_user]) && !force_user

      if @current_user && !@quiz.visible_to_user?(@current_user)
        if @current_user.quiz_submissions.where(quiz_id: @quiz).any?
          flash[:notice] = t "notices.submission_doesnt_count", "This quiz will no longer count towards your grade."
        else
          respond_to do |format|
            flash[:error] = t "You do not have access to the requested quiz."
            format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
          end
          return
        end
      end

      @quiz = @quiz.overridden_for(@current_user)
      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))

      setup_headless

      return if (@quiz.require_lockdown_browser? &
                @quiz.require_lockdown_browser_for_results?) &&
                params[:viewing] &&
                !check_lockdown_browser(:medium, named_context_url(@context, "context_quiz_url", @quiz.to_param, viewing: "1"))

      if @quiz.require_lockdown_browser? && value_to_boolean(params.delete(:refresh_ldb))
        return render(action: "refresh_quiz_after_popup")
      end

      @question_count = @quiz.question_count
      if session[:quiz_id] == @quiz.id && !request.xhr?
        session.delete(:quiz_id)
      end
      is_observer = @context_enrollment&.observer?
      @locked_reason = @quiz.locked_for?(@current_user, check_policies: true, deep_check_if_needed: true, is_observer:)
      @locked = @locked_reason && !can_preview?

      @context_module_tag = ContextModuleItem.find_tag_with_preferred([@quiz, @quiz.assignment], params[:module_item_id])
      @sequence_asset = @context_module_tag.try(:content)
      GuardRail.activate(:primary) do
        @quiz.context_module_action(@current_user, :read) unless @locked && !@locked_reason[:can_view]
      end
      @assignment = @quiz.assignment
      @assignment = @assignment.overridden_for(@current_user) if @assignment

      @submission = get_submission

      @just_graded = false
      if @submission&.needs_grading?(!!params[:take])
        GuardRail.activate(:primary) do
          Quizzes::SubmissionGrader.new(@submission).grade_submission(
            finished_at: @submission.finished_at_fallback
          )
          @submission.reload
          @just_graded = true
        end
      end
      if @submission
        upload_url = api_v1_quiz_submission_files_path(course_id: @context.id, quiz_id: @quiz.id)
        js_env UPLOAD_URL: upload_url
        js_env SUBMISSION_VERSIONS_URL: course_quiz_submission_versions_url(@context, @quiz) unless hide_quiz?
        if !@submission.preview? && (!@js_env || !@js_env[:QUIZ_SUBMISSION_EVENTS_URL])
          events_url = api_v1_course_quiz_submission_events_url(@context, @quiz, @submission)
          js_env QUIZ_SUBMISSION_EVENTS_URL: events_url
        end
      end

      setup_attachments
      submission_counts if @quiz.grants_right?(@current_user, session, :grade) || @quiz.grants_right?(@current_user, session, :read_statistics)
      @stored_params = (@submission.temporary_data rescue nil) if params[:take] && @submission && (@submission.untaken? || @submission.preview?)
      @stored_params ||= {}
      hash = {
        ATTACHMENTS: @attachments.to_h { |_, a| [a.id, attachment_hash(a)] },
        CONTEXT_ACTION_SOURCE: :quizzes,
        COURSE_ID: @context.id,
        LOCKDOWN_BROWSER: @quiz.require_lockdown_browser?,
        QUIZ: quiz_json(@quiz, @context, @current_user, session),
        QUIZ_DETAILS_URL: course_quiz_managed_quiz_data_url(@context.id, @quiz.id),
        QUIZZES_URL: course_quizzes_url(@context),
        MAX_GROUP_CONVERSATION_SIZE: Conversation.max_group_conversation_size
      }

      append_sis_data(hash)
      js_env(hash)
      conditional_release_js_env(@quiz.assignment, includes: [:rule])

      set_master_course_js_env_data(@quiz, @context)
      @quiz_menu_tools = external_tools_display_hashes(:quiz_menu)
      @can_take = can_take_quiz?
      GuardRail.activate(:primary) do
        if params[:take] && @can_take
          return false if @quiz.require_lockdown_browser? && !check_lockdown_browser(:highest, named_context_url(@context, "context_quiz_take_url", @quiz.id))

          # allow starting the quiz via a GET request, but only when using a lockdown browser
          if request.post? || (@quiz.require_lockdown_browser? && !quiz_submission_active?)
            start_quiz!
          else
            take_quiz
          end
        else
          @lock_results_if_needed = true

          log_asset_access(@quiz, "quizzes", "quizzes")
          js_bundle :quiz_show
          css_bundle :quizzes, :learning_outcomes
          if params[:take] && @quiz_eligibility && @quiz_eligibility.declined_reason_renders
            return render @quiz_eligibility.declined_reason_renders
          end

          render stream: can_stream_template?
        end
      end
      @padless = true
    end
  end

  def new
    if authorized_action(@context.quizzes.temp_record, @current_user, :create)
      quiz = @context.quizzes.build
      title = params[:title] || params[:name]
      quiz.title = title if title
      quiz.due_at = params[:due_at] if params[:due_at]
      quiz.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]
      quiz.save!

      quiz_edit_url = named_context_url(@context, :edit_context_quiz_url, quiz)
      return render json: { url: quiz_edit_url } if request.xhr?

      redirect_to(quiz_edit_url)
    end
  end

  def edit
    if authorized_action(@quiz, @current_user, :update)

      if params[:fixup_quiz_math_questions] == "1"
        InstStatsd::Statsd.increment("fixingup_quiz_math_question")
        @quiz = fixup_quiz_questions_with_bad_math(@quiz)
      end

      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
      @assignment = @quiz.assignment
      @quiz.title = params[:title] if params[:title]
      @quiz.due_at = params[:due_at] if params[:due_at]
      @quiz.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]

      @banks_hash = get_banks(@quiz)

      if (@has_student_submissions = @quiz.has_student_submissions?)
        flash[:notice] = t("notices.has_submissions_already", "Keep in mind, some students have already taken or started taking this quiz")
      end

      regrade_options = @quiz.current_quiz_question_regrades.to_h do |qqr|
        [qqr.quiz_question_id, qqr.regrade_option]
      end
      sections = @context.course_sections.active

      max_name_length_required_for_account = AssignmentUtil.name_length_required_for_account?(@context)
      max_name_length = AssignmentUtil.assignment_max_name_length(@context)

      hash = {
        ASSIGNMENT_ID: @assignment.present? ? @assignment.id : nil,
        ASSIGNMENT_OVERRIDES: assignment_overrides_json(@quiz.overrides_for(@current_user,
                                                                            ensure_set_not_empty: true),
                                                        @current_user,
                                                        include_names: true),
        DUE_DATE_REQUIRED_FOR_ACCOUNT: AssignmentUtil.due_date_required_for_account?(@context),
        QUIZ: quiz_json(@quiz, @context, @current_user, session),
        SECTION_LIST: sections.map do |section|
          {
            id: section.id,
            name: section.name,
            start_at: section.start_at,
            end_at: section.end_at,
            override_course_and_term_dates: section.restrict_enrollments_to_section_dates
          }
        end,
        QUIZZES_URL: course_quizzes_url(@context),
        QUIZ_IP_FILTERS_URL: api_v1_course_quiz_ip_filters_url(@context, @quiz),
        CONTEXT_ACTION_SOURCE: :quizzes,
        REGRADE_OPTIONS: regrade_options,
        quiz_max_combination_count: QUIZ_MAX_COMBINATION_COUNT,
        SHOW_QUIZ_ALT_TEXT_WARNING: true,
        VALID_DATE_RANGE: CourseDateRange.new(@context),
        HAS_GRADING_PERIODS: @context.grading_periods?,
        MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT: max_name_length_required_for_account,
        MAX_NAME_LENGTH: max_name_length,
        IS_MODULE_ITEM: @quiz.is_module_item?
      }

      if @context.grading_periods?
        hash[:active_grading_periods] = GradingPeriod.json_for(@context, @current_user)
      end

      if @context.is_a?(Course) && @context.grants_right?(@current_user, session, :read)
        hash[:COURSE_ID] = @context.id.to_s
      end

      append_sis_data(hash)
      append_default_due_time_js_env(@context, hash)
      js_env(hash)

      conditional_release_js_env(@quiz.assignment)
      set_master_course_js_env_data(@quiz, @context)

      js_bundle :quizzes
      css_bundle :quizzes, :tinymce, :conditional_release_editor
      render :new, stream: can_stream_template?
    end
  end

  def create
    if authorized_action(@context.quizzes.temp_record, @current_user, :create)
      @quiz = @context.quizzes.build

      return render_forbidden unless grading_periods_allow_submittable_create?(@quiz, params[:quiz])

      overrides = delete_override_params

      return render_forbidden if overrides && !grading_periods_allow_assignment_overrides_batch_create?(@quiz, overrides)

      quiz_params = get_quiz_params
      quiz_params[:title] = nil if quiz_params[:title] == "undefined"
      quiz_params[:title] ||= t(:default_title, "New Quiz")
      quiz_params[:description] = process_incoming_html_content(quiz_params[:description]) if quiz_params.key?(:description)
      quiz_params.delete(:points_possible) unless quiz_params[:quiz_type] == "graded_survey"
      quiz_params[:disable_timer_autosubmission] = false if quiz_params[:time_limit].blank?
      quiz_params[:access_code] = nil if quiz_params[:access_code] == ""
      if quiz_params[:quiz_type] == "assignment" || quiz_params[:quiz_type] == "graded_survey"
        quiz_params[:assignment_group_id] ||= @context.assignment_groups.first.id
        if (assignment_group_id = quiz_params.delete(:assignment_group_id)) && assignment_group_id.present?
          @assignment_group = @context.assignment_groups.active.where(id: assignment_group_id).first
        end
        if @assignment_group
          @assignment = @context.assignments.build(title: quiz_params[:title], due_at: quiz_params[:lock_at], submission_types: "online_quiz")
          @assignment.assignment_group = @assignment_group
          @assignment.saved_by = :quiz
          @assignment.workflow_state = "unpublished"
          @assignment.save
          quiz_params[:assignment_id] = @assignment.id
        end
        quiz_params[:assignment_id] = nil unless @assignment
        quiz_params[:title] = @assignment.title if @assignment
      end
      @quiz.content_being_saved_by(@current_user)
      @quiz.infer_times
      @quiz.transaction do
        @quiz.update!(quiz_params)
        batch_update_assignment_overrides(@quiz, overrides, @current_user) unless overrides.nil?
      end

      if params[:post_to_sis]
        @quiz.assignment.post_to_sis = params[:post_to_sis] == "1"
      end

      if params.include?(:important_dates)
        @quiz.assignment.important_dates = value_to_boolean(params[:important_dates])
      end

      @quiz.did_edit if @quiz.created?
      @quiz.reload
      render json: @quiz.as_json(include: { assignment: { include: :assignment_group } })
    end
  rescue
    render json: @quiz.errors, status: :bad_request
  end

  def update
    if authorized_action(@quiz, @current_user, :update)
      quiz_params = get_quiz_params
      params[:quiz] ||= {}

      return render_forbidden unless grading_periods_allow_submittable_update?(
        @quiz, quiz_params, flash_message: true
      )

      overrides = delete_override_params

      if overrides
        prepared_batch = prepare_assignment_overrides_for_batch_update(@quiz, overrides, @current_user)
        batch_update_allowed = grading_periods_allow_assignment_overrides_batch_update?(
          @quiz, prepared_batch, flash_message: true
        )
        return render_forbidden unless batch_update_allowed
      end

      quiz_params[:title] = t("New Quiz") if quiz_params[:title] == "undefined"
      quiz_params[:description] = process_incoming_html_content(quiz_params[:description]) if quiz_params.key?(:description)

      if quiz_params[:quiz_type] == "survey"
        quiz_params[:points_possible] = ""
      elsif quiz_params[:quiz_type] != "graded_survey"
        quiz_params.delete(:points_possible)
      end
      quiz_params[:disable_timer_autosubmission] = false if quiz_params[:time_limit].blank?
      quiz_params[:access_code] = nil if quiz_params[:access_code] == ""
      if quiz_params[:quiz_type] == "assignment" || quiz_params[:quiz_type] == "graded_survey" # 'new' && params[:quiz][:assignment_group_id]
        if (assignment_group_id = quiz_params.delete(:assignment_group_id)) && assignment_group_id.present?
          @assignment_group = @context.assignment_groups.active.where(id: assignment_group_id).first
        end
        @assignment_group ||= @context.assignment_groups.first
        # The code to build an assignment for a quiz used to be here, but it's
        # been moved to the model quiz.rb instead.  See Quiz:build_assignment.
        quiz_params[:assignment_group_id] = @assignment_group && @assignment_group.id
      end

      quiz_params[:lock_at] = nil if quiz_params.delete(:do_lock_at) == "false"
      created_quiz = @quiz.created?

      Assignment.suspend_due_date_caching do
        @quiz.with_versioning(false) do
          @quiz.did_edit if @quiz.created?
        end
      end

      cached_due_dates_changed = @quiz.update_cached_due_dates?(quiz_params[:quiz_type])

      # TODO: API for Quiz overrides!
      respond_to do |format|
        Assignment.suspend_due_date_caching do
          @quiz.transaction do
            notify_of_update = value_to_boolean(params[:quiz][:notify_of_update])

            old_assignment = nil
            if @quiz.assignment.present?
              old_assignment = @quiz.assignment.clone
              old_assignment.id = @quiz.assignment.id

              @quiz.assignment.post_to_sis = params[:post_to_sis] == "1"
              @quiz.assignment.validate_overrides_for_sis(overrides) unless overrides.nil?

              @quiz.assignment.important_dates = value_to_boolean(params[:important_dates])
            end

            auto_publish = @quiz.published?

            @quiz.with_versioning(auto_publish) do
              # using attributes= here so we don't need to make an extra
              # database call to get the times right after save!
              @quiz.attributes = quiz_params
              @quiz.infer_times
              @quiz.content_being_saved_by(@current_user)
              if auto_publish
                @quiz.generate_quiz_data
                @quiz.workflow_state = "available"
                @quiz.published_at = Time.now
              end
              @quiz.save!
            end

            if old_assignment && @quiz.assignment.present?
              @quiz.assignment.save
            end

            unless overrides.nil?
              update_quiz_and_assignment_versions(@quiz, prepared_batch) # to prevent undoing Quiz#link_assignment_overrides
              perform_batch_update_assignment_overrides(@quiz, prepared_batch)
            end

            # quiz.rb restricts all assignment broadcasts if notify_of_update is
            # false, so we do the same here
            if @quiz.assignment.present? && old_assignment && (notify_of_update || old_assignment.due_at != @quiz.assignment.due_at)
              @quiz.assignment.do_notifications!(old_assignment, notify_of_update)
            end
            @quiz.reload

            if params[:quiz][:time_limit].present?
              @quiz.delay_if_production(priority: Delayed::HIGH_PRIORITY).update_quiz_submission_end_at_times
            end

            @quiz.publish! if params[:publish]
          end
        end

        if @quiz.assignment && (@overrides_affected.to_i > 0 || cached_due_dates_changed || created_quiz)
          @quiz.assignment.clear_cache_key(:availability)
          SubmissionLifecycleManager.recompute(@quiz.assignment, update_grades: true, executing_user: @current_user)
        end

        flash[:notice] = t("Quiz successfully updated")
        format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz) }
        format.json { render json: @quiz.as_json(include: { assignment: { include: :assignment_group } }) }
      end
    end
  rescue
    respond_to do |format|
      flash[:error] = t("Quiz failed to update")
      format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz) }
      format.json { render json: @quiz.errors, status: :bad_request }
    end
  end

  def destroy
    if authorized_action(@quiz, @current_user, :delete)
      return render_unauthorized_action if editing_restricted?(@quiz)

      respond_to do |format|
        if @quiz.destroy
          format.html { redirect_to course_quizzes_url(@context) }
          format.json { render json: @quiz }
        else
          format.html { redirect_to course_quiz_url(@context, @quiz) }
          format.json { render json: @quiz.errors }
        end
      end
    end
  end

  def publish
    if authorized_action(@context, @current_user, [:manage_assignments, :manage_assignments_edit])
      @quizzes = @context.quizzes.active.where(id: params[:quizzes])
      @quizzes.each(&:publish!)

      flash[:notice] = t("notices.quizzes_published",
                         { one: "1 quiz successfully published!",
                           other: "%{count} quizzes successfully published!" },
                         count: @quizzes.length)

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render json: {}, status: :ok }
      end
    end
  end

  def unpublish
    if authorized_action(@context, @current_user, [:manage_assignments, :manage_assignments_edit])
      @quizzes = @context.quizzes.active.where(id: params[:quizzes]).select(&:available?)
      @quizzes.each(&:unpublish!)

      flash[:notice] = t("notices.quizzes_unpublished",
                         { one: "1 quiz successfully unpublished!",
                           other: "%{count} quizzes successfully unpublished!" },
                         count: @quizzes.length)

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render json: {}, status: :ok }
      end
    end
  end

  # student_analysis report
  def statistics
    if authorized_action(@quiz, @current_user, :read_statistics)
      respond_to do |format|
        format.html do
          add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
          add_crumb(t(:statistics_crumb, "Statistics"), named_context_url(@context, :context_quiz_statistics_url, @quiz))

          js_env({
                   quiz_url: api_v1_course_quiz_url(@context, @quiz),
                   quiz_statistics_url: api_v1_course_quiz_statistics_url(@context, @quiz),
                   course_sections_url: api_v1_course_sections_url(@context),
                   quiz_reports_url: api_v1_course_quiz_reports_url(@context, @quiz),
                 })

          render :statistics_cqs
        end
      end
    end
  end

  def managed_quiz_data
    extend Api::V1::User
    if authorized_action(@quiz, @current_user, [:grade, :read_statistics])
      student_scope = @context.students_visible_to(@current_user, include: :inactive)
      if @quiz.differentiated_assignments_applies?
        student_scope = student_scope.able_to_see_quiz_in_course_with_da(@quiz.id, @context.id)
      end
      students = student_scope.order_by_sortable_name.to_a.uniq

      @submissions_from_users = @quiz.quiz_submissions.for_user_ids(students.map(&:id)).not_settings_only.to_a

      @submissions_from_users = @submissions_from_users.index_by(&:user_id)

      # include logged out submissions
      @submissions_from_logged_out = @quiz.quiz_submissions.logged_out.not_settings_only

      @submitted_students, @unsubmitted_students = students.partition do |stud|
        @submissions_from_users[stud.id]
      end

      if @quiz.anonymous_survey?
        @submitted_students = @submitted_students.sort_by do |student|
          @submissions_from_users[student.id].id
        end

        submitted_students_json = @submitted_students.map(&:id)
        unsubmitted_students_json = @unsubmitted_students.map(&:id)
      else
        submitted_students_json = @submitted_students.map { |u| user_json(u, @current_user, session) }
        unsubmitted_students_json = @unsubmitted_students.map { |u| user_json(u, @current_user, session) }
      end

      @quiz_submission_list = { UNSUBMITTED_STUDENTS: unsubmitted_students_json,
                                SUBMITTED_STUDENTS: submitted_students_json }.to_json
      render layout: false
    end
  end

  def lockdown_browser_required
    plugin = Canvas::LockdownBrowser.plugin
    if plugin
      @lockdown_browser_download_url = plugin.settings[:download_url]
    end
    render
  end

  def history
    if authorized_action(@context, @current_user, :read)
      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
      if params[:quiz_submission_id]
        @submission = @quiz.quiz_submissions.find(params[:quiz_submission_id])
      else
        user_id = params[:user_id].presence || @current_user&.id
        @submission = @quiz.quiz_submissions.where(user_id:).order(:created_at).first
      end
      if @submission && !@submission.user_id && (logged_out_index = params[:u_index])
        @logged_out_user_index = logged_out_index
      end
      @submission = nil if @submission&.settings_only?
      @user = @submission&.user
      if @submission&.needs_grading?
        Quizzes::SubmissionGrader.new(@submission).grade_submission(
          finished_at: @submission.finished_at_fallback
        )
        @submission.reload
      end
      setup_attachments
      if @quiz.deleted?
        flash[:error] = t("errors.quiz_deleted", "That quiz has been deleted")
        redirect_to named_context_url(@context, :context_quizzes_url)
        return
      end
      unless @submission
        flash[:notice] = t("notices.no_submission_for_user", "There is no submission available for that user")
        redirect_to named_context_url(@context, :context_quiz_url, @quiz)
        return
      end
      if hide_quiz? && !@quiz.grants_right?(@current_user, session, :review_grades)
        flash[:notice] = t("notices.cant_view_submission_while_muted", "You cannot view the quiz history while the quiz is muted.")
        redirect_to named_context_url(@context, :context_quiz_url, @quiz)
        return
      end
      if params[:score_updated]
        js_env SCORE_UPDATED: true
      end
      js_env GRADE_BY_QUESTION: @current_user&.preferences&.dig(:enable_speedgrader_grade_by_question)
      if authorized_action(@submission, @current_user, :read)
        if @current_user && !@quiz.visible_to_user?(@current_user)
          flash[:notice] = t "notices.submission_doesnt_count", "This quiz will no longer count towards your grade."
        end
        dont_show_user_name = @submission.quiz.anonymous_submissions || (!@submission.user || @submission.user == @current_user)
        add_crumb((dont_show_user_name ? t(:default_history_crumb, "History") : @submission.user.name))
        @headers = !params[:headless]
        unless @headers
          @body_classes << "quizzes-speedgrader"
        end
        @current_submission = @submission
        @version_instances = @submission.submitted_attempts.sort_by(&:version_number)
        @versions = get_versions
        params[:version] ||= @version_instances[0].version_number if @submission.untaken? && !@version_instances.empty?
        @current_version = true
        @version_number = "current"
        if params[:version]
          @version_number = params[:version].to_i
          @unversioned_submission = @submission
          @submission = @versions.detect { |s| s.version_number >= @version_number }
          @submission ||= @unversioned_submission.versions.get(params[:version]).model
          @current_version = (@current_submission.version_number == @submission.version_number)
          @version_number = "current" if @current_version
        end
        if @submission&.user_id == @current_user.id
          @submission&.submission&.mark_read(@current_user)
        end

        log_asset_access(@quiz, "quizzes", "quizzes")

        return if @quiz.require_lockdown_browser? &&
                  @quiz.require_lockdown_browser_for_results? &&
                  params[:viewing] &&
                  !check_lockdown_browser(:medium, named_context_url(@context, "context_quiz_history_url", @quiz.to_param, viewing: "1", version: params[:version]))

        js_bundle :quiz_history
        render stream: can_stream_template?
      end
    end
  end

  def moderate
    if authorized_action(@quiz, @current_user, :grade)
      @students = @context.students_visible_to(@current_user)
      @students = @quiz.visible_students_with_da(@students)
      @students = @students.name_like(params[:search_term]) if params[:search_term].present?
      @students = @students.distinct.order_by_sortable_name
      @students = @students.order(:uuid) if @quiz.survey? && @quiz.anonymous_submissions
      last_updated_at = Time.parse(params[:last_updated_at]) rescue nil
      respond_to do |format|
        format.html do
          @students = @students.paginate(page: params[:page], per_page: 50)
          @submissions = @quiz.quiz_submissions.updated_after(last_updated_at).for_user_ids(@students.map(&:id))
        end
        format.json do
          @students = Api.paginate(@students, self, course_quiz_moderate_url(@context, @quiz), default_per_page: 50)
          @submissions = @quiz.quiz_submissions.updated_after(last_updated_at).for_user_ids(@students.map(&:id))
          render json: @submissions.map { |s| s.as_json(include_root: false, except: [:submission_data, :quiz_data], methods: ["extendable?", :finished_in_words, :attempts_left]) }
        end
      end
    end
  end

  def submission_versions
    if authorized_action(@quiz, @current_user, :read)
      @submission = get_submission
      @versions   = @submission ? get_versions : []

      if !@versions.empty? && !hide_quiz?
        render layout: false
      else
        head :ok
      end
    end
  end

  def read_only
    @assignment = @quiz.assignment
    if authorized_action(@quiz, @current_user, :read_statistics)
      @banks_hash = get_banks(@quiz)

      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
      js_env(quiz_max_combination_count: QUIZ_MAX_COMBINATION_COUNT)
      render
    end
  end

  def submission_html
    @submission = get_submission
    setup_attachments
    if @submission&.completed?
      @lock_results_if_needed = true
      render layout: false
    else
      head :ok
    end
  end

  private

  def can_preview?
    @quiz.grants_right?(@current_user, session, :preview)
  end

  def get_banks(quiz)
    banks_hash = {}
    bank_ids = quiz.quiz_groups.map(&:assessment_question_bank_id)
    unless bank_ids.empty?
      banks_hash = AssessmentQuestionBank.active.where(id: bank_ids).index_by(&:id)
    end
    banks_hash
  end

  def get_submission
    submission = @quiz.quiz_submissions.where(user_id: @current_user).order(:created_at).first if @current_user
    if !@current_user || (params[:preview] && can_preview?)
      user_code = temporary_user_code
      submission = @quiz.quiz_submissions.where(temporary_user_code: user_code).first
    end

    if submission
      submission.ensure_question_reference_integrity!
      submission.ensure_end_at_integrity!
    end

    submission
  end

  def get_versions
    @submission.submitted_attempts
  end

  def setup_attachments
    @attachments = if @submission
                     @submission.attachments.index_by(&:id)

                   else
                     {}
                   end
  end

  def attachment_hash(attachment)
    { id: attachment.id, display_name: attachment.display_name }
  end

  def delete_override_params
    # nil represents the fact that we don't want to update the overrides
    return nil unless params[:quiz].key?(:assignment_overrides)

    overrides = params[:quiz].delete(:assignment_overrides)
    overrides = deserialize_overrides(overrides)

    # overrides might be "false" to indicate no overrides through form params
    overrides.is_a?(Array) ? overrides : []
  end

  def force_user
    unless @current_user
      session[:return_to] = course_quiz_path(@context, @quiz)
      redirect_to login_path
    end
    @current_user.present?
  end

  def setup_headless
    # persist headless state through take button and next/prev questions
    session[:headless_quiz] = true if value_to_boolean(params[:persist_headless])
    @headers = !params[:headless] && !session[:headless_quiz]
  end

  # if this returns false, it's rendering or redirecting, so return from the
  # action that called it
  def check_lockdown_browser(security_level, redirect_return_url)
    return true if @quiz.grants_right?(@current_user, session, :grade)

    plugin = Canvas::LockdownBrowser.plugin.base
    if plugin.require_authorization_redirect?(self)
      redirect_to(plugin.redirect_url(self, redirect_return_url))
      return false
    elsif !plugin.authorized?(self)
      redirect_to(action: "lockdown_browser_required", quiz_id: @quiz.id)
      return false
    elsif !session["lockdown_browser_popup"] && (@query_params = plugin.popup_window(self, security_level))
      @security_level = security_level
      session["lockdown_browser_popup"] = true
      render(action: "take_quiz_in_popup")
      return false
    end
    @lockdown_browser_authorized_to_view = true
    @headers = false
    @show_left_side = false
    @padless = true
    true
  end

  # use this for all redirects while taking a quiz -- it'll add params to tell
  # the lockdown browser that it's ok to follow the redirect
  def quiz_redirect_params(opts = {})
    return opts if !@quiz.require_lockdown_browser? || @quiz.grants_right?(@current_user, session, :grade)

    plugin = Canvas::LockdownBrowser.plugin.base
    plugin.redirect_params(opts)
  end
  helper_method :quiz_redirect_params

  def start_quiz!
    can_retry = @submission && (@quiz.unlimited_attempts? || @submission.attempts_left > 0 || can_preview?)
    preview = params[:preview] && can_preview?
    if !@submission || @submission.settings_only? || (@submission.completed? && can_retry && !@just_graded) || preview
      user_code = @current_user
      user_code = nil if preview
      user_code ||= temporary_user_code
      @submission = @quiz.generate_submission(user_code, !!preview)
      log_asset_access(@quiz, "quizzes", "quizzes", "participate")
    end
    if quiz_submission_active?
      if request.get?
        # currently, the only way to start_quiz! with a get request is to use the LDB
        take_quiz
      else
        # redirect to avoid refresh issues
        redirect_to course_quiz_take_url(@context, @quiz, quiz_redirect_params(preview: params[:preview]))
      end
    else
      flash[:error] = t("errors.no_more_attempts", "You have no quiz attempts left") unless @just_graded
      redirect_to named_context_url(@context, :context_quiz_url, @quiz, quiz_redirect_params)
    end
  end

  def take_quiz
    return unless quiz_submission_active?

    @show_embedded_chat = false
    flash[:notice] = t("notices.less_than_allotted_time", "You started this quiz near when it was due, so you won't have the full amount of time to take the quiz.") if @submission.less_than_allotted_time?
    if params[:question_id] && !valid_question?(@submission, params[:question_id])
      redirect_to course_quiz_url(@context, @quiz) and return
    end

    if params[:fixup_quiz_math_questions] == "1"
      InstStatsd::Statsd.increment("fixingup_quiz_math_submission")
      fixup_submission_questions_with_bad_math(@submission)
    end

    if !@submission.preview? && (!@js_env || !@js_env[:QUIZ_SUBMISSION_EVENTS_URL])
      events_url = api_v1_course_quiz_submission_events_url(@context, @quiz, @submission)
      js_env QUIZ_SUBMISSION_EVENTS_URL: events_url
    end

    js_env IS_PREVIEW: true if @submission.preview?

    @quiz_presenter = Quizzes::TakeQuizPresenter.new(@quiz, @submission, params)
    if params[:persist_headless]
      add_meta_tag(name: "viewport", id: "vp", content: "initial-scale=1.0,user-scalable=yes,width=device-width")
      js_env MOBILE_UI: true
    end
    render :take_quiz
  end

  def valid_question?(submission, question_id)
    submission.has_question?(question_id)
  end

  def can_take_quiz?
    return true if params[:preview] && can_preview?
    return false if params[:take] && !@quiz.grants_right?(@current_user, :submit)
    return false if @submission&.completed? && @submission.attempts_left == 0

    @quiz_eligibility = Quizzes::QuizEligibility.new(course: @context,
                                                     quiz: @quiz,
                                                     user: @current_user,
                                                     session:,
                                                     remote_ip: request.remote_ip,
                                                     access_code: params[:access_code])

    if params[:take]
      @quiz_eligibility.eligible?
    else
      @quiz_eligibility.potentially_eligible?
    end
  end

  def quiz_submission_active?
    @submission && (@submission.untaken? || @submission.preview?) && !@just_graded
  end

  # counts of submissions queried in #managed_quiz_data
  def submission_counts
    submitted_with_submissions = @context.students_visible_to(@current_user, include: :inactive)
                                         .joins(:quiz_submissions)
                                         .where("quiz_submissions.quiz_id=? AND quiz_submissions.workflow_state<>'settings_only'", @quiz)
    @submitted_student_count = submitted_with_submissions.distinct.count(:id)
    # add logged out submissions
    @submitted_student_count += @quiz.quiz_submissions.logged_out.not_settings_only.count
    @any_submissions_pending_review = submitted_with_submissions.where("quiz_submissions.workflow_state = 'pending_review'").count > 0
  end

  def set_download_submission_dialog_title
    js_env SUBMISSION_DOWNLOAD_DIALOG_TITLE: I18n.t("#quizzes.download_all_quiz_file_upload_submissions",
                                                    "Download All Quiz File Upload Submissions")
  end

  # Handler for quiz option: one_time_results
  #
  # Prevent the student from seeing their submission results more than once.
  def lock_results
    return unless @lock_results_if_needed
    return unless @quiz.one_time_results?

    # ignore teacher views
    return if can_preview?

    submission = @submission || get_submission

    return if submission.blank? || submission.settings_only?

    if submission.results_visible? && !submission.has_seen_results?
      Quizzes::QuizSubmission.where({ id: submission }).update_all({
                                                                     has_seen_results: true
                                                                   })
    end
  end

  def render_forbidden
    if @quiz.new_record?
      render json: @quiz.errors, status: :forbidden
    else
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz) }
        format.json { render json: @quiz.errors, status: :forbidden }
      end
    end
  end

  def quiz_lti_on_quizzes_page?
    @context.root_account.feature_enabled?(:newquizzes_on_quiz_page) &&
      quiz_lti_enabled? &&
      @context.quiz_lti_tool.url != "http://void.url.inseng.net"
  end

  def quiz_lti_enabled?
    @context.feature_enabled?(:quizzes_next) &&
      @context.quiz_lti_tool.present?
  end

  def assignment_quizzes_json(serializer_options)
    old_quizzes = scoped_quizzes_index.select { |q| q.quiz_type == QUIZ_TYPE_ASSIGNMENT }
    unless @context.root_account.feature_enabled?(:newquizzes_on_quiz_page)
      return quizzes_json(old_quizzes, *serializer_options)
    end

    quizzes_next_json(
      sort_quizzes(old_quizzes + scoped_new_quizzes_index),
      *serializer_options
    )
  end

  def sort_quizzes(quizzes)
    quizzes.sort_by do |quiz|
      [
        quiz_due_date(quiz) || CanvasSort::Last,
        Canvas::ICU.collation_key(quiz.title || CanvasSort::First)
      ]
    end
  end

  # get the due_date for either a Classic Quiz or a quiz_lti quiz (Assignment)
  def quiz_due_date(quiz)
    return quiz.assignment ? quiz.assignment.due_at : quiz.lock_at if quiz.is_a?(Quizzes::Quiz)

    quiz.due_at || quiz.lock_at
  end

  protected

  def get_quiz_params
    params[:quiz] ? params[:quiz].permit(API_ALLOWED_QUIZ_INPUT_FIELDS[:only]) : {}
  end

  def update_quiz_and_assignment_versions(quiz, prepared_batch)
    params = { quiz_id: quiz.id,
               quiz_version: quiz.version_number,
               assignment_id: quiz.assignment_id,
               assignment_version: quiz.assignment&.version_number }
    prepared_batch[:overrides_to_create].each { |override| override.assign_attributes(params) unless override.context_module_id }
    prepared_batch[:overrides_to_update].each { |override| override.assign_attributes(params) unless override.context_module_id }
  end

  def hide_quiz?
    !@submission.posted?
  end

  def scoped_quizzes_index
    return @_quizzes_index if @_quizzes_index

    scope = @context.quizzes.active.preload(:assignment).select(*(Quizzes::Quiz.columns.map(&:name) - ["quiz_data"]))

    # students only get to see published quizzes, and they will fetch the
    # overrides later using the API:
    scope = scope.available unless @context.grants_right?(@current_user, session, :read_as_admin)

    scope = DifferentiableAssignment.scope_filter(scope, @current_user, @context)

    @_quizzes_index = sort_quizzes(scope)
  end

  def scoped_new_quizzes_index
    return @_new_quizzes_index if @_new_quizzes_index

    @_new_quizzes_index = Assignments::ScopedToUser.new(@context, @current_user).scope.preload(:duplicate_of).type_quiz_lti
  end

  def scoped_quizzes
    return @_quizzes if @_quizzes

    scope = @context.quizzes.active.preload(:assignment)

    # students only get to see published quizzes, and they will fetch the
    # overrides later using the API:
    scope = scope.available unless @context.grants_right?(@current_user, session, :read_as_admin)

    scope = DifferentiableAssignment.scope_filter(scope, @current_user, @context)

    @_quizzes = sort_quizzes(scope)
  end

  def quiz_engine_selection
    return "true" if new_quizzes_by_default?

    selection = nil
    if @context.is_a?(Course) && @context.settings.dig(:engine_selected, :user_id)
      selection_obj = @context.settings.dig(:engine_selected, :user_id)
      if selection_obj[:expiration] > Time.zone.today
        selection = selection_obj[:newquizzes_engine_selected]
      end
      selection
    end
    selection
  end
end
