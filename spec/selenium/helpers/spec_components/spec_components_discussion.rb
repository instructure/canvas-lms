require_relative 'spec_components_assignable_module'

module SpecComponents
  class Discussion
    include Assignable
    include Factories

    def initialize(opts)
      course = opts[:course]
      discussion_title = opts.fetch(:title, 'Test Discussion')
      due_at = opts.fetch(:due_at, Time.zone.now.advance(days: 7))

      @component_discussion = assignment_model(
        context: course,
        title: discussion_title,
        submission_types: 'discussion_topic',
        due_at: due_at
      )
      @id = @component_discussion.discussion_topic.id
      @title = @component_discussion.discussion_topic.title
    end

    def assign_to(opts)
      add_assignment_override(@component_discussion, opts)
    end

    def submit_as(user)
      @component_discussion.discussion_topic.discussion_entries.create!(
        message: "This is #{user.name}'s discussion entry",
        user: user
      )
    end

    private

      def add_assignment_override_for_student(opts)
        super(opts) { |assignment_override| assignment_override.assignment = @component_discussion }
      end

      def add_assignment_override_for_section(opts)
        super(opts) { |assignment_override| assignment_override.assignment = @component_discussion }
      end
  end
end
