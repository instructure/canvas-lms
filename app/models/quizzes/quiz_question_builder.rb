class Quizzes::QuizQuestionBuilder
  QUIZ_GROUP_ENTRY = 'quiz_group'
  DEFAULT_OPTIONS = {
    shuffle_answers: false
  }

  def initialize(options={})
    self.options = DEFAULT_OPTIONS.merge(options)
  end

  attr_accessor :options

  # Shuffle questions in quiz groups. Shuffle answers & matches in individual
  # questions.
  #
  # @note
  # Quiz groups that are tied to a question bank are not touched here. That
  # happens when we prepare questions for a single user/submission in
  # #build_submission_questions().
  def shuffle_quiz_data!(questions)
    questions.each do |val|
      # A quiz group linked to a question bank:
      if val[:entry_type] == QUIZ_GROUP_ENTRY && val[:assessment_question_bank_id]
        # It points to a question bank, question/answer/match shuffling happens
        # when a submission is generated. See #build_submission_questions()

      # A normal quiz group with questions:
      elsif val[:entry_type] == QUIZ_GROUP_ENTRY
        val[:questions].shuffle!
        val[:questions].each do |question|
          if question[:answers]
            question[:answers] = shuffle_answers(question)
            question[:matches] = shuffle_matches(question) if question[:matches]
          end
        end

      # A normal question:
      else
        if val[:answers]
          val[:answers] = shuffle_answers(val)
          val[:matches] = shuffle_matches(val) if val[:matches]
        end
      end
    end
  end

  # Build the question data for a specific submission. This is what the user
  # will end up taking in their quiz.
  #
  # Based on the type of entries the quiz has in its quiz_data, each
  # submission's quiz_data construct may be unique since questions may be drawn
  # randomly out of pre-defined pools.
  #
  # @param [Integer] quiz_id
  # @param [Array<Hash>] quiz_data
  #   The pre-shuffled quiz question entries. This is what's stored in
  #   Quiz#stored_questions.
  #
  # @return [Array<Hash>]
  #   What you'd store in QuizSubmission#quiz_data.
  def build_submission_questions(quiz_id, quiz_data)
    @submission_question_index = 0
    @picked = { aq: [], qq: [] }

    # initially, exclude all the questions defined locally in the quiz from bank
    # selections:
    mark_picked(quiz_data.select { |d| d[:entry_type] != QUIZ_GROUP_ENTRY })

    quiz_data.reduce([]) do |submission_questions, descriptor|
      # pulling from question bank
      questions = if descriptor[:entry_type] == QUIZ_GROUP_ENTRY && descriptor[:assessment_question_bank_id]
        if (bank = ::AssessmentQuestionBank.where(id: descriptor[:assessment_question_bank_id]).first)
          pool = BankPool.new(bank, @picked, &method(:mark_picked))
          pool.draw(quiz_id, descriptor[:id], descriptor[:pick_count]).each do |question|
            question[:points_possible] = descriptor[:question_points]
            question[:published_at] = descriptor[:published_at]

            # since these questions were not resolved when the quiz's questions
            # were generated (because they're different for each user/submission),
            # so we need to decorate them like we did the group questions back in
            # #shuffle_quiz_data!()
            if question[:answers]
              question[:answers] = shuffle_answers(question)
              question[:matches] = shuffle_matches(question) if question[:matches]
            end
          end
        end

      # pulling from questions defined directly in a group
      elsif descriptor[:entry_type] == QUIZ_GROUP_ENTRY
        pool = GroupPool.new(descriptor[:questions], @picked, &method(:mark_picked))
        pool.draw(quiz_id, descriptor[:id], descriptor[:pick_count]).each do |question|
          question[:points_possible] = descriptor[:question_points]
        end

      # just a question
      else
        questions = [ descriptor ]
      end

      questions.each do |question|
        decorate_question_for_submission(question)
      end

      submission_questions.concat(questions)
    end
  end

  def self.decorate_question_for_submission(q, position)
    question_name = t(
      '#quizzes.quiz.question_name_counter',
      "Question %{question_number}", {
        question_number: position
      })

    q[:position] = position

    case q[:question_type]
    when ::Quizzes::QuizQuestion::Q_TEXT_ONLY
      question_name = t('#quizzes.quiz.default_text_only_question_name', 'Spacer')
    when ::Quizzes::QuizQuestion::Q_FILL_IN_MULTIPLE_BLANKS
      text = q[:question_text]
      variables = q[:answers].map { |a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = ::AssessmentQuestion.variable_id(variable)
        re = Regexp.new("\\[#{variable}\\]")
        text = text.sub re, <<-HTML
          <input
            class='question_input'
            type='text'
            autocomplete='off'
            style='width: 120px;'
            name='question_#{q[:id]}_#{variable_id}'
            value='{{question_#{q[:id]}_#{variable_id}}}' />
        HTML
      end

      q[:original_question_text] = q[:question_text]
      q[:question_text] = text
    when ::Quizzes::QuizQuestion::Q_MULTIPLE_DROPDOWNS
      text = q[:question_text]
      variables = q[:answers].map { |a| a[:blank_id] }.uniq
      variables.each do |variable|
        variable_id = ::AssessmentQuestion.variable_id(variable)
        variable_answers = q[:answers].select { |a| a[:blank_id] == variable }

        options = variable_answers.map do |a|
          "<option value='#{a[:id]}'>#{CGI::escapeHTML(a[:text])}</option>"
        end

        select = <<-HTML
          <select class='question_input' name='question_#{q[:id]}_#{variable_id}'>
            <option value=''>
              #{ERB::Util.h(t('#quizzes.quiz.default_question_input', "[ Select ]"))}
            </option>
            #{options}
          </select>
        HTML

        re = Regexp.new("\\[#{variable}\\]")
        text = text.sub(re, select)
      end # variable loop

      q[:original_question_text] = q[:question_text]
      q[:question_text] = text
    when ::Quizzes::QuizQuestion::Q_CALCULATED
      # on equation questions, pick one of the formulas, plug it in
      # and you should be able to treat it like a numerical_answer
      # question for all intents and purposes
      text = q[:question_text]
      q[:answers] = [q[:answers].sort_by { |a| rand }.first].compact
      if q[:answers].first
        q[:answers].first[:variables].each do |variable|
          re = Regexp.new("\\[#{variable[:name]}\\]")
          text = text.gsub(re, TextHelper.round_if_whole(variable[:value]).to_s)
        end
      end
      q[:question_text] = text
    end # case q[:question_type]

    q[:name] = q[:question_name] = question_name
    q
  end

  def shuffle_answers(question)
    if @options[:shuffle_answers] && shuffleable_question_type?(question[:question_type])
      question[:answers].sort_by { |a| rand }
    else
      question[:answers]
    end
  end

  def shuffle_matches(question)
    # question matches should always be shuffled, regardless of the
    # shuffle_answers option
    question[:matches].sort_by { |m| rand }
  end

  protected

  def self.t(*args)
    ::ActiveRecord::Base.t(*args)
  end

  # @property [Integer] submission_question_index
  # @private
  #
  # A counter used in generating question names for students based on the
  # position of the question within the quiz_data set.
  attr_reader :submission_question_index
  attr_reader :picked

  def decorate_question_for_submission(question)
    unless question[:question_type] == ::Quizzes::QuizQuestion::Q_TEXT_ONLY
      @submission_question_index += 1
    end

    self.class.decorate_question_for_submission(question, @submission_question_index)
  end

  def shuffleable_question_type?(question_type)
    # TODO: constantize
    ![
      "true_false_question",
      "matching_question",
      "fill_in_multiple_blanks_question"
    ].include?(question_type)
  end

  def mark_picked(questions)
    @picked[:aq].concat(questions.map { |q| q[:assessment_question_id] }).uniq!
    @picked[:qq].concat(questions.map { |q| q[:id] })
  end
end
