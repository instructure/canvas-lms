module DataFixup
  module AttachDissociatedDiscussionTopics
    def self.run
      return unless DiscussionTopic.connection.adapter_name == 'PostgreSQL'

      ActiveRecord::Base.connection.execute(<<-SQL)
        UPDATE discussion_topics SET assignment_id = old_assignment_id, updated_at = NOW()
        FROM assignments
        WHERE discussion_topics.old_assignment_id = assignments.id
        AND discussion_topics.assignment_id IS NULL
        AND discussion_topics.context_id = assignments.context_id
        AND discussion_topics.context_type = assignments.context_type
        AND discussion_topics.title = assignments.title
        AND discussion_topics.updated_at > '2013-04-14T18:00:00Z'
        AND assignments.workflow_state <> 'deleted'
        AND discussion_topics.workflow_state <> 'deleted'
        AND (assignments.description LIKE '%download?verifier=%' OR assignments.description LIKE '%/download?%')
      SQL
    end
  end
end
