require_relative 'spec_components_assignable_module'

module SpecComponents
  class Discussion
    include Assignable

    attr_reader :id, :title

    def initialize(context, discussion_title)
      @component_discussion = assignment_model(
        context: context,
        title: discussion_title,
        due_at: Time.zone.now.advance(days: 7),
        submission_types: 'discussion_topic'
      )
      @id = @component_discussion.discussion_topic.id
      @title = @component_discussion.discussion_topic.title
    end

    def assign_to(opts = {})
      add_assignment_override(@component_discussion, opts)
    end

    def submit_as(user)
      @component_discussion.discussion_topic.discussion_entries.create!(
        message: "This is #{user.name}'s discussion entry",
        user: user
      )
    end

    private

      def add_assignment_override_for_student(opts = {})
        super(opts) { |assignment_override| assignment_override.assignment = @component_discussion }
      end
  end
end