require 'English'

module Exporters
  class Quizzes2Exporter

    attr_accessor :course, :user

    def initialize(content_export)
      @content_export = content_export
      @course = @content_export.context
      @context_id = @course.id
      @logger = Rails.logger
      # TO-DO: initialize @quiz; we need pass in the ID of the
      # quiz from the view, which is not hooked up yet
    end

    def build_assignment_payload
      assignment_title = "Cloned Quiz" # TO-DO: Replace with quiz.title
      {
        assignment: {
          title: assignment_title
        }
      }
      # TO-DO: Payload should look like the example below
      # {
      #   assignment: {
      #     title: "Some Name"
      #     resouce_link_id: "SHA from Assignment Creation"
      #     qti_export: {
      #       content_url: "Endpoint for the export"
      #     }
      #   }
      # }
    end

    def trigger_import
      build_assignment_payload
      # TO-DO: Queue the Live Event here
    end

    def export
      begin
        trigger_import
      rescue
        add_error(I18n.t("Error running Quizzes 2 export."), $ERROR_INFO)
        @logger.error $ERROR_INFO
        return false
      end
      true
    end
  end
end
