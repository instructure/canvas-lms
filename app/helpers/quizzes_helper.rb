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
    return false unless can_publish(quiz)

    !quiz.available? || quiz.unpublished_changes?
  end

  def can_read(quiz, user=@current_user)
    can_do(quiz, user, :read)
  end

  def can_publish(quiz, user=@current_user)
    can_do(quiz, user, :update) || can_do(quiz, user, :manage)
  end

  def unpublished_quiz_warning
    I18n.t(
      '*This quiz is unpublished* Only teachers can see the quiz until ' +
      'it is published.',
      :wrapper => '<strong class=unpublished_quiz_warning>\1</strong>')
  end

  def unsaved_changes_warning
    I18n.t(
      '*You have made changes to the questions in this quiz.* '+
      'These changes will not appear for students until you ' +
      'save the quiz.',
      :wrapper => '<strong class=unsaved_quiz_warning>\1</strong>')
  end

  def quiz_published_state_warning(quiz=@quiz)
    if !quiz.available?
      unpublished_quiz_warning
    else
      unsaved_changes_warning
    end
  end

  def display_save_button?(quiz=@quiz)
    quiz.available? && can_publish(quiz)
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
      I18n.t("Practice Quiz")
    when "assignment"
      I18n.t("Graded Quiz")
    when "graded_survey"
      I18n.t("Graded Survey")
    when "survey"
      I18n.t("Ungraded Survey")
    end
  end

  def render_score_to_keep(quiz_scoring_policy)
    case quiz_scoring_policy
    when "keep_highest"
      I18n.t('Highest')
    when "keep_latest"
      I18n.t('Latest')
    when "keep_average"
      I18n.t('Average')
    end
  end

  def render_show_correct_answers(quiz)
    if !quiz.show_correct_answers
      return I18n.t('No')
    end

    show_at = quiz.show_correct_answers_at
    hide_at = quiz.hide_correct_answers_at

    if show_at && hide_at
      I18n.t('From %{from} to %{to}', {
        from: datetime_string(quiz.show_correct_answers_at),
        to: datetime_string(quiz.hide_correct_answers_at)
      })
    elsif show_at
      I18n.t('After %{date}', {
        date: datetime_string(quiz.show_correct_answers_at)
      })
    elsif hide_at
      I18n.t('Until %{date}', {
        date: datetime_string(quiz.hide_correct_answers_at)
      })
    elsif quiz.show_correct_answers_last_attempt
      I18n.t('After Last Attempt')
    else
      I18n.t('Immediately')
    end
  end

  def render_correct_answer_protection(quiz)
    return I18n.t('Answers will be shown after your last attempt') if quiz.show_correct_answers_last_attempt
    show_at = quiz.show_correct_answers_at
    hide_at = quiz.hide_correct_answers_at
    now = Time.now

    # Some labels will be used in more than one case, so we'll pre-define them.
    labels = {}
    if hide_at
      labels[:available_until] = I18n.t(
        'Correct answers are available until %{date}.', {
        date: datetime_string(quiz.hide_correct_answers_at)
      })
    end

    if !quiz.show_correct_answers
      I18n.t('Correct answers are hidden.')
    elsif hide_at.present? && hide_at < now
      I18n.t('Correct answers are no longer available.')
    elsif show_at.present? && hide_at.present?
      # If the answers are currently visible, there's no need to show the range
      # of availability.
      if now > show_at
        labels[:available_until]
      else
        I18n.t(
          'Correct answers will be available %{from} - %{to}.', {
            from: datetime_string(show_at),
            to: datetime_string(hide_at)
          })
      end
    elsif show_at.present?
      I18n.t(
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
      I18n.t("No")
    when "until_after_last_attempt"
      I18n.t("After Last Attempt")
    when nil
      I18n.t("Always")
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
    I18n.t(
      { :zero => "Students who have taken the quiz",
        :one => "Students who have taken the quiz (%{count})",
        :other => "Students who have taken the quiz (%{count})" },
      { :count => student_count })
  end

  def submitted_students_survey_title(student_count)
    I18n.t(
      { :zero => "Students who have taken the survey",
        :one => "Students who have taken the survey (%{count})",
        :other => "Students who have taken the survey (%{count})" },
      { :count => student_count })
  end

  def no_submitted_students_msg(quiz)
    if quiz.survey?
      I18n.t("No Students have taken the survey yet")
    else
      I18n.t("No Students have taken the quiz yet")
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
    I18n.t(
      { :zero => "Student who haven't taken the quiz",
        :one => "Students who haven't taken the quiz (%{count})",
        :other => "Students who haven't taken the quiz (%{count})" },
      { :count => student_count })
  end

  def unsubmitted_students_survey_title(student_count)
    I18n.t(
      { :zero => "Student who haven't taken the survey",
        :one => "Students who haven't taken the survey (%{count})",
        :other => "Students who haven't taken the survey (%{count})" },
      { :count => student_count })
  end

  def no_unsubmitted_students_msg(quiz)
    if quiz.survey?
      I18n.t("All Students have taken the survey")
    else
      I18n.t("All Students have taken the quiz")
    end
  end

  def render_result_protection(quiz, submission)
    if quiz.one_time_results && submission.has_seen_results?
      I18n.t("Quiz results are protected for this quiz and can be viewed a single time immediately after submission.")
    elsif quiz.hide_results == 'until_after_last_attempt'
      I18n.t("Quiz results are protected for this quiz and are not visible to students until they have submitted their last attempt.")
    else
      I18n.t("Quiz results are protected for this quiz and are not visible to students.")
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
    label_attr = "aria-label='#{I18n.t("Fill in the blank, read surrounding text")}'"

    answer_list.each do |entry|
      entry[:blank_id] = AssessmentQuestion.variable_id(entry[:blank_id])
    end
    # Requires mutliline option to be robust
    res.gsub!(%r{<input.*?name=\\?['"](question_.*?)\\?['"].*?>}m) do |match|
      blank = match.match(RE_EXTRACT_BLANK_ID).to_a[1]
      blank.gsub!(/\\/,'')
      answer = answer_list.detect { |entry| entry[:blank_id] == blank } || {}
      answer = h(answer[:answer] || '')

      # If given answer list, insert the values into the text inputs for displaying user's answers.
      if answer_list.any?
        #  Replace the {{question_IDNUM_VARIABLEID}} template text with the user's answer text.
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
    doc = Nokogiri::HTML.fragment(res)
    selects = doc.css(".question_input")
    selects.each do |s|
      if answer_list && !answer_list.empty?
        a = answer_list[index]
        index += 1
      else
        question_id = s["name"]
        a = hash_get(answers, question_id)
      end

      # If existing answer is one of the options, select it
      if opt_tag = s.children.css("option[value='#{a}']").first
        opt_tag["selected"] = "selected"
      end
    end
    doc.to_s.html_safe
  end

  def duration_in_minutes(duration_seconds)
    if duration_seconds < 60
      duration_minutes = 0
    else
      duration_minutes = (duration_seconds / 60).round
    end
    I18n.t(
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
    I18n.t("%{score} out of %{points_possible}",
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
      I18n.t('Take the Survey') :
      I18n.t('Take the Quiz')
  end

  def retake_poll_message(quiz=@quiz)
    quiz.survey? ?
      I18n.t('Take the Survey Again') :
      I18n.t('Take the Quiz Again')
  end

  def resume_poll_message(quiz=@quiz)
    quiz.survey? ?
      I18n.t('Resume Survey') :
      I18n.t('Resume Quiz')
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
    case quiz.scoring_policy
    when "keep_highest"
      I18n.t("Will keep the highest of all your scores")
    when "keep_latest"
      I18n.t("Will keep the latest of all your scores")
    when "keep_average"
      I18n.t("Will keep the average of all your scores")
    end
  end

  def quiz_edit_text(quiz=@quiz)
    if quiz.survey?
      I18n.t('Edit Survey')
    else
      I18n.t('Edit Quiz')
    end
  end

  def quiz_delete_text(quiz=@quiz)
    if quiz.survey?
      I18n.t('Delete Survey')
    else
      I18n.t('Delete Quiz')
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
      titles << ("#{answer}.")
    end

    if selected_answer
      titles << I18n.t(:selected_answer, "You selected this answer.")
    end

    if correct_answer && show_correct_answers
      titles << I18n.t(:correct_answer, "This was the correct answer.")
    end

    titles = titles.map { |title| h(title) }
    title = "title=\"#{titles.join(' ')}\"".html_safe if titles.length > 0
  end

  def matching_answer_title(item_text, did_select_answer, selected_answer_text, is_correct_answer, correct_answer_text, show_correct_answers)
    titles = []

    if did_select_answer || is_correct_answer || show_correct_answers
      titles << "#{item_text}."
    end


    if did_select_answer
      titles << I18n.t(:user_selected_answer, "You selected")
    end

    titles << "#{selected_answer_text}."

    if is_correct_answer && show_correct_answers
      titles << I18n.t(:correct_answer, "This was the correct answer.")
    end

    if !is_correct_answer && show_correct_answers
      titles << I18n.t(:user_selected_wrong, "The correct answer was %{correct_answer_text}.", correct_answer_text: correct_answer_text)
    end

    titles = titles.map { |title| h(title) }
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
