#
# Copyright (C) 2011 - 2015 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class ActiveRecord::Base
  DROPPED_COLUMNS = {
    'abstract_courses' => %w(sis_name sis_course_code),
    'accounts' => %w(type sis_name account_code authentication_type ldap_host ldap_domain),
    'account_authorization_configs' => %w(auth_uid),
    'account_notification_roles' => %w(role_type),
    'account_users' => %w(membership_type),
    'access_tokens' => %w(token),
    'asset_user_accesses' => %w(asset_access_stat_id interaction_seconds progress count),
    'assignments' => %w(sequence_position minimum_required_blog_posts minimum_required_blog_comments reminders_created_for_due_at publishing_reminder_sent previously_published before_quiz_submission_types),
    'attachments' => %w(enrollment_id cached_s3_url s3_url_cached_at scribd_account_id scribd_user scribd_mime_type_id submitted_to_scribd_at scribd_doc scribd_attempts cached_scribd_thumbnail last_inline_view),
    'calendar_events' => %w(calendar_event_repeat_id for_repeat_on),
    'communication_channels' => %w(access_token_id internal_path),
    'content_exports' => %w(course_id),
    'content_tags' => %w(sequence_position context_module_association_id),
    'context_modules' => %w(downstream_modules),
    'conversation_messages' => %w(context_message_id),
    'course_sections' => %w(sis_cross_listed_section_id sis_cross_listed_section_sis_batch_id sticky_xlist sis_name students_can_participate_before_start_at section_organization_name long_section_code account_id section_code),
    'courses' => %w(section hidden_tabs sis_name sis_course_code hashtag allow_student_assignment_edits publish_grades_immediately),
    'discussion_topics' => %w(authorization_list_id),
    'enrollment_terms' => %w(sis_data sis_name ignore_term_date_restrictions),
    'enrollments' => %w(invitation_email can_participate_before_start_at limit_priveleges_to_course_sections role_name),
    'external_feeds' => %w(body_match feed_type feed_purpose),
    'failed_jobs' => %w(original_id),
    'grading_periods' => %w(course_id account_id),
    'groups' => %w(sis_name type groupable_id groupable_type),
    'messages' => %w(cc bcc),
    'notification_policies' => %w(user_id broadcast),
    'page_views' => %w(contributed),
    'pseudonyms' => %w(sis_update_data deleted_unique_id sis_source_id crypted_webdav_access_code type),
    'role_overrides' => %w(context_code enrollment_type),
    'users' => %w(type creation_unique_id creation_sis_batch_id creation_email sis_name bio),
    'quizzes' => %w(root_quiz_id),
    'sis_batches' => %w{batch_id},
    'stream_items' => %w{context_code item_asset_string},
    'stream_item_instances' => %w(context_code),
    'submissions' => %w(changed_since_publish late),
    'wiki_pages' => %w(hide_from_students)
  }.freeze

  def self.columns_with_remove_dropped_columns
    @columns_with_dropped ||= self.columns_without_remove_dropped_columns.reject { |c|
      (DROPPED_COLUMNS[self.table_name] || []).include?(c.name)
    }
  end

  def self.reset_column_information_with_remove_dropped_columns
    @columns_with_dropped = nil
    self.reset_column_information_without_remove_dropped_columns
  end

  def self.instantiate_with_remove_dropped_columns(attributes, *args)
    (DROPPED_COLUMNS[self.table_name] || []).each do |attr|
      attributes.delete(attr)
    end unless self.respond_to?(:tableless?)
    instantiate_without_remove_dropped_columns(attributes, *args)
  end

  class << self
    alias_method_chain :columns, :remove_dropped_columns
    alias_method_chain :reset_column_information, :remove_dropped_columns
    alias_method_chain :instantiate, :remove_dropped_columns
  end
end
