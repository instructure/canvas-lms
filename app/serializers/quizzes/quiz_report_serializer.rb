module Quizzes
  # Input to this serializer is actually a Quizzes::QuizStatistics object, but
  # it exposes data related to its report.
  class QuizReportSerializer < Canvas::APISerializer
    root :quiz_report

    def_delegators :@controller,
      :api_v1_course_quiz_url,
      :api_v1_course_quiz_report_url,
      :api_v1_progress_url

    def_delegators :object, :quiz

    attributes *%w[
      id
      report_type
      readable_type
      includes_all_versions
      generatable
      anonymous
      url
      progress_url
      created_at
      updated_at
    ].map(&:to_sym)

    has_one :quiz, embed: :ids, root: :quiz
    has_one :progress, {
      root: :progress,
      embed: :object,
      embed_in_root: true,
      wrap_in_array: false
    }
    has_one :attachment, {
      root: :file,
      embed: :object,
      embed_in_root: true,
      wrap_in_array: false
    }

    def generatable
      object.report.generatable?
    end

    def url
      api_v1_course_quiz_report_url(context, quiz, object)
    end

    def quiz_url
      api_v1_course_quiz_url(context, quiz)
    end

    def progress_url
      api_v1_progress_url(object.progress)
    end

    def stringify_ids?
      accepts_jsonapi?
    end

    def filter(keys)
      super.select do |key|
        case key
        when :progress_url then !accepts_jsonapi? && has_progress?
        when :progress then has_progress? && including?('progress')
        when :attachment then has_attachment? && including?('file')
        else true
        end
      end
    end

    def serializable_object(options={})
      super.tap do |hash|
        unless accepts_jsonapi?
          hash.delete('links')
          hash[:quiz_id] = quiz.id
        end
      end
    end

    private

    def attachment
      object.csv_attachment
    end

    def has_attachment?
      attachment.present?
    end

    def has_progress?
      object.progress.present?
    end

    def including?(document)
      @sideloads.include?(document)
    end
  end
end