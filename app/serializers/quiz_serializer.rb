class QuizSerializer < Canvas::APISerializer
  include LockedSerializer

  root :quiz

  attributes :id, :title, :html_url, :mobile_url, :description, :quiz_type,
              :time_limit, :shuffle_answers, :show_correct_answers,
              :scoring_policy, :allowed_attempts, :one_question_at_a_time,
              :question_count, :points_possible, :cant_go_back,
              :access_code, :ip_filter, :due_at, :lock_at, :unlock_at,
              :published, :unpublishable, :locked_for_user, :lock_info,
              :lock_explanation, :hide_results, :show_correct_answers_at,
              :hide_correct_answers_at, :all_dates, :can_unpublish, :can_update,
              :require_lockdown_browser, :require_lockdown_browser_for_results,
              :require_lockdown_browser_monitor, :lockdown_browser_monitor_data,
              :speed_grader_url

  def_delegators :@controller,
    :api_v1_course_assignment_group_url,
    :speed_grader_course_gradebook_url

  has_one :assignment_group, embed: :ids, key: :assignment_group

  def speed_grader_url
    return nil unless show_speedgrader?
    speed_grader_course_gradebook_url(quiz.context, assignment_id: quiz.assignment.id)
  end

  def html_url
    controller.send(:course_quiz_url, context, quiz)
  end

  def mobile_url
    controller.send(:course_quiz_url, context, quiz, persist_headless: 1, force_user: 1)
  end

  def all_dates
    quiz.dates_hash_visible_to user
  end

  def locked_for_json_type; 'quiz' end

  def include_all_dates?
    quiz.grants_right?(current_user, session, :update)
  end

  def include_grading_attribute?
    quiz.grants_right?(current_user, session, :grade)
  end

  def include_unpublishable?
    quiz.grants_right?(current_user, session, :manage)
  end

  def filter(keys)
    super(keys).select do |key|
      case key
      when :all_dates then include_all_dates?
      when :access_code, :speed_grader_url then include_grading_attribute?
      when :unpublishable then include_unpublishable?
      else true
      end
    end
  end

  def can_unpublish
    quiz.can_unpublish?
  end

  def can_update
    quiz.grants_right?(current_user, session, :update)
  end

  def question_count
    quiz.available_question_count
  end
  
  def require_lockdown_browser
    quiz.require_lockdown_browser?
  end
  
  def require_lockdown_browser_for_results
    quiz.require_lockdown_browser_for_results?
  end
  
  def require_lockdown_browser_monitor
    quiz.require_lockdown_browser_monitor?
  end
  
  def lockdown_browser_monitor_data
    quiz.lockdown_browser_monitor_data
  end

  def serializable_object(options={})
    hash = super(options)
    # legacy v1 api
    unless accepts_jsonapi?
      links = hash.delete('links')
      id = hash['assignment_group']
      hash['assignment_group_id'] = quiz.assignment_group.try(:id)
    end
    hash
  end

  def assignment_group_url
    api_v1_course_assignment_group_url(quiz.context, quiz.assignment_group.id)
  end

  def stringify_ids?
    !!(accepts_jsonapi? || stringify_json_ids?)
  end

  private

  def show_speedgrader?
    quiz.assignment.present? && quiz.published? && quiz.context.allows_speed_grader?
  end

end
