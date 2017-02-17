class AddForeignKeys14 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :assignment_override_students, :quizzes, delay_validation: true
    add_foreign_key_if_not_exists :assignment_overrides, :quizzes, delay_validation: true
    add_foreign_key_if_not_exists :collaborators, :groups, delay_validation: true
    add_foreign_key_if_not_exists :content_participations, :users, delay_validation: true
    add_foreign_key_if_not_exists :content_tags, :learning_outcomes, delay_validation: true
    add_foreign_key_if_not_exists :context_module_progressions, :context_modules, delay_validation: true
    add_foreign_key_if_not_exists :course_sections, :courses, delay_validation: true
    add_foreign_key_if_not_exists :delayed_messages, :communication_channels, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topic_materialized_views, :discussion_topics, delay_validation: true
    add_foreign_key_if_not_exists :migration_issues, :content_migrations, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :assignment_override_students, :quizzes
    remove_foreign_key_if_exists :assignment_overrides, :quizzes
    remove_foreign_key_if_exists :collaborators, :groups
    remove_foreign_key_if_exists :content_participations, :users
    remove_foreign_key_if_exists :content_tags, :learning_outcomes
    remove_foreign_key_if_exists :context_module_progressions, :context_modules
    remove_foreign_key_if_exists :course_sections, :courses
    remove_foreign_key_if_exists :delayed_messages, :communication_channels
    remove_foreign_key_if_exists :discussion_topic_materialized_views, :discussion_topics
    remove_foreign_key_if_exists :migration_issues, :content_migrations
  end
end
