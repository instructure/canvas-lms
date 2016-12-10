class DropReallyOldUnusedColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  disable_ddl_transaction!

  # cleanup for some legacy database schema that may not even exist for databases created post-OSS release
  def self.maybe_drop(table, column)
    remove_column(table, column) if self.connection.columns(table).map(&:name).include?(column.to_s)
  end

  def self.up
   maybe_drop :accounts, :account_code
   maybe_drop :accounts, :authentication_type
   maybe_drop :accounts, :ldap_host
   maybe_drop :accounts, :ldap_domain

   maybe_drop :account_authorization_configs, :auth_uid

   maybe_drop :assignments, :sequence_position

   maybe_drop :content_tags, :sequence_position

   maybe_drop :course_sections, :students_can_participate_before_start_at

   maybe_drop :discussion_topics, :authorization_list_id

   maybe_drop :enrollments, :can_participate_before_start_at

   maybe_drop :pseudonyms, :crypted_webdav_access_code

   maybe_drop :quizzes, :root_quiz_id
  end

  def self.down
  end
end
