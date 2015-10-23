require File.expand_path(File.dirname(__FILE__) + '/../../factories/quiz_factory')
require File.expand_path(File.dirname(__FILE__) + '/../../factories/assignment_factory')
require File.expand_path(File.dirname(__FILE__) + '/../../factories/discussion_topic_factory')

module Components

  class Component
    def assign_to(_user)
      raise NotImplementedError, 'You must implement the assign_to() method'
    end

    def submit_as(_user)
      raise NotImplementedError, 'You must implement the submit_as() method'
    end

    private

    def add_assignment_override(assignment, opts={})
      add_assignment_override_for_student(opts) if opts[:user]
      add_assignment_override_for_section(assignment, opts) if opts[:section]
      assignment.only_visible_to_overrides = true
      assignment.save!
      assignment.reload
    end

    def add_assignment_override_for_student(opts={})
      assignment_override = AssignmentOverride.new()
      yield assignment_override
      assignment_override.title = "ADHOC OVERRIDE"
      assignment_override.workflow_state = "active"
      assignment_override.set_type = "ADHOC"
      set_override_dates(assignment_override, opts)
      assignment_override.save!
      override_student = assignment_override.assignment_override_students.build
      override_student.user = opts[:user]
      override_student.save!
    end

    def add_assignment_override_for_section(assignment, opts={})
      override = assignment.assignment_overrides.build
      override.set = opts[:section]
      set_override_dates(override, opts)
      override.save!
    end

    def set_override_dates(override, opts={})
      override.due_at = opts.fetch(:due_at, Time.zone.now.advance(days: 7))
      override.due_at_overridden = true
      override.lock_at = opts.fetch(:lock_at, Time.zone.now.advance(days: 7))
      override.lock_at_overridden = true
      override.unlock_at = opts.fetch(:unlock_at, Time.zone.now.advance(days: -1))
      override.unlock_at_overridden = true
    end
  end

  class Quiz < Component

    def assign_to(opts={})
      add_assignment_override(@component_quiz, opts)
    end

    def submit_as(user)
      submission = @component_quiz.generate_submission user
      submission.workflow_state = 'complete'
      submission.save!
    end

    private

    def initialize(course, quiz_name)
      @component_quiz = assignment_quiz([], course: course, title: quiz_name)
    end

    def add_assignment_override_for_student(opts={})
      super(opts) { |assignment_override| assignment_override.quiz = @component_quiz }
    end
  end

  class Assignment < Component

    private

    def initialize
      # @component_assignment =
    end

    def add_assignment_override_for_student(opts={})
      super(opts) { |assignment_override| assignment_override.assignment = @component_assignment }
    end
  end

  class Discussion < Component

    private

    def initialize
      # @component_discussion =
    end

    def add_assignment_override_for_student(opts={})
      super(opts) { |assignment_override| assignment_override.discussion = @component_discussion }
    end
  end
end
