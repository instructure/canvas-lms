module SpecComponents
  module Assignable
    attr_reader :title

    def assign_to(_opts = {})
      raise NotImplementedError, 'You must implement the assign_to() method!'
    end

    def submit_as(_user)
      raise NotImplementedError, 'You must implement the submit_as() method!'
    end

    private

      def add_assignment_override(assignment, opts)
        return if opts[:user].nil? || opts[:section].nil? || opts[:group].nil?
        add_assignment_override_for_student(opts) if opts[:user]
        add_assignment_override_for_section(assignment, opts) if opts[:section]
        add_assignment_override_for_group(opts) if opts[:group]
        assignment.only_visible_to_overrides = true
        assignment.save!
        assignment.reload
      end

      def add_assignment_override_for_student(opts)
        assignment_override = AssignmentOverride.new()
        yield assignment_override
        assignment_override.title = 'ADHOC OVERRIDE'
        assignment_override.workflow_state = 'active'
        assignment_override.set_type = 'ADHOC'
        set_override_dates(assignment_override, opts)
        assignment_override.save!
        override_student = assignment_override.assignment_override_students.build
        override_student.user = opts[:user]
        override_student.save!
      end

      def add_assignment_override_for_section(assignment, opts)
        override = assignment.assignment_overrides.build
        override.set = opts[:section]
        set_override_dates(override, opts)
        override.save!
      end

      def add_assignment_override_for_group(opts)
        # TODO: define this after DA for Groups is merged
      end

      def set_override_dates(override, opts = {})
        override.due_at               = opts.fetch(:due_at, Time.zone.now.advance(days: 7))
        override.due_at_overridden    = true
        override.lock_at              = opts.fetch(:lock_at, Time.zone.now.advance(days: 7))
        override.lock_at_overridden   = true
        override.unlock_at            = opts.fetch(:unlock_at, Time.zone.now.advance(days: -1))
        override.unlock_at_overridden = true
      end
  end
end