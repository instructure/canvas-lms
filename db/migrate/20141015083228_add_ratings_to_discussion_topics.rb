class AddRatingsToDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :discussion_topics, :allow_rating, :boolean
    add_column :discussion_topics, :only_graders_can_rate, :boolean
    add_column :discussion_topics, :sort_by_rating, :boolean
    add_column :discussion_entries, :rating_count, :integer
    add_column :discussion_entries, :rating_sum, :integer
    add_column :discussion_entry_participants, :rating, :integer
  end
end
