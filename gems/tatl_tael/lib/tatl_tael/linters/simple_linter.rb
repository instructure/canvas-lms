# frozen_string_literal: true

module TatlTael
  module Linters
    class SimpleLinter < BaseLinter
      attr_reader :comment

      def initialize(config:, changes:, auto_correct: false)
        super
        @comment = {
          message: config[:message],
          severity: config[:severity],
          cover_message: true
        }
      end

      def run
        comment if precondition_met? && !requirement_met?
      end

      def precondition_met?
        changes_exist?(config[:precondition])
      end

      def requirement_met?
        config[:requirement] && changes_exist?(config[:requirement])
      end
    end
  end
end
