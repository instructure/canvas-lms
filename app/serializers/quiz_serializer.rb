require File.expand_path(File.dirname(__FILE__) + '/canvas_api_serializer')

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
              :hide_correct_answers_at, :all_dates

  has_one :assignment_group, embed: :ids

  def html_url
    polymorphic_url([context, quiz])
  end

  def mobile_url
    polymorphic_url([context, quiz], persist_headless: 1, force_user: 1)
  end

  def all_dates
    quiz.dates_hash_visible_to user
  end

  def locked_for_json_type; 'quiz' end

  def filter(keys)
    rejected = []
    rejected << :all_dates unless quiz.grants_right?(current_user, session, :update)
    rejected << :access_code unless quiz.grants_right?(current_user, session, :grade)
    rejected << :unpublishable unless quiz.grants_right?(current_user, session, :manage)
    super(keys) - rejected
  end

  def question_count
    quiz.available_question_count
  end

  def serializable_object(options={})
    hash = super(options)
    if (accepts_jsonapi? && id = hash.delete('assignment_group_id'))
        hash[:links] ||= {}
        hash[:links][:assignment_group] = controller.send(:api_v1_course_assignment_group_url, quiz.context, id)
    end
    hash
  end
end
