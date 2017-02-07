class ToDoListPresenter
  ASSIGNMENT_LIMIT = 100
  VISIBLE_LIMIT = 5

  attr_reader :needs_grading, :needs_moderation, :needs_submitting, :needs_reviewing

  def initialize(view, user, contexts)
    @view = view
    @user = user
    @contexts = contexts

    if user
      @needs_grading = assignments_needing(:grading)
      @needs_moderation = assignments_needing(:moderation)
      @needs_submitting = assignments_needing(:submitting, include_ungraded: true)
      @needs_submitting += ungraded_quizzes_needing_submitting
      @needs_submitting.sort_by! { |a| a.due_at || a.updated_at }
      assessment_requests = user.submissions_needing_peer_review(contexts: contexts, limit: ASSIGNMENT_LIMIT)
      @needs_reviewing = assessment_requests.map do |ar|
        AssessmentRequestPresenter.new(view, ar, user) if ar.asset.assignment.published?
      end.compact
    else
      @needs_grading = []
      @needs_moderation = []
      @needs_submitting = []
      @needs_reviewing = []
    end
  end

  def assignments_needing(type, opts = {})
    if @user
      @user.send("assignments_needing_#{type}", {contexts: @contexts, limit: ASSIGNMENT_LIMIT}.merge(opts)).map do |assignment|
        AssignmentPresenter.new(@view, assignment, @user, type)
      end
    else
      []
    end
  end

  def ungraded_quizzes_needing_submitting
    @user.ungraded_quizzes_needing_submitting(contexts: @contexts, limit: ASSIGNMENT_LIMIT).map do |quiz|
      AssignmentPresenter.new(@view, quiz, @user, :submitting)
    end
  end

  def any_assignments?
    @user && (
      @needs_grading.present? ||
      @needs_moderation.present? ||
      @needs_submitting.present? ||
      @needs_reviewing.present?
    )
  end

  # False when there's only one context (no point in showing its name beneath each assignment), true otherwise.
  def show_context?
    @contexts.nil? || @contexts.length > 1
  end

  def visible_limit
    VISIBLE_LIMIT
  end

  def hidden_count_for(items)
    if items.length > visible_limit
      items.length - visible_limit
    else
      0
    end
  end

  def hidden_count
    @hidden_count ||= [needs_grading, needs_moderation, needs_submitting, needs_reviewing].sum do |items|
      hidden_count_for(items)
    end
  end

  class AssignmentPresenter
    attr_reader :assignment
    protected :assignment
    delegate :title, :submission_action_string, :points_possible, :due_at, :updated_at, :peer_reviews_due_at, to: :assignment

    def initialize(view, assignment, user, type)
      @view = view
      @assignment = assignment
      @assignment = @assignment.overridden_for(user) if type == :submitting
      @user = user
      @type = type
    end

    def needs_moderation_icon_data
      @view.icon_data(context: assignment.context, current_user: @user, recent_event: assignment)
    end

    def needs_submitting_icon_data
      @view.icon_data(context: assignment.context, current_user: @user, recent_event: assignment, student_only: true)
    end

    def context_name
      @assignment.context.nickname_for(@user)
    end

    def short_context_name
      @assignment.context.nickname_for(@user, :short_name)
    end

    def needs_grading_count
      @needs_grading_count ||= Assignments::NeedsGradingCountQuery.new(@assignment, @user).count
    end

    def needs_grading_badge
      if needs_grading_count > 999
        I18n.t('%{more_than}+', more_than: 999)
      else
        needs_grading_count
      end
    end

    def needs_grading_label
      if needs_grading_count > 999
        I18n.t('More than 999 submissions need grading')
      else
        I18n.t({one: '1 submission needs grading', other: '%{count} submissions need grading'}, count: assignment.needs_grading_count)
      end
    end

    def gradebook_path
      @view.speed_grader_course_gradebook_path(assignment.context_id, assignment_id: assignment.id)
    end

    def moderate_path
      @view.course_assignment_moderate_path(assignment.context_id, assignment)
    end

    def assignment_path
      if assignment.is_a?(Quizzes::Quiz)
        @view.course_quiz_path(assignment.context_id, assignment.id)
      else
        @view.course_assignment_path(assignment.context_id, assignment.id)
      end
    end

    def ignore_url
      @view.todo_ignore_api_url(@type, @assignment)
    end

    def ignore_title
      case @type
      when :grading
        I18n.t('Ignore until new submission')
      when :moderation
        I18n.t('Ignore until new mark')
      when :submitting
        I18n.t('Ignore this assignment')
      end
    end

    def ignore_sr_message
      case @type
      when :grading
        I18n.t('Ignore %{item} until new submission', :item => title)
      when :moderation
        I18n.t('Ignore %{item} until new mark', :item => title)
      when :submitting
        I18n.t('Ignore %{item}', :item => title)
      end
    end

    def ignore_flash_message
      case @type
      when :grading
        I18n.t('This item will reappear when a new submission is made.')
      when :moderation
        I18n.t('This item will reappear when there are new grades to moderate.')
      end
    end

    def formatted_due_date
      @view.due_at(assignment, @user)
    end

    def formatted_peer_review_due_date
      if assignment.peer_reviews_due_at
        @view.datetime_string(assignment.peer_reviews_due_at)
      else
        I18n.t('No Due Date')
      end
    end
  end

  class AssessmentRequestPresenter
    delegate :context_name, to: :assignment_presenter
    delegate :short_context_name, to: :assignment_presenter
    attr_reader :assignment

    def initialize(view, assessment_request, user)
      @view = view
      @assessment_request = assessment_request
      @user = user
      @assignment = assessment_request.asset.assignment
    end

    def published?
      @assessment_request.asset.assignment.published?
    end

    def assignment_presenter
      AssignmentPresenter.new(@view, @assignment, @user, :reviewing)
    end

    def submission_path
      @view.course_assignment_submission_path(@assignment.context_id, @assignment.id, @assessment_request.user_id)
    end

    def ignore_url
      @view.todo_ignore_api_url('reviewing', @assessment_request)
    end

    def ignore_title
      I18n.t('Ignore this assignment')
    end

    def ignore_sr_message
      I18n.t('Ignore %{assignment}', :assignment => @assignment.title)
    end

    def ignore_flash_message
    end

    def submission_author_name
      @view.submission_author_name_for(@assessment_request, "#{I18n.t('user')}: ")
    end
  end
end
