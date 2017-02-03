require 'sanitize'

module Quizzes::QuizQuestion::AnswerSerializers
  module Util
    MaxTextualAnswerLength = 16.kilobyte

    class << self
      def blank_id(blank)
        AssessmentQuestion.variable_id(blank)
      end

      # Cast a numerical value to an Integer.
      #
      # @return [Integer|NilClass]
      #   nil if the parameter isn't really an integer.
      def to_integer(number)
        begin
          Integer(number)
        rescue
          nil
        end
      end

      # Convert a value to a BigDecimal.
      #
      # @return [BigDecimal]
      def to_decimal(value)
        BigDecimal.new(value.to_s)
      rescue ArgumentError
        BigDecimal.new('0.0')
      end

      def to_boolean(flag)
        Canvas::Plugin.value_to_boolean(flag)
      end

      # See Util.MaxTextualAnswerLength for the threshold.
      def text_too_long?(text)
        text.to_s.length >= MaxTextualAnswerLength
      end

      def sanitize_html(html)
        Sanitize.clean((html || '').to_s, CanvasSanitize::SANITIZE)
      end

      def sanitize_text(text)
        (text || '').to_s.strip.downcase
      end
    end
  end
end
