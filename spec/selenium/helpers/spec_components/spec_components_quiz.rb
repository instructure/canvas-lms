require_relative 'spec_components_assignable_module'

module SpecComponents
  class Quiz
    include Assignable

    def initialize(opts)
      course = opts[:course]
      quiz_title = opts.fetch(:title, 'Test Quiz')
      due_at = opts.fetch(:due_at, Time.zone.now.advance(days: 7))

      assignment = course.assignments.create(title: quiz_title)
      assignment.workflow_state = 'published'
      assignment.submission_types = 'online_quiz'
      assignment.due_at = due_at
      assignment.save

      quiz = Quizzes::Quiz.where(assignment_id: assignment).first
      quiz.generate_quiz_data
      quiz.publish!
      quiz.save!

      @component_quiz = quiz
      @id = @component_quiz.id
      @title = @component_quiz.title
    end

    def assign_to(opts)
      add_assignment_override(@component_quiz, opts)
    end

    def submit_as(user)
      submission = @component_quiz.generate_submission user
      submission.workflow_state = 'complete'
      submission.save!
    end

    private

      def add_assignment_override_for_student(opts)
        super(opts) { |assignment_override| assignment_override.quiz = @component_quiz }
      end

      def add_assignment_override_for_section(opts)
        super(opts) { |assignment_override| assignment_override.quiz = @component_quiz }
      end
  end
end
