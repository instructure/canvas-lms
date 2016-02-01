require_relative 'spec_components_assignable_module'

module SpecComponents
  class Quiz
    include Assignable

    attr_reader :id, :title

    def initialize(context, quiz_title)
      quiz_assignment = assignment_model(
        context: context,
        title: quiz_title,
        due_at: Time.zone.now.advance(days: 7),
        submission_types: 'online_quiz'
      )
      @component_quiz = quiz_model(
        assignment_id: quiz_assignment,
        title: quiz_assignment.title
      )
      @id = @component_quiz.id
      @title = @component_quiz.title
    end

    def assign_to(opts = {})
      add_assignment_override(@component_quiz, opts)
    end

    def submit_as(user)
      submission = @component_quiz.generate_submission user
      submission.workflow_state = 'complete'
      submission.save!
    end

    private

      def add_assignment_override_for_student(opts = {})
        super(opts) { |assignment_override| assignment_override.quiz = @component_quiz }
      end
  end
end