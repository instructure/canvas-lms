#
# Copyright (C) 2011 Instructure, Inc.
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
  include Api::V1::AssignmentOverride
  include KalturaHelper
  include Filters::Quizzes

  # If Quiz#one_time_results is on, this flag must be set whenever we've
  # rendered the submission results to the student so that the results can be
  # locked down.
  attr_reader :lock_results_if_needed

  before_filter :require_context
  add_crumb(proc { t('#crumbs.quizzes', "Quizzes") }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_quizzes_url }
  before_filter { |c| c.active_tab = "quizzes" }
  before_filter :require_quiz, :only => [
    :statistics,
    :edit,
    :show,
    :history,
    :update,
    :destroy,
    :moderate,
    :read_only,
    :managed_quiz_data,
    :submission_versions,
    :submission_html
  ]
  before_filter :set_download_submission_dialog_title , only: [:show,:statistics]
  after_filter :lock_results, only: [ :show, :submission_html ]
  # The number of questions that can display "details". After this number, the "Show details" option is disabled
  # and the data is not even loaded.
  QUIZ_QUESTIONS_DETAIL_LIMIT = 25
  QUIZ_MAX_COMBINATION_COUNT = 200

  QUIZ_TYPE_ASSIGNMENT = 'assignment'
  QUIZ_TYPE_PRACTICE = 'practice_quiz'
  QUIZ_TYPE_SURVEYS = ['survey', 'graded_survey']

  def index
    return unless authorized_action(@context, @current_user, :read)
    return unless tab_enabled?(@context.class::TAB_QUIZZES)

    can_manage = @context.grants_right?(@current_user, session, :manage_assignments)

    scope = @context.quizzes.active.includes([ :assignment ])

    # students only get to see published quizzes, and they will fetch the
    # overrides later using the API:
    scope = scope.available unless can_manage

    if @context.feature_enabled?(:differentiated_assignments)
      scope = DifferentiableAssignment.scope_filter(scope, @current_user, @context)
    end

    quizzes = scope.sort_by do |quiz|
      due_date = quiz.assignment ? quiz.assignment.due_at : quiz.lock_at
      [
        due_date || CanvasSort::Last,
        Canvas::ICU.collation_key(quiz.title || CanvasSort::First)
      ]
    end

    quiz_options = Rails.cache.fetch([
      'quiz_user_permissions', @context.id, @current_user,
      quizzes.map(&:id), # invalidate on add/delete of quizzes
      quizzes.map(&:updated_at).sort.last # invalidate on modifications
    ].cache_key) do
      quizzes.each_with_object({}) do |quiz, quiz_user_permissions|
        quiz_user_permissions[quiz.id] = {
          can_update: can_manage,
          can_unpublish: can_manage && quiz.can_unpublish?
        }
      end
    end

    assignment_quizzes = quizzes.select{ |q| q.quiz_type == QUIZ_TYPE_ASSIGNMENT }
    open_quizzes       = quizzes.select{ |q| q.quiz_type == QUIZ_TYPE_PRACTICE }
    surveys            = quizzes.select{ |q| QUIZ_TYPE_SURVEYS.include?(q.quiz_type) }
    serializer_options = [@context, @current_user, session, {
      permissions: quiz_options,
      skip_date_overrides: true,
      skip_lock_tests: true
    }]

    js_env({
      :QUIZZES => {
        assignment: quizzes_json(assignment_quizzes, *serializer_options),
        open: quizzes_json(open_quizzes, *serializer_options),
        surveys: quizzes_json(surveys, *serializer_options),
        options: quiz_options
      },
      :URLS => {
        new_quiz_url: context_url(@context, :new_context_quiz_url, :fresh => 1),
        question_banks_url: context_url(@context, :context_question_banks_url),
        assignment_overrides: api_v1_course_quiz_assignment_overrides_url(@context)
      },
      :PERMISSIONS => {
        create: can_do(@context.quizzes.scoped.new, @current_user, :create),
        manage: can_manage
      },
      :FLAGS => {
        question_banks: feature_enabled?(:question_banks)
      },
      :quiz_menu_tools => external_tools_display_hashes(:quiz_menu)
    })

    if @current_user.present?
      Quizzes::OutstandingQuizSubmissionManager.send_later_if_production(:grade_by_course,
        @context)
    end

    log_asset_access("quizzes:#{@context.asset_string}", "quizzes", 'other')
  end

  def show
    if @quiz.deleted?
      flash[:error] = t('errors.quiz_deleted', "That quiz has been deleted")
      redirect_to named_context_url(@context, :context_quizzes_url)
      return
    end

    if authorized_action(@quiz, @current_user, :read)
      # optionally force auth even for public courses
      return if value_to_boolean(params[:force_user]) && !force_user

      if @current_user && !@quiz.visible_to_user?(@current_user)
        if @current_user.quiz_submissions.where(quiz_id: @quiz).any?
          flash[:notice] = t 'notices.submission_doesnt_count', "This quiz will no longer count towards your grade."
        else
          respond_to do |format|
            flash[:error] = t 'notices.quiz_not_availible', "You do not have access to the requested quiz."
            format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
          end
          return
        end
      end

      @quiz = @quiz.overridden_for(@current_user)
      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))

      setup_headless

      if @quiz.require_lockdown_browser? && @quiz.require_lockdown_browser_for_results? && params[:viewing]
        return unless check_lockdown_browser(:medium, named_context_url(@context, 'context_quiz_url', @quiz.to_param, :viewing => "1"))
      end

      if @quiz.require_lockdown_browser? && refresh_ldb = value_to_boolean(params.delete(:refresh_ldb))
        return render(:action => "refresh_quiz_after_popup")
      end

      @question_count = @quiz.question_count
      if session[:quiz_id] == @quiz.id && !request.xhr?
        session.delete(:quiz_id)
      end
      @locked_reason = @quiz.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true)
      @locked = @locked_reason && !@quiz.grants_right?(@current_user, session, :update)

      @context_module_tag = ContextModuleItem.find_tag_with_preferred([@quiz, @quiz.assignment], params[:module_item_id])
      @sequence_asset = @context_module_tag.try(:content)
      @quiz.context_module_action(@current_user, :read) if !@locked

      @assignment = @quiz.assignment
      @assignment = @assignment.overridden_for(@current_user) if @assignment

      @submission = get_submission

      @just_graded = false
      if @submission && @submission.needs_grading?(!!params[:take])
        Quizzes::SubmissionGrader.new(@submission).grade_submission(:finished_at => @submission.end_at)
        @submission.reload
        @just_graded = true
      end
      if @submission
        upload_url = api_v1_quiz_submission_files_path(:course_id => @context.id, :quiz_id => @quiz.id)
        js_env :UPLOAD_URL => upload_url
        js_env :SUBMISSION_VERSIONS_URL => course_quiz_submission_versions_url(@context, @quiz) unless @quiz.muted?
        events_url = api_v1_course_quiz_submission_events_url(@context, @quiz, @submission)
        js_env QUIZ_SUBMISSION_EVENTS_URL: events_url unless @js_env[:QUIZ_SUBMISSION_EVENTS_URL]
      end

      setup_attachments
      submission_counts if @quiz.grants_right?(@current_user, session, :grade) || @quiz.grants_right?(@current_user, session, :read_statistics)
      @stored_params = (@submission.temporary_data rescue nil) if params[:take] && @submission && (@submission.untaken? || @submission.preview?)
      @stored_params ||= {}
      hash = { :QUIZZES_URL => course_quizzes_url(@context),
             :IS_SURVEY => @quiz.survey?,
             :QUIZ => quiz_json(@quiz,@context,@current_user,session),
             :COURSE_ID => @context.id,
             :LOCKDOWN_BROWSER => @quiz.require_lockdown_browser?,
             :ATTACHMENTS => Hash[@attachments.map { |_,a| [a.id,attachment_hash(a)]}],
             :CONTEXT_ACTION_SOURCE => :quizzes  }
      append_sis_data(hash)
      js_env(hash)

      @quiz_menu_tools = external_tools_display_hashes(:quiz_menu)
      if params[:take] && (@can_take = can_take_quiz?)

        # allow starting the quiz via a GET request, but only when using a lockdown browser
        if request.post? || (@quiz.require_lockdown_browser? && !quiz_submission_active?)
          start_quiz!
        else
          take_quiz
        end
      else
        @lock_results_if_needed = true

        log_asset_access(@quiz, "quizzes", "quizzes")
      end
      @padless = true
    end
  end

  def new
    if authorized_action(@context.quizzes.scoped.new, @current_user, :create)
      @assignment = nil
      @assignment = @context.assignments.active.find(params[:assignment_id]) if params[:assignment_id]
      @quiz = @context.quizzes.build
      @quiz.title = params[:title] if params[:title]
      @quiz.due_at = params[:due_at] if params[:due_at]
      @quiz.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]
      @quiz.save!
      # this is a weird check... who can create but not update???
      if authorized_action(@quiz, @current_user, :update)
        @assignment = @quiz.assignment
      end
      redirect_to(named_context_url(@context, :edit_context_quiz_url, @quiz))
    end
  end

  def edit
    if authorized_action(@quiz, @current_user, :update)
      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
      @assignment = @quiz.assignment

      @quiz.title = params[:title] if params[:title]
      @quiz.due_at = params[:due_at] if params[:due_at]
      @quiz.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]

      student_ids = @context.student_ids
      @banks_hash = get_banks(@quiz)

      if @has_student_submissions = @quiz.has_student_submissions?
        flash[:notice] = t('notices.has_submissions_already', "Keep in mind, some students have already taken or started taking this quiz")
      end

      regrade_options = Hash[@quiz.current_quiz_question_regrades.map do |qqr|
        [qqr.quiz_question_id, qqr.regrade_option]
      end]
      sections = @context.course_sections.active

      hash = {
        :ASSIGNMENT_ID => @assigment.present? ? @assignment.id : nil,
        :ASSIGNMENT_OVERRIDES => assignment_overrides_json(@quiz.overrides_for(@current_user)),
        :DIFFERENTIATED_ASSIGNMENTS_ENABLED => @context.feature_enabled?(:differentiated_assignments),
        :QUIZ => quiz_json(@quiz, @context, @current_user, session),
        :SECTION_LIST => sections.map { |section|
          {
            :id => section.id,
            :name => section.name,
            :start_at => section.start_at,
            :end_at => section.end_at,
            :override_course_dates => section.restrict_enrollments_to_section_dates
          }
        },
        :QUIZZES_URL => course_quizzes_url(@context),
        :QUIZ_IP_FILTERS_URL => api_v1_course_quiz_ip_filters_url(@context, @quiz),
        :CONTEXT_ACTION_SOURCE => :quizzes,
        :REGRADE_OPTIONS => regrade_options,
        :quiz_max_combination_count => QUIZ_MAX_COMBINATION_COUNT,
        :COURSE_DATE_RANGE => {
          :start_at => @context.start_at,
          :end_at => @context.conclude_at,
          :override_term_dates => @context.restrict_enrollments_to_course_dates
        },
        :TERM_DATE_RANGE => {
          :start_at => @context.enrollment_term.start_at,
          :end_at => @context.enrollment_term.end_at
        }
      }

      append_sis_data(hash)
      js_env(hash)
      render :action => "new"
    end
  end

  def create
    if authorized_action(@context.quizzes.scoped.new, @current_user, :create)
      params[:quiz][:title] = nil if params[:quiz][:title] == "undefined"
      params[:quiz][:title] ||= t(:default_title, "New Quiz")
      params[:quiz].delete(:points_possible) unless params[:quiz][:quiz_type] == 'graded_survey'
      params[:quiz][:access_code] = nil if params[:quiz][:access_code] == ""
      if params[:quiz][:quiz_type] == 'assignment' || params[:quiz][:quiz_type] == 'graded_survey'
        params[:quiz][:assignment_group_id] ||= @context.assignment_groups.first.id
        if (assignment_group_id = params[:quiz].delete(:assignment_group_id)) && assignment_group_id.present?
          @assignment_group = @context.assignment_groups.active.where(id: assignment_group_id).first
        end
        if @assignment_group
          @assignment = @context.assignments.build(:title => params[:quiz][:title], :due_at => params[:quiz][:lock_at], :submission_types => 'online_quiz')
          @assignment.assignment_group = @assignment_group
          @assignment.saved_by = :quiz
          @assignment.workflow_state = 'unpublished'
          @assignment.save
          params[:quiz][:assignment_id] = @assignment.id
        end
        params[:quiz][:assignment_id] = nil unless @assignment
        params[:quiz][:title] = @assignment.title if @assignment
      end
      if params[:assignment].present? && @context.feature_enabled?(:post_grades) && @quiz.assignment
        @quiz.assignment.post_to_sis = params[:assignment][:post_to_sis]
        @quiz.assignment.save
      end
      @quiz = @context.quizzes.build
      @quiz.content_being_saved_by(@current_user)
      @quiz.infer_times
      overrides = delete_override_params
      params[:quiz].delete(:only_visible_to_overrides) unless @context.feature_enabled?(:differentiated_assignments)
      @quiz.transaction do
        @quiz.update_attributes!(params[:quiz])
        batch_update_assignment_overrides(@quiz,overrides) unless overrides.nil?
      end
      @quiz.did_edit if @quiz.created?
      @quiz.reload
      render :json => @quiz.as_json(:include => {:assignment => {:include => :assignment_group}})
    end
  rescue
    render :json => @quiz.errors, :status => :bad_request
  end

  def update
    n = Time.now.to_f
    if authorized_action(@quiz, @current_user, :update)
      params[:quiz] ||= {}
      params[:quiz][:title] = t(:default_title, "New Quiz") if params[:quiz][:title] == "undefined"
      params[:quiz].delete(:points_possible) unless params[:quiz][:quiz_type] == 'graded_survey'
      params[:quiz][:access_code] = nil if params[:quiz][:access_code] == ""
      if params[:quiz][:quiz_type] == 'assignment' || params[:quiz][:quiz_type] == 'graded_survey' #'new' && params[:quiz][:assignment_group_id]
        if (assignment_group_id = params[:quiz].delete(:assignment_group_id)) && assignment_group_id.present?
          @assignment_group = @context.assignment_groups.active.where(id: assignment_group_id).first
        end
        @assignment_group ||= @context.assignment_groups.first
        # The code to build an assignment for a quiz used to be here, but it's
        # been moved to the model quiz.rb instead.  See Quiz:build_assignment.
        params[:quiz][:assignment_group_id] = @assignment_group && @assignment_group.id
      end

      params[:quiz][:lock_at] = nil if params[:quiz].delete(:do_lock_at) == 'false'

      @quiz.with_versioning(false) do
        @quiz.did_edit if @quiz.created?
      end

      # TODO: API for Quiz overrides!
      respond_to do |format|
        @quiz.transaction do
          overrides = delete_override_params
          notify_of_update = value_to_boolean(params[:quiz][:notify_of_update])
          params[:quiz][:notify_of_update] = false

          old_assignment = nil
          if @quiz.assignment.present?
            old_assignment = @quiz.assignment.clone
            old_assignment.id = @quiz.assignment.id

            if params[:assignment] && @context.feature_enabled?(:post_grades)
              @quiz.assignment.post_to_sis = params[:assignment][:post_to_sis]
              @quiz.assignment.save
            end
          end

          auto_publish = @quiz.published?
          @quiz.with_versioning(auto_publish) do
            params[:quiz].delete(:only_visible_to_overrides) unless @context.feature_enabled?(:differentiated_assignments)
            # using attributes= here so we don't need to make an extra
            # database call to get the times right after save!
            @quiz.attributes = params[:quiz]
            @quiz.infer_times
            @quiz.content_being_saved_by(@current_user)
            if auto_publish
              @quiz.generate_quiz_data
              @quiz.workflow_state = 'available'
              @quiz.published_at = Time.now
            end
            @quiz.save!
          end

          batch_update_assignment_overrides(@quiz,overrides) unless overrides.nil?

          # quiz.rb restricts all assignment broadcasts if notify_of_update is
          # false, so we do the same here
          if @quiz.assignment.present? && old_assignment && (notify_of_update || old_assignment.due_at != @quiz.assignment.due_at)
            @quiz.assignment.do_notifications!(old_assignment, notify_of_update)
          end
          @quiz.reload
          @quiz.update_quiz_submission_end_at_times if params[:quiz][:time_limit].present?
        end
        flash[:notice] = t('notices.quiz_updated', "Quiz successfully updated")
        format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz) }
        format.json { render :json => @quiz.as_json(:include => {:assignment => {:include => :assignment_group}}) }
      end
    end
  rescue
    respond_to do |format|
      flash[:error] = t('errors.quiz_update_failed', "Quiz failed to update")
      format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz) }
      format.json { render :json => @quiz.errors, :status => :bad_request }
    end
  end

  def destroy
    if authorized_action(@quiz, @current_user, :delete)
      respond_to do |format|
        if @quiz.destroy
          format.html { redirect_to course_quizzes_url(@context) }
          format.json { render :json => @quiz }
        else
          format.html { redirect_to course_quiz_url(@context, @quiz) }
          format.json { render :json => @quiz.errors }
        end
      end
    end
  end

  def publish
    if authorized_action(@context, @current_user, :manage_assignments)
      @quizzes = @context.quizzes.active.where(id: params[:quizzes])
      @quizzes.each(&:publish!)

      flash[:notice] = t('notices.quizzes_published',
                         { :one => "1 quiz successfully published!",
                           :other => "%{count} quizzes successfully published!" },
                         :count => @quizzes.length)


      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render :json => {}, :status => :ok }
      end
    end
  end

  def unpublish
    if authorized_action(@context, @current_user, :manage_assignments)
      @quizzes = @context.quizzes.active.where(id: params[:quizzes]).select{|q| q.available? }
      @quizzes.each(&:unpublish!)

      flash[:notice] = t('notices.quizzes_unpublished',
                         { :one => "1 quiz successfully unpublished!",
                           :other => "%{count} quizzes successfully unpublished!" },
                         :count => @quizzes.length)

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render :json => {}, :status => :ok }
      end
    end
  end

  # student_analysis report
  def statistics
    if @context.feature_enabled?(:quiz_stats)
      return statistics_cqs
    end

    if authorized_action(@quiz, @current_user, :read_statistics)
      respond_to do |format|
        format.html {
          all_versions = params[:all_versions] == '1'
          add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
          add_crumb(t(:statistics_crumb, "Statistics"), named_context_url(@context, :context_quiz_statistics_url, @quiz))

          if !@context.large_roster?
            @statistics = @quiz.statistics(all_versions)
            user_ids = @statistics[:submission_user_ids]
            @submitted_users = User.where(:id => user_ids.to_a).order_by_sortable_name
            #include logged out users
            @submitted_users += @statistics[:submission_logged_out_users]
            @users = Hash[
              @submitted_users.map { |u| [u.id, u] }
            ]
          end

          js_env quiz_reports: Quizzes::QuizStatistics::REPORTS.map { |report_type|
            report = @quiz.current_statistics_for(report_type, {
              includes_all_versions: all_versions
            })

            Quizzes::QuizReportSerializer.new(report, {
              controller: self,
              scope: @current_user,
              root: false,
              includes: %w[ file progress ]
            }).as_json
          }
        }
      end
    end
  end

  def statistics_cqs
    if authorized_action(@quiz, @current_user, :read_statistics)
      respond_to do |format|
        format.html {
          add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
          add_crumb(t(:statistics_crumb, "Statistics"), named_context_url(@context, :context_quiz_statistics_url, @quiz))

          js_env({
            quiz_url: api_v1_course_quiz_url(@context, @quiz),
            quiz_statistics_url: api_v1_course_quiz_statistics_url(@context, @quiz),
            quiz_reports_url: api_v1_course_quiz_reports_url(@context, @quiz),
          })

          render action: "statistics_cqs"
        }
      end
    end
  end

  def managed_quiz_data
    extend Api::V1::User
    if authorized_action(@quiz, @current_user, [:grade, :read_statistics])
      student_scope = @context.students_visible_to(@current_user)
      if @quiz.differentiated_assignments_applies?
        student_scope = student_scope.able_to_see_quiz_in_course_with_da(@quiz.id, @context.id)
      end
      students = student_scope.order_by_sortable_name.to_a.uniq

      @submissions_from_users = @quiz.quiz_submissions.for_user_ids(students.map(&:id)).not_settings_only.all

      @submissions_from_users = Hash[@submissions_from_users.map { |s| [s.user_id,s] }]

      #include logged out submissions
      @submissions_from_logged_out = @quiz.quiz_submissions.logged_out.not_settings_only

      @submitted_students, @unsubmitted_students = students.partition do |stud|
        @submissions_from_users[stud.id]
      end

      if @quiz.anonymous_survey?
        @submitted_students = @submitted_students.sort_by do |student|
          @submissions_from_users[student.id].id
        end

        submitted_students_json = @submitted_students.map &:id
        unsubmitted_students_json = @unsubmitted_students.map &:id
      else
        submitted_students_json = @submitted_students.map { |u| user_json(u, @current_user, session) }
        unsubmitted_students_json = @unsubmitted_students.map { |u| user_json(u, @current_user, session) }
      end

      @quiz_submission_list = { :UNSUBMITTED_STUDENTS => unsubmitted_students_json,
                                :SUBMITTED_STUDENTS => submitted_students_json }.to_json
      render :layout => false
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
        user_id = params[:user_id].presence || @current_user.id
        @submission = @quiz.quiz_submissions.where(user_id: user_id).order(:created_at).first
      end
      if @submission && !@submission.user_id && logged_out_index = params[:u_index]
        @logged_out_user_index = logged_out_index
      end
      @submission = nil if @submission && @submission.settings_only?
      @user = @submission && @submission.user
      if @submission && @submission.needs_grading?
        Quizzes::SubmissionGrader.new(@submission).grade_submission(:finished_at => @submission.end_at)
        @submission.reload
      end
      setup_attachments
      if @quiz.deleted?
        flash[:error] = t('errors.quiz_deleted', "That quiz has been deleted")
        redirect_to named_context_url(@context, :context_quizzes_url)
        return
      end
      if !@submission
        flash[:notice] = t('notices.no_submission_for_user', "There is no submission available for that user")
        redirect_to named_context_url(@context, :context_quiz_url, @quiz)
        return
      end
      if @quiz.muted? && !@quiz.grants_right?(@current_user, session, :grade)
        flash[:notice] = t('notices.cant_view_submission_while_muted', "You cannot view the quiz history while the quiz is muted.")
        redirect_to named_context_url(@context, :context_quiz_url, @quiz)
        return
      end
      if params[:score_updated]
        js_env :SCORE_UPDATED => true
      end
      js_env :GRADE_BY_QUESTION => @current_user.preferences[:enable_speedgrader_grade_by_question]
      if authorized_action(@submission, @current_user, :read)
        if @current_user && !@quiz.visible_to_user?(@current_user)
          flash[:notice] = t 'notices.submission_doesnt_count', "This quiz will no longer count towards your grade."
        end
        dont_show_user_name = @submission.quiz.anonymous_submissions || (!@submission.user || @submission.user == @current_user)
        add_crumb((dont_show_user_name ? t(:default_history_crumb, "History") : @submission.user.name))
        @headers = !params[:headless]
        unless @headers
          @body_classes << 'quizzes-speedgrader'
        end
        @current_submission = @submission
        @version_instances = @submission.submitted_attempts.sort_by{|v| v.version_number }
        @versions = get_versions
        params[:version] ||= @version_instances[0].version_number if @submission.untaken? && !@version_instances.empty?
        @current_version = true
        @version_number = "current"
        if params[:version]
          @version_number = params[:version].to_i
          @unversioned_submission = @submission
          @submission = @versions.detect{|s| s.version_number >= @version_number}
          @submission ||= @unversioned_submission.versions.get(params[:version]).model
          @current_version = (@current_submission.version_number == @submission.version_number)
          @version_number = "current" if @current_version
        end
        log_asset_access(@quiz, "quizzes", 'quizzes')

        if @quiz.require_lockdown_browser? && @quiz.require_lockdown_browser_for_results? && params[:viewing]
          return unless check_lockdown_browser(:medium, named_context_url(@context, 'context_quiz_history_url', @quiz.to_param, :viewing => "1", :version => params[:version]))
        end
      end
    end
  end

  def moderate
    if authorized_action(@quiz, @current_user, :grade)
      @all_students = @context.students_visible_to(@current_user).order_by_sortable_name
      @students = @all_students
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
          render :json => @submissions.map{ |s| s.as_json(include_root: false, except: [:submission_data, :quiz_data], methods: ['extendable?', :finished_in_words, :attempts_left]) }
        end
      end
    end
  end

  def submission_versions
    if authorized_action(@quiz, @current_user, :read)
      @submission = get_submission
      @versions   = @submission ? get_versions : []

      if @versions.size > 0 && !@quiz.muted?
        render :layout => false
      else
        render :nothing => true
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
    if @submission && @submission.completed?
      @lock_results_if_needed = true
      render layout: false
    else
      render nothing: true
    end
  end

  private

  def get_banks(quiz)
    banks_hash = {}
    bank_ids = quiz.quiz_groups.map(&:assessment_question_bank_id)
    unless bank_ids.empty?
      banks_hash = AssessmentQuestionBank.active.where(id: bank_ids).index_by(&:id)
    end
    banks_hash
  end

  def get_submission
    submission = @quiz.quiz_submissions.where(user_id: @current_user).order(:created_at).first
    if !@current_user || (params[:preview] && @quiz.grants_right?(@current_user, session, :update))
      user_code = temporary_user_code
      submission = @quiz.quiz_submissions.where(temporary_user_code: user_code).first
    end

    if submission
      submission.ensure_question_reference_integrity!
    end

    submission
  end

  def get_versions
    @submission.submitted_attempts
  end

  def setup_attachments
    if @submission
      @attachments = Hash[@submission.attachments.map do |attachment|
          [attachment.id,attachment]
      end
      ]
    else
      @attachments = {}
    end
  end

  def attachment_hash(attachment)
    {:id => attachment.id, :display_name => attachment.display_name}
  end

  def delete_override_params
    # nil represents the fact that we don't want to update the overrides
    return nil unless params[:quiz].has_key?(:assignment_overrides)

    overrides = params[:quiz].delete(:assignment_overrides)
    overrides = deserialize_overrides(overrides)

    # overrides might be "false" to indicate no overrides through form params
    overrides.is_a?(Array) ? overrides : []
  end

  def force_user
    if !@current_user
      session[:return_to] = course_quiz_path(@context, @quiz)
      redirect_to login_path
    end
    return @current_user.present?
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
      redirect_to(:action => 'lockdown_browser_required', :quiz_id => @quiz.id)
      return false
    elsif !session['lockdown_browser_popup'] && @query_params = plugin.popup_window(self, security_level)
      @security_level = security_level
      session['lockdown_browser_popup'] = true
      render(:action => 'take_quiz_in_popup')
      return false
    end
    @lockdown_browser_authorized_to_view = true
    @headers = false
    @show_left_side = false
    @padless = true
    return true
  end

  # use this for all redirects while taking a quiz -- it'll add params to tell
  # the lockdown browser that it's ok to follow the redirect
  def quiz_redirect_params(opts = {})
    return opts if !@quiz.require_lockdown_browser? || @quiz.grants_right?(@current_user, session, :grade)
    plugin = Canvas::LockdownBrowser.plugin.base
    plugin.redirect_params(self, opts)
  end
  helper_method :quiz_redirect_params

  def start_quiz!
    can_retry = @submission && (@quiz.unlimited_attempts? || @submission.attempts_left > 0 || @quiz.grants_right?(@current_user, session, :update))
    preview = params[:preview] && @quiz.grants_right?(@current_user, session, :update)
    if !@submission || @submission.settings_only? || (@submission.completed? && can_retry && !@just_graded) || preview
      user_code = @current_user
      user_code = nil if preview
      user_code ||= temporary_user_code
      @submission = @quiz.generate_submission(user_code, !!preview)
      log_asset_access(@quiz, 'quizzes', 'quizzes', 'participate')
    end
    if quiz_submission_active?
      if request.get?
        # currently, the only way to start_quiz! with a get request is to use the LDB
        take_quiz
      else
        # redirect to avoid refresh issues
        redirect_to course_quiz_take_url(@context, @quiz, quiz_redirect_params(:preview => params[:preview]))
      end
    else
      flash[:error] = t('errors.no_more_attempts', "You have no quiz attempts left") unless @just_graded
      redirect_to named_context_url(@context, :context_quiz_url, @quiz, quiz_redirect_params)
    end
  end

  def take_quiz
    return unless quiz_submission_active?
    @show_embedded_chat = false
    flash[:notice] = t('notices.less_than_allotted_time', "You started this quiz near when it was due, so you won't have the full amount of time to take the quiz.") if @submission.less_than_allotted_time?
    if params[:question_id] && !valid_question?(@submission, params[:question_id])
      redirect_to course_quiz_url(@context, @quiz) and return
    end

    events_url = api_v1_course_quiz_submission_events_url(@context, @quiz, @submission)
    js_env QUIZ_SUBMISSION_EVENTS_URL: events_url unless @js_env[:QUIZ_SUBMISSION_EVENTS_URL]

    @quiz_presenter = Quizzes::TakeQuizPresenter.new(@quiz, @submission, params)
    render :action => 'take_quiz'
  end

  def valid_question?(submission, question_id)
    submission.has_question?(question_id)
  end

  def can_take_quiz?
    return false if @locked
    return false unless authorized_action(@quiz, @current_user, :submit)
    return false if @quiz.require_lockdown_browser? && !check_lockdown_browser(:highest, named_context_url(@context, 'context_quiz_take_url', @quiz.id))

    quiz_access_code_key = @quiz.access_code_key_for_user(@current_user)

    if @quiz.access_code.present? && params[:access_code] == @quiz.access_code
      session[quiz_access_code_key] = true
    end
    if @quiz.access_code.present? && !session[quiz_access_code_key]
      render :action => 'access_code'
      false
    elsif @quiz.ip_filter && !@quiz.valid_ip?(request.remote_ip)
      render :action => 'invalid_ip'
      false
    elsif @section.present? && @section.restrict_enrollments_to_section_dates && @section.end_at < Time.now
      false
    elsif @context.restrict_enrollments_to_course_dates && @context.soft_concluded?
      false
    elsif @current_user.present? &&
          @context.present? &&
          @context.enrollments.where(user_id: @current_user.id).all? {|e| e.inactive? } &&
          !@context.grants_right?(@current_user, :read_as_admin)
      false
    else
      true
    end
  end

  def quiz_submission_active?
    @submission && (@submission.untaken? || @submission.preview?) && !@just_graded
  end

  # counts of submissions queried in #managed_quiz_data
  def submission_counts
    submitted_with_submissions = @context.students_visible_to(@current_user).
        joins(:quiz_submissions).
        where("quiz_submissions.quiz_id=? AND quiz_submissions.workflow_state<>'settings_only'", @quiz)
    @submitted_student_count = submitted_with_submissions.count(:id, :distinct => true)
    #add logged out submissions
    @submitted_student_count += @quiz.quiz_submissions.logged_out.not_settings_only.count
    @any_submissions_pending_review = submitted_with_submissions.where("quiz_submissions.workflow_state = 'pending_review'").count > 0
  end

  def set_download_submission_dialog_title
    js_env SUBMISSION_DOWNLOAD_DIALOG_TITLE: I18n.t('#quizzes.download_all_quiz_file_upload_submissions',
                                                    'Download All Quiz File Upload Submissions')
  end

  # Handler for quiz option: one_time_results
  #
  # Prevent the student from seeing their submission results more than once.
  def lock_results
    return unless @lock_results_if_needed
    return unless @quiz.one_time_results?

    # ignore teacher views
    return if @quiz.grants_right?(@current_user, :update)

    submission = @submission || get_submission

    return if submission.blank? || submission.settings_only?

    if submission.results_visible? && !submission.has_seen_results?
      Quizzes::QuizSubmission.where({ id: submission }).update_all({
        has_seen_results: true
      })
    end
  end
end
