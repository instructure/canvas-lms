class Quizzes::TakeQuizPresenter
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  attr_accessor :quiz,
    :submission,
    :params,
    :submission_data,
    :answers

  def initialize(quiz, submission, params)
    self.quiz = quiz
    self.submission = submission
    self.params = params

    self.submission_data = submission.temporary_data
    self.answers = resolve_answers
  end

  def current_questions
    @current_questions ||= if quiz.cant_go_back?
      question_ids = all_questions.map { |question| question[:id] }
      first_unread_question = question_ids.detect{ |question_id|
        !submission_data[:"_question_#{question_id}_read"]
      }
      [submission.question(first_unread_question)]
    elsif params[:question_id]
      [submission.question(params[:question_id])]
    elsif one_question_at_a_time?
      [all_questions.first]
    else
      all_questions
    end.compact
  end

  def all_questions
    @all_questions ||= submission.questions_as_object.compact
  end

  def one_question_at_a_time?
    quiz.one_question_at_a_time?
  end

  def previous_question_viewable?
    previous_question && !cant_go_back?
  end

  def last_page?
    next_question.nil? || !one_question_at_a_time?
  end

  def cant_go_back?
    quiz.cant_go_back?
  end

  def can_go_back?
    !cant_go_back?
  end

  def require_lockdown_browser?
    quiz.require_lockdown_browser?
  end

  def form_class
    classes = []
    classes << (one_question_at_a_time? ? "one_question_at_a_time" : "all_questions")
    classes << "cant_go_back" if cant_go_back?
    classes << "last_page" if last_page?
    classes.join(' ')
  end

  def question_class(q)
    classes = ["list_question"]
    classes << "answered" if question_answered?(q)
    classes << "marked" if marked?(q)
    classes << "seen" if question_seen?(q)
    classes << "current_question" if one_question_at_a_time? && current_question?(q)
    classes << "text_only" if text_only?(q)
    classes.join(' ')
  end

  def marked?(q)
    submission_data["question_#{q[:id]}_marked"].present?
  end

  def text_only?(q)
    q['question_type'] == "text_only_question"
  end

  def answered_icon(q)
    question_answered?(q) ? 'icon-check' : 'icon-question'
  end

  def answered_text(q)
    if question_answered?(q)
      I18n.t('question_answered', 'Answered')
    else
      I18n.t('question_unanswered', 'Haven\'t Answered Yet')
    end
  end

  def marked_text(q)
    if marked?(q)
      I18n.t('titles.come_back_later', 'You marked this question to come back to later')
    end
  end

  def current_question?(question)
    question[:id] == current_question[:id]
  end

  def current_question
    current_questions.first
  end

  def question_seen?(question)
    question_index(question) <= question_index(current_question)
  end

  def question_answered?(question)
    answers.has_key?(question[:id])
  end

  def question_index(question)
    all_questions.index { |q| q[:id] == question[:id] }
  end

  def last_question?
    current_question == all_questions.last
  end

  def next_question
    neighboring_question(:next)
  end

  def previous_question
    neighboring_question(:previous)
  end

  def neighboring_question(direction)
    if current_index = all_questions.index(current_question)
      modifier = (direction == :next) ? 1 : -1
      neighbor_index = current_index + modifier
      all_questions[neighbor_index] if neighbor_index >= 0
    end
  end

  def next_question_path
    question_path next_question[:id]
  end

  def previous_question_path
    question_path previous_question[:id]
  end

  def question_path(id)
    ps = { :course_id => quiz.context.id, :quiz_id => quiz.id, :question_id => id }
    ps[:preview] = true if params[:preview]
    course_quiz_question_path(ps)
  end

  def form_action(session,user)
    if one_question_at_a_time? && next_question
      next_question_form_action(session, user)
    else
      submit_form_action(session, user)
    end
  end

  def submit_form_action(session, user)
    course_quiz_quiz_submissions_path(quiz.context, quiz, form_action_params(session, user))
  end

  def next_question_form_action(session, user)
    record_answer_course_quiz_quiz_submission_path(
      quiz.context, quiz, submission, form_action_params(session, user).merge({
        :next_question_path => next_question_path
      })
    )
  end

  def previous_question_form_action(session, user)
    record_answer_course_quiz_quiz_submission_path(
      quiz.context, quiz, submission, form_action_params(session, user).merge({
        :next_question_path => previous_question_path
      })
    )
  end

  def form_action_params(session, user)
    url_params = { :user_id => user && user.id }
    if session['lockdown_browser_popup']
      url_params.merge!(Canvas::LockdownBrowser.plugin.base.quiz_exit_params)
    end
    url_params
  end
  private :form_action_params

  # Build an optimized set of the so-far answered questions for quick access.
  #
  # The output set will filter out the following:
  #   - any entry that does not contain a "question" phrase
  #   - entries like 'question_x_marked'
  #   - entries like '_question_x_read'
  #   - entries with a value 0
  #   - entries with no value (entry#present? returns false)
  #
  # The output set keys will be the question id (in integer format) and the value
  # is meaningless; if the key exists, then the question is answered.
  def resolve_answers(dataset = submission_data)
    # get all the question status-entries and group them by the question id
    _answers = dataset.keys.group_by do |k|
      k =~ /question_(\d+)/ ? $1.to_i : :irrelevant
    end

    # remove any non-question keys we've collected
    _answers.delete(:irrelevant)

    # discard "marked" or "read" entries
    _answers.each_pair do |_, status_entries|
      status_entries.reject! { |status| status =~ /_(marked|read)$/ }
    end

    _answers.reject! do |_, status_entries|
      # an answer must not be falsy/empty
      status_entries.any? { |status| !dataset[status].present? } ||
      # all zeroes for an answer is a no-answer
      status_entries.all? { |status| dataset[status] == '0' }
    end

    _answers
  end
  private :resolve_answers

end
