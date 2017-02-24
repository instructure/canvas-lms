require 'English'

module Exporters
  class Quizzes2Exporter

    GROUP_NAME = 'Migrated Quizzes'.freeze

    attr_accessor :course, :quiz
    delegate :add_error, :to => :@content_export, :allow_nil => true

    def initialize(content_export)
      @content_export = content_export
      @course = @content_export.context
      @context_id = @course.id
      @quiz = @course.quizzes.find(content_export.selected_content)
      # TO-DO: we need pass in the ID of the
      # quiz from the view, which is not hooked up yet
    end

    def export
      begin
        trigger_import
        create_assignment
      rescue
        add_error(I18n.t("Error running Quizzes 2 export."), $ERROR_INFO)
        return false
      end
      true
    end

    private

    def build_assignment_payload
      assignment_title = @quiz.title
      {
        assignment: {
          title: assignment_title
        }
      }
      # TO-DO: Payload should look like the example below
      # {
      #   assignment: {
      #     title: @quiz.title
      #     resouce_link_id: "SHA from Assignment Creation"
      #     qti_export: {
      #       content_url: "Endpoint for the export"
      #     }
      #   }
      # }
    end

    def assignment_group
      @assignment_group ||=
        course.assignment_groups.find_or_create_by(
          name: GROUP_NAME,
          workflow_state: 'available'
        )
    end

    def create_assignment
      post_to_sis = Assignment.sis_grade_export_enabled?(course)
      assignment_params = {
        title: quiz.title,
        points_possible: quiz.points_possible,
        due_at: quiz.due_at,
        unlock_at: quiz.unlock_at,
        lock_at: quiz.lock_at,
        assignment_group: assignment_group,
        workflow_state: 'unpublished'
      }
      assignment_params[:post_to_sis] = quiz.assignment.post_to_sis if post_to_sis
      assignment = course.assignments.create(assignment_params)
      assignment.quiz_lti! && assignment.save!
    end

    def trigger_import
      build_assignment_payload
      # TO-DO: Queue the Live Event here
    end
  end
end
