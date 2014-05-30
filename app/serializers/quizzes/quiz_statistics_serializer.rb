module Quizzes
  class QuizStatisticsSerializer < Canvas::APISerializer
    root :quiz_statistics

    # Utilizes both Student and Item analysis to generate a compound document of
    # quiz statistics.
    #
    # This is what you should pass to this serializer!!!
    class Input < Struct.new(:quiz, :student_analysis, :item_analysis)
      include ActiveModel::SerializerSupport
    end

    attributes *[
      # the id is really only included in JSON-API and only because the spec
      # requires it, this is because the output of this serializer is a mix of
      # two entities, an id doesn't make much sense, but we'll use the id of the
      # StudentAnalysis when needed
      :id,

      :url,
      :html_url,

      # whether any of the participants has taken the quiz more than one time
      :multiple_attempts_exist,

       # the time of the generation of the analysis (the earliest one)
      :generated_at,

      # whether the statistics were based on earlier and current quiz submissions
      #
      # PS: this is always true for item analysis
      :includes_all_versions,

      # an aggregate of question stats from both student and item analysis
      :question_statistics,

      # submission-related statistics (extracted from student analysis):
      #
      #   - correct_count_average
      #   - incorrect_count_average
      #   - duration_average
      #   - logged_out_users (id set)
      #   - score_average
      #   - score_high
      #   - score_low
      #   - score_stdev
      #   - user_ids (id set)
      :submission_statistics
    ]

    def_delegators :@controller,
      :course_quiz_statistics_url,
      :api_v1_course_quiz_url,
      :api_v1_course_quiz_statistics_url

    has_one :quiz, embed: :ids

    def id
      object[:student_analysis].id
    end

    def url
      api_v1_course_quiz_statistics_url(object.quiz.context, object.quiz)
    end

    def html_url
      course_quiz_statistics_url(object.quiz.context, object.quiz)
    end

    def quiz_url
      api_v1_course_quiz_url(object.quiz.context, object.quiz)
    end

    def question_statistics
      # entries in the :questions set are pairs of a static string and actual
      # question data, e.g:
      #
      # [['question', { id: 1, ... }], ['question', { id:2, ... }]]
      question_statistics = student_analysis_report[:questions].collect(&:last)

      # we're going to merge the item analysis for applicable questions into the
      # generic question statistics from the student analysis
      question_statistics.each do |question|
        question_id = question[:id]
        question_item = item_analysis_report.detect do |question_item|
          question_item[:question_id] == question_id
        end

        if question_item.present?
          question_item.delete :question_id
          question.merge! question_item
        end

        remove_unwanted_fields question
      end

      question_statistics
    end

    def submission_statistics
      report = student_analysis_report
      extractor = /^submission_(.+)/

      {}.tap do |out|
        report.each_pair do |key, statistic|
          out[$1] = statistic if key =~ extractor
        end

        out[:unique_count] = report[:unique_submission_count]
      end
    end

    def generated_at
      [ object[:student_analysis], object[:item_analysis] ].map(&:created_at).min
    end

    def multiple_attempts_exist
      student_analysis_report[:multiple_attempts_exist]
    end

    def includes_all_versions
      object[:student_analysis].includes_all_versions
    end

    private

    def student_analysis_report
      @student_analysis_report ||= object[:student_analysis].report.generate
    end

    def item_analysis_report
      @item_analysis_report ||= object[:item_analysis].report.generate
    end

    def remove_unwanted_fields(question)
      # this is always empty
      question.delete(:unexpected_response_values)

      (question[:answers] || []).each do |answer|
        # this is 99% of the time empty, see CNVS-12170
        answer.delete(:html)
        # this is unnecessary
        answer.delete(:comments)
      end
    end
  end
end