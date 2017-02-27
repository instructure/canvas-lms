class SetDefaultValuesForDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    fields = [
      :could_be_locked, :podcast_enabled, :podcast_has_student_posts,
      :require_initial_post, :pinned, :locked, :allow_rating, :only_graders_can_rate,
      :sort_by_rating
    ]
    fields.each { |field| change_column_default(:discussion_topics, field, false) }
    DataFixup::BackfillNulls.run(DiscussionTopic, fields, default_value: false)
    fields.each { |field| change_column_null_with_less_locking(:discussion_topics, field) }
  end

  def down
    fields = [
      :could_be_locked, :podcast_enabled, :podcast_has_student_posts,
      :require_initial_post, :pinned, :locked, :allow_rating, :only_graders_can_rate,
      :sort_by_rating
    ]
    fields.each { |field| change_column_null(:discussion_topics, field, true) }
    fields.each { |field| change_column_default(:discussion_topics, field, nil) }
  end
end
