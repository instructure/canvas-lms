module Quizzes
  class QuizSerializer < Canvas::APISerializer
    include LockedSerializer
    include PermissionsSerializer

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
                :speed_grader_url, :permissions, :quiz_reports_url, :quiz_statistics_url,
                :message_students_url, :quiz_submission_html_url, :section_count

    def_delegators :@controller,
      :api_v1_course_assignment_group_url,
      :speed_grader_course_gradebook_url,
      :api_v1_course_quiz_submission_url,
      :api_v1_course_quiz_submissions_url,
      :api_v1_course_quiz_reports_url,
      :api_v1_course_quiz_statistics_url,
      :course_quiz_submission_html_url,
      :api_v1_course_quiz_submission_users_url,
      :api_v1_course_quiz_submission_users_message_url

   def_delegators :@object,
     :context,
     :submitted_students_visible_to,
     :unsubmitted_students_visible_to

    has_one :assignment_group, embed: :ids, root: :assignment_group
    has_many :quiz_submissions, embed: :ids, root: :quiz_submissions
    has_many :submitted_students, embed: :ids, root: :submitted_students
    has_many :unsubmitted_students, embed: :ids, root: :unsubmitted_students

    def submitted_students
      user_finder.submitted_students
    end

    def unsubmitted_students
      user_finder.unsubmitted_students
    end

    def message_students_url
      api_v1_course_quiz_submission_users_message_url(context, quiz)
    end

    def speed_grader_url
      return nil unless show_speedgrader?
      speed_grader_course_gradebook_url(context, assignment_id: quiz.assignment.id)
    end

    def quiz_submissions_url
      if user_may_grade?
        api_v1_course_quiz_submissions_url(context, quiz)
      else
        if submission_for_current_user?
          api_v1_course_quiz_submission_url(quiz.context, quiz, submission_for_current_user)
        else
          nil
        end
      end
    end

    def unsubmitted_students_url
      api_v1_course_quiz_submission_users_url(context, quiz, submitted: 'false')
    end

    def submitted_students_url
      api_v1_course_quiz_submission_users_url(context, quiz, submitted: true)
    end

    def quiz_submission_html_url
      course_quiz_submission_html_url(context, quiz)
    end

    def html_url
      controller.send(:course_quiz_url, context, quiz)
    end

    def mobile_url
      controller.send(:course_quiz_url, context, quiz, persist_headless: 1, force_user: 1)
    end

    def all_dates
      quiz.formatted_dates_hash(due_dates[1])
    end

    def section_count
      context.active_course_sections.count
    end

    def locked_for_json_type; 'quiz' end

    # Teacher or Observer?
    def include_all_dates?
      due_dates[1].present?
    end

    def include_unpublishable?
      quiz.grants_right?(current_user, session, :manage)
    end

    def filter(keys)
      super(keys).select do |key|
        case key
        when :all_dates then include_all_dates?
        when :section_count then user_may_grade?
        when :access_code, :speed_grader_url, :message_students_url then user_may_grade?
        when :unpublishable then include_unpublishable?
        when :submitted_students, :unsubmitted_students then user_may_grade?
        when :quiz_submission_html_url then accepts_jsonapi?
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
      else
        # since we're not embedding QuizStatistics as an association because
        # the statistics objects are built on-demand when the endpoint is
        # requested, and we only need the link, we'll have to assign it manually
        hash['links']['quiz_statistics'] = hash.delete(:quiz_statistics_url)
        hash['links']['quiz_reports'] = hash.delete(:quiz_reports_url)
      end
      hash
    end

    def assignment_group_url
      api_v1_course_assignment_group_url(context, quiz.assignment_group.id)
    end

    def quiz_reports_url
      api_v1_course_quiz_reports_url(quiz.context, quiz)
    end

    def quiz_statistics_url
      api_v1_course_quiz_statistics_url(quiz.context, quiz)
    end

    def stringify_ids?
      !!(accepts_jsonapi? || stringify_json_ids?)
    end

    private

    def show_speedgrader?
      quiz.assignment.present? && quiz.published? && context.allows_speed_grader?
    end

    def due_dates
      @due_dates ||= quiz.due_dates_for(current_user)
    end

    # If the current user is a student and is in a course section which has
    # an assignment override, the date will be that of the section's, otherwise
    # we will use the Quiz's.
    #
    # @param [:due_at|:lock_at|:unlock_at] domain
    def overridden_date(domain)
      due_dates[0] ? due_dates[0][domain] : quiz.send(domain)
    end

    def due_at
      overridden_date :due_at
    end

    def lock_at
      overridden_date :lock_at
    end

    def unlock_at
      overridden_date :unlock_at
    end

    def user_may_grade?
      quiz.grants_right?(current_user, session, :grade)
    end

    def user_finder
      @user_finder ||= Quizzes::QuizUserFinder.new(quiz, current_user)
    end

    def submission_for_current_user
      @submission_for_current_user ||= (
        quiz.quiz_submissions.where(user_id: current_user).first
      )
    end

    def submission_for_current_user?
      !!submission_for_current_user
    end

  end
end
