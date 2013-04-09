class TakeQuizPresenter
  include ActionController::UrlWriter
  include ApplicationHelper

  attr_accessor :quiz, :submission, :params

  def initialize(quiz, submission, params)
    self.quiz = quiz
    self.submission = submission
    self.params = params
  end

  def current_questions
    questions = if quiz.cant_go_back?
      questions_ids = @submission.quiz_data.map{|s| s[:id] }
      first_unread_question = questions_ids.detect{ |question_id|
        !@submission.submission_data[:"_question_#{question_id}_read"]
      }
      [submission.question(first_unread_question)]
    elsif params[:question_id]
      [submission.question(params[:question_id])]
    elsif one_question_at_a_time?
      [all_questions.first]
    else
      all_questions
    end

    questions.compact
  end

  def all_questions
    submission.questions_as_object.compact
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
    classes << "answered" if submission.question_answered?(q[:id])
    classes << "marked" if submission.submission_data["question_#{q[:id]}_marked"].present?
    classes << "seen" if question_seen?(q)
    classes << "current_question" if one_question_at_a_time? && current_question?(q) 
    classes.join(' ')
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
    submission.question_answered?(question[:id])
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
    polymorphic_path(
      [quiz.context,quiz,:quiz_submissions],
      form_action_params(session, user)
    )
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
      url_params.merge!(Canvas::LockdownBrowser.plugin.base.quiz_exit_params({}))
    end
    url_params
  end
  private :form_action_params

end
