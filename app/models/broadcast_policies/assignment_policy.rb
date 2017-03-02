module BroadcastPolicies
  class AssignmentPolicy
    extend DatesOverridable::ClassMethods
    attr_reader :assignment

    def initialize(assignment)
      @assignment = assignment
    end

    def should_dispatch_assignment_due_date_changed?
      accepting_messages? &&
      assignment.changed_in_state(:published, :fields => :due_at) &&
      !just_published? &&
      !AssignmentPolicy.due_dates_equal?(assignment.due_at, assignment.due_at_was) &&
      created_before(3.hours.ago)
    end

    def should_dispatch_assignment_changed?
      accepting_messages? &&
      assignment.published? &&
      !assignment.muted? &&
      created_before(30.minutes.ago) &&
      !just_published? &&
      (assignment.points_possible_changed? || assignment.assignment_changed)
    end

    def should_dispatch_assignment_created?
      return false unless context_sendable?

      published_on_create? || just_published? ||
        (assignment.workflow_state_changed? && assignment.published?)
    end

    def should_dispatch_assignment_unmuted?
      context_sendable? &&
        assignment.recently_unmuted
    end

    private

    def context_sendable?
      assignment.context.available? &&
        !assignment.context.concluded?
    end

    def accepting_messages?
      context_sendable? &&
        !assignment.just_created
    end

    def created_before(time)
      assignment.created_at < time
    end

    def published_on_create?
      assignment.just_created && assignment.published?
    end

    def just_published?
      assignment.workflow_state_changed? && assignment.published?
    end
  end
end
