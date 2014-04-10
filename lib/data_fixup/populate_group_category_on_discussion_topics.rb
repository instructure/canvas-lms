module DataFixup::PopulateGroupCategoryOnDiscussionTopics
  def self.run
    Assignment.where('submission_types = ? AND group_category_id IS NOT NULL', 'discussion_topic').find_ids_in_ranges do |min_id, max_id|
      DiscussionTopic.where(assignment_id: min_id..max_id).joins(:assignment).update_all('group_category_id = assignments.group_category_id')
    end
  end
end
