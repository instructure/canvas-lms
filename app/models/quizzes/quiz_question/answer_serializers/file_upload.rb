module Quizzes::QuizQuestion::AnswerSerializers
  class FileUpload < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    def serialize(*args)
    end

    # @return [String|NilClass]
    #   ID of the attachment for the file that was uploaded, if any.
    #
    # @example output for uploading a file that was stored in an attachment with
    #          the id of "3":
    #   "3"
    #
    # @example output for not uploading any file:
    #   null
    def deserialize(submission_data, full=false)
      # when this is present, it would be an array, but it always includes 1
      # ID (or none, in which case it would contain 1 item which is '')
      attachment_ids = Array(submission_data[question_key]).reject(&:blank?)

      if attachment_ids.present?
        attachment_ids.first
      end
    end
  end
end
