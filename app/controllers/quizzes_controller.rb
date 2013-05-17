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

class QuizzesController < ApplicationController
  include Api::V1::Quiz
  include Api::V1::AssignmentOverride
  before_filter :require_context
  add_crumb(proc { t('#crumbs.quizzes', "Quizzes") }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_quizzes_url }
  before_filter { |c| c.active_tab = "quizzes" }
  before_filter :get_quiz, :only => [:statistics, :edit, :show, :reorder, :history, :update, :destroy, :moderate, :filters, :read_only, :managed_quiz_data]

  # The number of questions that can display "details". After this number, the "Show details" option is disabled
  # and the data is not even loaded.
  QUIZ_QUESTIONS_DETAIL_LIMIT = 25

  def index
    if authorized_action(@context, @current_user, :read)
      return unless tab_enabled?(@context.class::TAB_QUIZZES)
      @quizzes = @context.quizzes.active.include_assignment.sort_by{|q| [(q.assignment ? q.assignment.due_at : q.lock_at) || Time.parse("Jan 1 2020"), q.title || ""]}
      @unpublished_quizzes = @quizzes.select{|q| !q.available?}
      @quizzes = @quizzes.select{|q| q.available?}
      @assignment_quizzes = @quizzes.select{|q| q.assignment_id}
      @open_quizzes = @quizzes.select{|q| q.quiz_type == 'practice_quiz'}
      @surveys = @quizzes.select{|q| q.quiz_type == 'survey' || q.quiz_type == 'graded_survey' }
      @submissions_hash = {}
      @submissions_hash
      @current_user && @current_user.quiz_submissions.where('quizzes.context_id=? AND quizzes.context_type=?', @context, @context.class.to_s).includes(:quiz).each do |s|
        if s.needs_grading?
          s.grade_submission(:finished_at => s.end_at)
          s.reload
        end
        @submissions_hash[s.quiz_id] = s
      end
      log_asset_access("quizzes:#{@context.asset_string}", "quizzes", 'other')
    end
  end

  def new
    if authorized_action(@context.quizzes.new, @current_user, :create)
      @assignment = nil
      @assignment = @context.assignments.active.find(params[:assignment_id]) if params[:assignment_id]
      @quiz = @context.quizzes.build
      @quiz.title = params[:title] if params[:title]
      @quiz.due_at = params[:due_at] if params[:due_at]
      @quiz.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]
      @quiz.save!
      add_crumb((!@quiz.quiz_title || @quiz.quiz_title.empty? ? t(:default_new_crumb, "New Quiz") : @quiz.quiz_title))
      # this is a weird check... who can create but not update???
      if authorized_action(@quiz, @current_user, :update)
        @assignment = @quiz.assignment
      end
      redirect_to(named_context_url(@context, :edit_context_quiz_url, @quiz))
    end
  end

  def statistics
    if authorized_action(@quiz, @current_user, :read_statistics)
      if @context.large_roster?
        flash[:notice] = t "#application.notices.page_disabled_for_course", "That page has been disabled for this course"
        redirect_to named_context_url(@context, :context_quiz_url, @quiz)
        return
      end
      
      respond_to do |format|
        format.html {
          add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
          add_crumb(t(:statistics_crumb, "Statistics"), named_context_url(@context, :context_quiz_statistics_url, @quiz))
          @statistics = @quiz.statistics(params[:all_versions] == '1')
          user_ids = @statistics[:submission_user_ids]
          @submitted_users = User.where(:id => user_ids.to_a).order_by_sortable_name
          @users = Hash[
            @submitted_users.map { |u| [u.id, u] }
          ]
        }
        format.csv {
          redirect_to @quiz.statistics_csv(
            :include_all_versions => params[:all_versions] == '1',
            :anonymous => @quiz.anonymous_submissions
          ).csv_attachment.cacheable_s3_download_url
        }
      end
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
      @banks_hash = {}
      bank_ids = @quiz.quiz_groups.map(&:assessment_question_bank_id)
      unless bank_ids.empty?
        AssessmentQuestionBank.active.find_all_by_id(bank_ids).compact.each do |bank|
          @banks_hash[bank.id] = bank
        end
      end
      if @has_student_submissions = @quiz.has_student_submissions?
        flash[:notice] = t('notices.has_submissions_already', "Keep in mind, some students have already taken or started taking this quiz")
      end

      sections = @context.course_sections.active
      js_env :ASSIGNMENT_ID => @assigment.present? ? @assignment.id : nil,
             :ASSIGNMENT_OVERRIDES => assignment_overrides_json(@quiz.overrides_visible_to(@current_user)),
             :QUIZ => quiz_json(@quiz, @context, @current_user, session),
             :SECTION_LIST => sections.map { |section| { :id => section.id, :name => section.name } },
             :QUIZZES_URL => polymorphic_url([@context, :quizzes])
      render :action => "new"
    end
  end

  def read_only
    @assignment = @quiz.assignment
    if authorized_action(@quiz, @current_user, :read_statistics)
      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
      render
    end
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
      @submission = @quiz.quiz_submissions.find_by_user_id(@current_user.id, :order => 'created_at') rescue nil
      if !@current_user || (params[:preview] && @quiz.grants_right?(@current_user, session, :update))
        user_code = temporary_user_code
        @submission = @quiz.quiz_submissions.find_by_temporary_user_code(user_code)
      end
      @just_graded = false
      if @submission && @submission.needs_grading?(!!params[:take])
        @submission.grade_submission(:finished_at => @submission.end_at)
        @submission.reload
        @just_graded = true
      end
      submission_counts if @quiz.grants_right?(@current_user, session, :grade) || @quiz.grants_right?(@current_user, session, :read_statistics)
      @stored_params = (@submission.temporary_data rescue nil) if params[:take] && @submission && (@submission.untaken? || @submission.preview?)
      @stored_params ||= {}
      log_asset_access(@quiz, "quizzes", "quizzes")
      js_env :QUIZZES_URL => polymorphic_url([@context, :quizzes]),
             :IS_SURVEY => @quiz.survey?,
             :QUIZ => quiz_json(@quiz,@context,@current_user,session),
             :LOCKDOWN_BROWSER => @quiz.require_lockdown_browser?
      if params[:take] && can_take_quiz?
        # allow starting the quiz via a GET request, but only when using a lockdown browser
        if request.post? || (@quiz.require_lockdown_browser? && !quiz_submission_active?)
          start_quiz!
        else
          take_quiz
        end
      end
      @padless = true
    end
  end

  def managed_quiz_data
    extend Api::V1::User
    if authorized_action(@quiz, @current_user, [:grade, :read_statistics])
      students = @context.students_visible_to(@current_user).order_by_sortable_name.to_a.uniq
      @submissions = @quiz.quiz_submissions.for_user_ids(students.map(&:id)).where("workflow_state<>'settings_only'").all
      @submissions = Hash[@submissions.map { |s| [s.user_id,s] }]
      @submitted_students, @unsubmitted_students = students.partition do |stud|
        @submissions[stud.id]
      end

      if @quiz.anonymous_survey?
        @submitted_students = @submitted_students.sort_by do |student|
          @submissions[student.id].id
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

  def publish
    if authorized_action(@context, @current_user, :manage_assignments)
      @quizzes = @context.quizzes.active.find_all_by_id(params[:quizzes]).compact.select{|q| !q.available? }
      @quizzes.each do |quiz|
        quiz.generate_quiz_data
        quiz.published_at = Time.now
        quiz.workflow_state = 'available'
        quiz.save
      end
      flash[:notice] = t('notices.quizzes_published',
                         { :one => "1 quiz successfully published!",
                           :other => "%{count} quizzes successfully published!" },
                         :count => @quizzes.length)
      redirect_to named_context_url(@context, :context_quizzes_url)
    end
  end

  def filters
    if authorized_action(@quiz, @current_user, :update)
      @filters = []
      @account = @quiz.context.account
      if @quiz.ip_filter
        @filters << {
          :name => t(:current_filter, 'Current Filter'),
          :account => @quiz.title,
          :filter => @quiz.ip_filter
        }
      end
      while @account
        (@account.settings[:ip_filters] || {}).sort_by(&:first).each do |key, filter|
          @filters << {
            :name => key,
            :account => @account.name,
            :filter => filter
          }
        end
        @account = @account.parent_account
      end
      render :json => @filters.to_json
    end
  end

  def reorder
    if authorized_action(@quiz, @current_user, :update)
      items = []
      groups = @quiz.quiz_groups
      questions = @quiz.quiz_questions
      order = params[:order].split(",")
      order.each_index do |idx|
        name = order[idx]
        obj = nil
        id = name.gsub(/\A(question|group)_/, "").to_i
        obj = questions.detect{|q| q.id == id.to_i} if id != 0 && name.match(/\Aquestion/)
        obj.quiz_group_id = nil if obj.respond_to?("quiz_group_id=")
        obj = groups.detect{|g| g.id == id.to_i} if id != 0 && name.match(/\Agroup/)
        items << obj if obj
      end
      root_questions = @quiz.quiz_questions.where("quiz_group_id IS NULL").all
      items += root_questions
      items.uniq!
      question_updates = []
      group_updates = []
      items.each_with_index do |item, idx|
        if item.is_a?(QuizQuestion)
          question_updates << "WHEN id=#{item.id} THEN #{idx + 1}"
        else
          group_updates << "WHEN id=#{item.id} THEN #{idx + 1}"
        end
      end
      QuizQuestion.where(:id => items.select{|i| i.is_a?(QuizQuestion)}).update_all("quiz_group_id=NULL,position=CASE #{question_updates.join(" ")} ELSE NULL END") unless question_updates.empty?
      QuizGroup.where(:id => items.select{|i| i.is_a?(QuizGroup)}).update_all("position=CASE #{group_updates.join(" ")} ELSE NULL END") unless group_updates.empty?
      Quiz.mark_quiz_edited(@quiz.id)
      render :json => {:reorder => true}
    end
  end

  def history
    if authorized_action(@context, @current_user, :read)
      add_crumb(@quiz.title, named_context_url(@context, :context_quiz_url, @quiz))
      if params[:quiz_submission_id]
        @submission = @quiz.quiz_submissions.find(params[:quiz_submission_id])
      else
        user_id = params[:user_id].presence || @current_user.id
        @submission = @quiz.quiz_submissions.find_by_user_id(user_id, :order => 'created_at') rescue nil
      end
      @submission = nil if @submission && @submission.settings_only?
      @user = @submission && @submission.user
      if @submission && @submission.needs_grading?
        @submission.grade_submission(:finished_at => @submission.end_at)
        @submission.reload
      end
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
      if authorized_action(@submission, @current_user, :read)
        dont_show_user_name = @submission.quiz.anonymous_submissions || (!@submission.user || @submission.user == @current_user)
        add_crumb((dont_show_user_name ? t(:default_history_crumb, "History") : @submission.user.name))
        @headers = !params[:headless]
        unless @headers
          @body_classes << 'quizzes-speedgrader'
        end
        @current_submission = @submission
        @version_instances = @submission.submitted_versions.sort_by{|v| v.version_number }
        params[:version] ||= @version_instances[0].version_number if @submission.untaken? && !@version_instances.empty?
        @current_version = true
        @version_number = "current"
        if params[:version]
          @version_number = params[:version].to_i
          @unversioned_submission = @submission
          @submission = @version_instances.detect{|s| s.version_number >= @version_number}
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

  def delete_override_params
    # nil represents the fact that we don't want to update the overrides
    return nil unless params[:quiz].has_key?(:assignment_overrides)

    overrides = params[:quiz].delete(:assignment_overrides)
    overrides = deserialize_overrides(overrides)

    # overrides might be "false" to indicate no overrides through form params
    overrides.is_a?(Array) ? overrides : []
  end

  def create
    if authorized_action(@context.quizzes.new, @current_user, :create)
      params[:quiz][:title] = nil if params[:quiz][:title] == "undefined"
      params[:quiz][:title] ||= t(:default_title, "New Quiz")
      params[:quiz].delete(:points_possible) unless params[:quiz][:quiz_type] == 'graded_survey'
      params[:quiz][:access_code] = nil if params[:quiz][:access_code] == ""
      if params[:quiz][:quiz_type] == 'assignment' || params[:quiz][:quiz_type] == 'graded_survey'
        params[:quiz][:assignment_group_id] ||= @context.assignment_groups.first.id
        if (assignment_group_id = params[:quiz].delete(:assignment_group_id)) && assignment_group_id.present?
          @assignment_group = @context.assignment_groups.active.find_by_id(assignment_group_id)
        end
        if @assignment_group
          @assignment = @context.assignments.build(:title => params[:quiz][:title], :due_at => params[:quiz][:lock_at], :submission_types => 'online_quiz')
          @assignment.assignment_group = @assignment_group
          @assignment.saved_by = :quiz
          @assignment.save
          params[:quiz][:assignment_id] = @assignment.id
        end
        params[:quiz][:assignment_id] = nil unless @assignment
        params[:quiz][:title] = @assignment.title if @assignment
      end
      @quiz = @context.quizzes.build
      @quiz.content_being_saved_by(@current_user)
      @quiz.infer_times
      overrides = delete_override_params
      @quiz.transaction do
        @quiz.update_attributes!(params[:quiz])
        batch_update_assignment_overrides(@quiz,overrides) unless overrides.nil?
        if params[:activate]
          @quiz.generate_quiz_data
          @quiz.published_at = Time.now
          @quiz.workflow_state = 'available'
          @quiz.save!
        end
      end
      @quiz.did_edit if @quiz.created?
      @quiz.reload
      render :json => @quiz.to_json(:include => {:assignment => {:include => :assignment_group}})
    end
  rescue
    render :json => @quiz.errors.to_json, :status => :bad_request
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
          @assignment_group = @context.assignment_groups.active.find_by_id(assignment_group_id)
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
          if params[:activate]
            @quiz.with_versioning(true) do
              @quiz.generate_quiz_data
              @quiz.workflow_state = 'available'
              @quiz.published_at = Time.now
              @quiz.save!
            end
          end

          notify_of_update = value_to_boolean(params[:quiz][:notify_of_update])
          params[:quiz][:notify_of_update] = false

          old_assignment = nil
          if @quiz.assignment.present?
            old_assignment = @quiz.assignment.clone
            old_assignment.id = @quiz.assignment.id
          end

          @quiz.with_versioning(false) do
            # using attributes= here so we don't need to make an extra
            # database call to get the times right after save!
            @quiz.attributes = params[:quiz]
            @quiz.infer_times
            @quiz.content_being_saved_by(@current_user)
            @quiz.save!
          end

          batch_update_assignment_overrides(@quiz,overrides) unless overrides.nil?

          # quiz.rb restricts all assignment broadcasts if notify_of_update is
          # false, so we do the same here
          if @quiz.assignment.present? && (notify_of_update || old_assignment.due_at != @quiz.assignment.due_at)
            @quiz.assignment.do_notifications!(old_assignment, notify_of_update)
          end
          @quiz.reload
          @quiz.update_quiz_submission_end_at_times if params[:quiz][:time_limit].present?
        end
        flash[:notice] = t('notices.quiz_updated', "Quiz successfully updated")
        format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz) }
        format.json { render :json => @quiz.to_json(:include => {:assignment => {:include => :assignment_group}}) }
      end
    end
  rescue
    respond_to do |format|
      flash[:error] = t('errors.quiz_update_failed', "Quiz failed to update")
      format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz) }
      format.json { render :json => @quiz.errors.to_json, :status => :bad_request }
    end
  end

  def destroy
    if authorized_action(@quiz, @current_user, :delete)
      respond_to do |format|
        if @quiz.destroy
          format.html { redirect_to course_quizzes_url(@context) }
          format.json { render :json => @quiz.to_json }
        else
          format.html { redirect_to course_quiz_url(@context, @quiz) }
          format.json { render :json => @quiz.errors.to_json }
        end
      end
    end
  end

  def moderate
    if authorized_action(@quiz, @current_user, :grade)
      @all_students = @context.students_visible_to(@current_user).order_by_sortable_name
      if @quiz.survey? && @quiz.anonymous_submissions
        @students = @all_students.paginate(:per_page => 50, :page => params[:page], :order => :uuid)
      else
        @students = @all_students.paginate(:per_page => 50, :page => params[:page])
      end
      last_updated_at = Time.parse(params[:last_updated_at]) rescue nil
      @submissions = @quiz.quiz_submissions.updated_after(last_updated_at).for_user_ids(@students.map(&:id))
      respond_to do |format|
        format.html
        format.json { render :json => @submissions.to_json(:include_root => false, :except => [:submission_data, :quiz_data], :methods => ['extendable?', :finished_in_words, :attempts_left]) }
      end
    end
  end

  def force_user
    if !@current_user
      session[:return_to] = polymorphic_path([@context, @quiz])
      redirect_to login_path
    end
    return @current_user.present?
  end

  def setup_headless
    # persist headless state through take button and next/prev questions
    session[:headless_quiz] = true if value_to_boolean(params[:persist_headless])
    @headers = !params[:headless] && !session[:headless_quiz]
  end

  protected

  def get_quiz
    @quiz = @context.quizzes.find(params[:id] || params[:quiz_id])
    @quiz_name = @quiz.title
    @quiz
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
    end
    if quiz_submission_active?
      if request.get?
        # currently, the only way to start_quiz! with a get request is to use the LDB
        take_quiz
      else
        # redirect to avoid refresh issues
        redirect_to polymorphic_url([@context, @quiz, 'take'], quiz_redirect_params(:preview => params[:preview]))
      end
    else
      flash[:error] = t('errors.no_more_attempts', "You have no quiz attempts left") unless @just_graded
      redirect_to named_context_url(@context, :context_quiz_url, @quiz, quiz_redirect_params)
    end
  end

  def take_quiz
    return unless quiz_submission_active?
    log_asset_access(@quiz, "quizzes", "quizzes", 'participate')
    flash[:notice] = t('notices.less_than_allotted_time', "You started this quiz near when it was due, so you won't have the full amount of time to take the quiz.") if @submission.less_than_allotted_time?

    if params[:question_id] && !valid_question?(@submission, params[:question_id])
      redirect_to course_quiz_url(@context, @quiz) and return
    end

    @quiz_presenter = TakeQuizPresenter.new(@quiz, @submission, params)
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
    @any_submissions_pending_review = submitted_with_submissions.where("quiz_submissions.workflow_state = 'pending_review'").count > 0
  end
end
