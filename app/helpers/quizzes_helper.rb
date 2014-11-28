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

module QuizzesHelper
  RE_EXTRACT_BLANK_ID = /['"]question_\w+_(.*?)['"]/

  def needs_unpublished_warning?(quiz=@quiz, user=@current_user)
    if quiz.feature_enabled?(:draft_state)
      return false unless can_publish(quiz)
      show_unpublished_changes = true
    else
      return false unless can_read(quiz)
      show_unpublished_changes = can_publish(quiz)
    end

    !quiz.available? || (show_unpublished_changes && quiz.unpublished_changes?)
  end

  def can_read(quiz, user=@current_user)
    can_do(quiz, user, :read)
  end

  def can_publish(quiz, user=@current_user)
    can_do(quiz, user, :update) || can_do(quiz, user, :manage)
  end

  def unpublished_quiz_warning
    I18n.t("#quizzes.warnings.unpublished_quiz",
      '*This quiz is unpublished* Only teachers can see the quiz until ' +
      'it is published.',
      :wrapper => '<strong class=unpublished_quiz_warning>\1</strong>')
  end

  def unpublished_changes_warning
    I18n.t("#quizzes.warnings.unpublished_changes",
      '*You have made unpublished changes to this quiz.* '+
      'These changes will not appear for students until you publish or ' +
      'republish the quiz.',
      :wrapper => '<strong class=unpublished_quiz_warning>\1</strong>')
  end

  def draft_state_unsaved_changes_warning
    I18n.t("#quizzes.warnings.draft_state_unsaved_changes",
      '*You have made changes to the questions in this quiz.* '+
      'These changes will not appear for students until you ' +
      'save the quiz.',
      :wrapper => '<strong class=unsaved_quiz_warning>\1</strong>')
  end

  def quiz_published_state_warning(quiz=@quiz)
    if !quiz.available?
      unpublished_quiz_warning
    else
      if quiz.feature_enabled? :draft_state
        draft_state_unsaved_changes_warning
      else
        unpublished_changes_warning
      end
    end
  end

  def display_save_button?(quiz=@quiz)
    quiz.available? && quiz.feature_enabled?(:draft_state) && can_publish(quiz)
  end

  def render_score(score, precision=2)
    if score.nil?
      '_'
    else
      score.to_f.round(precision).to_s
    end
  end

  def render_quiz_type(quiz_type)
    case quiz_type
    when "practice_quiz"
      I18n.t('#quizzes.practice_quiz', "Practice Quiz")
    when "assignment"
      I18n.t('#quizzes.graded_quiz', "Graded Quiz")
    when "graded_survey"
      I18n.t('#quizzes.graded_survey', "Graded Survey")
    when "survey"
      I18n.t('#quizzes.ungraded_survey', "Ungraded Survey")
    end
  end

  def render_score_to_keep(quiz_scoring_policy)
    case quiz_scoring_policy
    when "keep_highest"
      I18n.t('#quizzes.keep_highest', 'Highest')
    when "keep_latest"
      I18n.t('#quizzes.keep_latest', 'Latest')
    end
  end

  def render_show_correct_answers(quiz)
    if !quiz.show_correct_answers
      return I18n.t('#options.no', 'No')
    end

    show_at = quiz.show_correct_answers_at
    hide_at = quiz.hide_correct_answers_at

    if show_at && hide_at
      I18n.t('#quizzes.show_and_hide_correct_answers', 'From %{from} to %{to}', {
        from: datetime_string(quiz.show_correct_answers_at),
        to: datetime_string(quiz.hide_correct_answers_at)
      })
    elsif show_at
      I18n.t('#quizzes.show_correct_answers_after', 'After %{date}', {
        date: datetime_string(quiz.show_correct_answers_at)
      })
    elsif hide_at
      I18n.t('#quizzes.show_correct_answers_until', 'Until %{date}', {
        date: datetime_string(quiz.hide_correct_answers_at)
      })
    else
      I18n.t('#quizzes.show_correct_answers_immediately', 'Immediately')
    end
  end

  def render_correct_answer_protection(quiz)
    show_at = quiz.show_correct_answers_at
    hide_at = quiz.hide_correct_answers_at
    now = Time.now

    # Some labels will be used in more than one case, so we'll pre-define them.
    labels = {}
    if hide_at
      labels[:available_until] = I18n.t('#quizzes.correct_answers_shown_until',
        'Correct answers are available until %{date}.', {
        date: datetime_string(quiz.hide_correct_answers_at)
      })
    end

    if !quiz.show_correct_answers
      I18n.t('#quizzes.correct_answers_protected',
        'Correct answers are hidden.')
    elsif hide_at.present? && hide_at < now
      I18n.t('#quizzes.correct_answers_no_longer_available',
        'Correct answers are no longer available.')
    elsif show_at.present? && hide_at.present?
      # If the answers are currently visible, there's no need to show the range
      # of availability.
      if now > show_at
        labels[:available_until]
      else
        I18n.t('#quizzes.correct_answers_shown_between',
          'Correct answers will be available %{from} - %{to}.', {
            from: datetime_string(show_at),
            to: datetime_string(hide_at)
          })
      end
    elsif show_at.present?
      I18n.t('#quizzes.correct_answers_shown_after',
        'Correct answers will be available on %{date}.', {
          date: datetime_string(show_at)
        })
    elsif hide_at.present?
      labels[:available_until]
    end
  end

  def render_show_responses(quiz_hide_results)
    # "Let Students See Their Quiz Responses?"
    case quiz_hide_results
    when "always"
      I18n.t('#options.no', "No")
    when "until_after_last_attempt"
      I18n.t('#quizzes.after_last_attempt', "After Last Attempt")
    when nil
      I18n.t('#quizzes.always', "Always")
    end
  end

  def submitted_students_title(quiz, students, logged_out)
    length = students.length + logged_out.length
    if quiz.survey?
      submitted_students_survey_title(length)
    else
      submitted_students_quiz_title(length)
    end
  end

  def submitted_students_quiz_title(student_count)
    I18n.t('#quizzes.headers.submitted_students_quiz_title',
      { :zero => "Students who have taken the quiz",
        :one => "Students who have taken the quiz (%{count})",
        :other => "Students who have taken the quiz (%{count})" },
      { :count => student_count })
  end

  def submitted_students_survey_title(student_count)
    I18n.t('#quizzes.headers.submitted_students_survey_title',
      { :zero => "Students who have taken the survey",
        :one => "Students who have taken the survey (%{count})",
        :other => "Students who have taken the survey (%{count})" },
      { :count => student_count })
  end

  def no_submitted_students_msg(quiz)
    if quiz.survey?
      t('#quizzes.messages.no_submitted_students_survey', "No Students have taken the survey yet")
    else
      t('#quizzes.messages.no_submitted_students_quiz', "No Students have taken the quiz yet")
    end
  end

  def unsubmitted_students_title(quiz, students)
    if quiz.survey?
      unsubmitted_students_survey_title(students.length)
    else
      unsubmitted_students_quiz_title(students.length)
    end
  end

  def unsubmitted_students_quiz_title(student_count)
    I18n.t('#quizzes.headers.unsubmitted_students_quiz_title',
      { :zero => "Student who haven't taken the quiz",
        :one => "Students who haven't taken the quiz (%{count})",
        :other => "Students who haven't taken the quiz (%{count})" },
      { :count => student_count })
  end

  def unsubmitted_students_survey_title(student_count)
    I18n.t('#quizzes.headers.unsubmitted_students_survey_title',
      { :zero => "Student who haven't taken the survey",
        :one => "Students who haven't taken the survey (%{count})",
        :other => "Students who haven't taken the survey (%{count})" },
      { :count => student_count })
  end

  def no_unsubmitted_students_msg(quiz)
    if quiz.survey?
      t('#quizzes.messages.no_unsubmitted_students_survey', "All Students have taken the survey")
    else
      t('#quizzes.messages.no_unsubmitted_students_quiz', "All Students have taken the quiz")
    end
  end

  def render_result_protection(quiz, submission)
    if quiz.one_time_results && submission.has_seen_results?
      I18n.t(:quiz_results_protected_after_first_glimpse, "Quiz results are protected for this quiz and can be viewed a single time immediately after submission.")
    elsif quiz.hide_results == 'until_after_last_attempt'
      I18n.t(:quiz_results_protected_until_last_attempt, "Quiz results are protected for this quiz and are not visible to students until they have submitted their last attempt.")
    else
      I18n.t(:quiz_results_protected, "Quiz results are protected for this quiz and are not visible to students.")
    end
  end

  QuestionType = Struct.new(:question_type,
                            :entry_type,
                            :display_answers,
                            :answer_type,
                            :multiple_sets,
                            :unsupported)

  def answer_type(question)
    return QuestionType.new unless question
    @answer_types_lookup ||= {
      "multiple_choice_question" => QuestionType.new(
        "multiple_choice_question",
        "radio",
        "multiple",
        "select_answer",
        false,
        false
      ),
      "true_false_question" => QuestionType.new(
        "true_false_question",
        "radio",
        "multiple",
        "select_answer",
        false,
        false
      ),
      "short_answer_question" => QuestionType.new(
        "short_answer_question",
        "text_box",
        "single",
        "select_answer",
        false,
        false
      ),
      "essay_question" => QuestionType.new(
        "essay_question",
        "textarea",
        "single",
        "text_answer",
        false,
        false
      ),
      "file_upload_question" => QuestionType.new(
        "file_upload_question",
        "file",
        "single",
        "file_answer",
        false,
        false
      ),
      "matching_question" => QuestionType.new(
        "matching_question",
        "matching",
        "multiple",
        "matching_answer",
        false,
        false
      ),
      "missing_word_question" => QuestionType.new(
        "missing_word_question",
        "select",
        "multiple",
        "select_answer",
        false,
        false
      ),
      "numerical_question" => QuestionType.new(
        "numerical_question",
        "numerical_text_box",
        "single",
        "numerical_answer",
        false,
        false
      ),
      "calculated_question" => QuestionType.new(
        "calculated_question",
        "numerical_text_box",
        "single",
        "numerical_answer",
        false,
        false
      ),
      "multiple_answers_question" => QuestionType.new(
        "multiple_answers_question",
        "checkbox",
        "multiple",
        "select_answer",
        false,
        false
      ),
      "fill_in_multiple_blanks_question" => QuestionType.new(
        "fill_in_multiple_blanks_question",
        "text_box",
        "multiple",
        "select_answer",
        true,
        false
      ),
      "multiple_dropdowns_question" => QuestionType.new(
        "multiple_dropdowns_question",
        "select",
        "none",
        "select_answer",
        true,
        false
      ),
      "other" =>  QuestionType.new(
        "text_only_question",
        "none",
        "none",
        "none",
        false,
        false
      )
    }
    res = @answer_types_lookup[question[:question_type]] || @answer_types_lookup["other"]
    if res.question_type == "text_only_question"
      res.unsupported = question[:question_type] != "text_only_question"
    end
    res
  end

  # Build the question-level comments. Lists in the order of :correct_comments, :incorrect_comments, :neutral_comments.
  # ==== Arguments
  # * <tt>user_answer</tt> - The user_answer hash.
  # * <tt>question</tt> - The question hash.
  def question_comment(user_answer, question)
    correct_text   = (hash_get(user_answer, :correct) == true) ? comment_get(question, :correct_comments) : nil
    incorrect_text = (hash_get(user_answer, :correct) == false) ? comment_get(question, :incorrect_comments) : nil
    neutral_text   = (hash_get(question, :neutral_comments).present?) ? comment_get(question, :neutral_comments) : nil

    text = []
    text << content_tag(:p, correct_text, {:class => 'correct_comments'}) if correct_text.present?
    text << content_tag(:p, incorrect_text, {:class => 'incorrect_comments'}) if incorrect_text.present?
    text << content_tag(:p, neutral_text, {:class => 'neutral_comments'}) if neutral_text.present?
    if text.empty?
      ''
    else
      content_tag(:div, text.join('').html_safe, {:class => 'quiz_comment'})
    end
  end

  def comment_get(hash, field)
    if html = hash_get(hash, "#{field}_html".to_sym)
      raw(html)
    else
      hash_get(hash, field)
    end
  end

  # @param [Array<Hash>] options.answer_list
  #   A set of question blanks and the student response for each. Example:
  #   [{ blank_id: "color", "answer": "red" }]
  def fill_in_multiple_blanks_question(options)
    question = hash_get(options, :question)
    answers  = hash_get(options, :answers).dup
    answer_list = hash_get(options, :answer_list, [])
    res      = user_content hash_get(question, :question_text)
    readonly_markup = hash_get(options, :editable) ? " />" : 'readonly="readonly" />'
    label_attr = "aria-label='#{I18n.t('#quizzes.labels.multiple_blanks_question', "Fill in the blank, read surrounding text")}'"

    answer_list.each do |entry|
      entry[:blank_id] = AssessmentQuestion.variable_id(entry[:blank_id])
    end
    res.gsub! %r{<input.*?name=\\?['"](question_.*?)\\?['"].*?>} do |match|
      blank = match.match(RE_EXTRACT_BLANK_ID).to_a[1]
      blank.gsub!(/\\/,'')
      answer = answer_list.detect { |entry| entry[:blank_id] == blank } || {}
      answer = h(answer[:answer] || '')

      # If given answer list, insert the values into the text inputs for displaying user's answers.
      if answer_list.any?
        #  Replace the {{question_BLAH}} template text with the user's answer text.
        match = match.sub(/\{\{question_.*?\}\}/, answer.to_s).
          # Match on "/>" but only when at the end of the string and insert "readonly" if set to be readonly
          sub(/\/*>\Z/, readonly_markup)
      end
      # add labelling to input element regardless
      match.sub(/\/*>\Z/, "#{label_attr} />")
    end

    if answer_list.empty?
      answers.delete_if { |k, v| !k.match /^question_#{hash_get(question, :id)}/ }
      answers.each { |k, v| res.sub! /\{\{#{k}\}\}/, h(v) }
      res.gsub! /\{\{question_[^}]+\}\}/, ""
    end

    # all of our manipulation lost this flag - reset it
    res.html_safe
  end

  def multiple_dropdowns_question(options)
    question = hash_get(options, :question)
    answers  = hash_get(options, :answers)
    answer_list = hash_get(options, :answer_list)
    res      = user_content hash_get(question, :question_text)
    index  = 0
    res.to_str.gsub %r{<select.*?name=['"](question_.*?)['"].*?>.*?</select>} do |match|
      if answer_list && !answer_list.empty?
        a = answer_list[index]
        index += 1
      else
        a = hash_get(answers, $1)
      end
      match.sub(%r{(<option.*?value=['"]#{ERB::Util.h(a)}['"])}, '\\1 selected')
    end.html_safe
  end

  def duration_in_minutes(duration_seconds)
    if duration_seconds < 60
      duration_minutes = 0
    else
      duration_minutes = (duration_seconds / 60).round
    end
    I18n.t("quizzes.helpers.duration_in_minutes",
      { :zero => "less than 1 minute",
        :one => "1 minute",
        :other => "%{count} minutes" },
      :count => duration_minutes)
  end

  def score_out_of_points_possible(score, points_possible, options={})
    options.reverse_merge!({ :precision => 2 })
    score_html = \
      if options[:id] or options[:class] or options[:style] then
        content_tag('span',
          render_score(score, options[:precision]),
          options.slice(:class, :id, :style))
      else
        render_score(score, options[:precision])
      end
    I18n.t("quizzes.helpers.score_out_of_points_possible", "%{score} out of %{points_possible}",
        :score => score_html,
        :points_possible => render_score(points_possible, options[:precision]))
  end

  def link_to_take_quiz(link_body, opts={})
    opts = opts.with_indifferent_access
    class_array = (opts['class'] || "").split(" ")
    class_array << 'element_toggler' if @quiz.cant_go_back?
    opts['class'] = class_array.compact.join(" ")
    opts['aria-controls'] = 'js-sequential-warning-dialogue' if @quiz.cant_go_back?
    opts['data-method'] = 'post' unless @quiz.cant_go_back?
    link_to(link_body, take_quiz_url, opts)
  end

  def take_quiz_url
    user_id = @current_user && @current_user.id
    course_quiz_take_path(@context, @quiz, user_id: user_id)
  end

  def link_to_take_or_retake_poll(opts={})
    if @submission && !@submission.settings_only?
      link_to_retake_poll(opts)
    else
      link_to_take_poll(opts)
    end
  end

  def link_to_take_poll(opts={})
    link_to_take_quiz(take_poll_message, opts)
  end

  def link_to_retake_poll(opts={})
    link_to_take_quiz(retake_poll_message, opts)
  end

  def link_to_resume_poll(opts = {})
    link_to_take_quiz(resume_poll_message, opts)
  end

  def take_poll_message(quiz=@quiz)
    quiz.survey? ?
      t('#quizzes.links.take_the_survey', 'Take the Survey') :
      t('#quizzes.links.take_the_quiz', 'Take the Quiz')
  end

  def retake_poll_message(quiz=@quiz)
    quiz.survey? ?
      t('#quizzes.links.take_the_survey_again', 'Take the Survey Again') :
      t('#quizzes.links.take_the_quiz_again', 'Take the Quiz Again')
  end

  def resume_poll_message(quiz=@quiz)
    quiz.survey? ?
      t('#quizzes.links.resume_survey', 'Resume Survey') :
      t('#quizzes.links.resume_quiz', 'Resume Quiz')
  end

  def attachment_id_for(question)
    attach = attachment_for(question)
    attach[:id] if attach.present?
  end

  def attachment_for(question)
    key = "question_#{question[:id]}"
    @attachments[@stored_params[key].try(:first).to_i]
  end

  def score_to_keep_message(quiz=@quiz)
    quiz.scoring_policy == "keep_highest" ?
      t('#quizzes.links.will_keep_highest_score', "Will keep the highest of all your scores") :
      t('#quizzes.links.will_keep_latest_score', "Will keep the latest of all your scores")
  end

  def quiz_edit_text(quiz=@quiz)
    if quiz.survey?
      I18n.t('titles.edit_survey', 'Edit Survey')
    else
      I18n.t('titles.edit_quiz', 'Edit Quiz')
    end
  end

  def quiz_delete_text(quiz=@quiz)
    if quiz.survey?
      I18n.t('titles.delete_survey', 'Delete Survey')
    else
      I18n.t('titles.delete_quiz', 'Delete Quiz')
    end
  end

  def submission_has_regrade?(submission)
    submission && submission.score_before_regrade.present?
  end

  def score_affected_by_regrade?(submission)
    submission && submission.score_before_regrade != submission.kept_score
  end

  def answer_title(answer, selected_answer, correct_answer, show_correct_answers)
    titles = []

    if selected_answer || correct_answer || show_correct_answers
      titles << h("#{answer}.")
    end

    if selected_answer
      titles << I18n.t(:selected_answer, "You selected this answer.")
    end

    if correct_answer && show_correct_answers
      titles << I18n.t(:correct_answer, "This was the correct answer.")
    end

    title = "title=\"#{titles.join(' ')}\"".html_safe if titles.length > 0
  end

  def show_correct_answers?(quiz=@quiz, user=@current_user, submission=@submission)
    @quiz && @quiz.try_rescue(:show_correct_answers?, @current_user, @submission)
  end

  def correct_answers_protected?(quiz=@quiz, user=@current_user, submission=@submission)
    if !quiz
      false
    elsif !show_correct_answers?(quiz, user, submission)
      true
    elsif quiz.hide_correct_answers_at.present?
      !quiz.grants_right?(user, :grade)
    end
  end

  def point_value_for_input(user_answer, question)
    return user_answer[:points] unless user_answer[:correct] == 'undefined'

    if ["assignment", "practice_quiz"].include?(@quiz.quiz_type)
      "--"
    else
      question[:points_possible] || 0
    end
  end

end
