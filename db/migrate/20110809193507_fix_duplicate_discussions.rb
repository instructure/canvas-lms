class FixDuplicateDiscussions < ActiveRecord::Migration
  def self.up
    DiscussionTopic.transaction do
      duplicate_topics = DiscussionTopic.find(:all,
        :select => 'old_assignment_id, context_id, context_type',
        :conditions => "old_assignment_id IS NOT NULL AND workflow_state <> 'deleted' AND root_topic_id IS NULL AND context_type='Course'",
        :group => 'old_assignment_id, context_id, context_type HAVING count(*) > 1')

      duplicate_topics.each do |topic|
        duplicates = DiscussionTopic.find(:all,
          :conditions => ["context_id=? and context_type=? and old_assignment_id=? and workflow_state<>'deleted' and root_topic_id is null",
                          topic.context_id, topic.context_type, topic.old_assignment_id],
          :order => 'updated_at DESC')
        to_keep = duplicates.shift
        duplicate_ids = duplicates.map(&:id)

        DiscussionEntry.update_all("discussion_topic_id=#{to_keep.id}", :discussion_topic_id => duplicate_ids)
        DiscussionTopic.update_all("root_topic_id=#{to_keep.id}", :root_topic_id => duplicate_ids)
        DiscussionTopic.delete(duplicate_ids)
      end
    end
  end

  def self.down
  end
end
