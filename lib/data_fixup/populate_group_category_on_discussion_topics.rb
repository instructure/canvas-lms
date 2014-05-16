module DataFixup::PopulateGroupCategoryOnDiscussionTopics
  def self.run
    target = %w{MySQL Mysql2}.include?(DiscussionTopic.connection.adapter_name) ? 'discussion_topics.group_category_id' : 'group_category_id'
    Assignment.where('submission_types = ? AND group_category_id IS NOT NULL', 'discussion_topic').find_ids_in_ranges do |min_id, max_id|
      DiscussionTopic.where(assignment_id: min_id..max_id).joins(:assignment).update_all("#{target} = assignments.group_category_id")
    end
  end
end
