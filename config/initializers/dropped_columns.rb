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
    'abstract_courses' => %w(sis_name sis_course_code).freeze,
    'accounts' => %w(type
                     sis_name
                     account_code
                     authentication_type
                     ldap_host
                     ldap_domain).freeze,
    'account_authorization_configs' => %w(auth_uid
                                          login_handle_name
                                          change_password_url
                                          unknown_user_url).freeze,
    'account_notification_roles' => %w(role_type).freeze,
    'account_users' => %w(membership_type).freeze,
    'access_tokens' => %w(token).freeze,
    'asset_user_accesses' => %w(asset_access_stat_id
                                interaction_seconds
                                progress
                                count).freeze,
    'assignments' => %w(sequence_position
                        minimum_required_blog_posts
                        minimum_required_blog_comments
                        reminders_created_for_due_at
                        publishing_reminder_sent
                        previously_published
                        before_quiz_submission_types).freeze,
    'attachments' => %w(enrollment_id
                        cached_s3_url
                        s3_url_cached_at
                        scribd_account_id
                        scribd_user
                        scribd_mime_type_id
                        submitted_to_scribd_at
                        scribd_doc
                        scribd_attempts
                        cached_scribd_thumbnail
                        last_inline_view
                        local_filename).freeze,
    'calendar_events' => %w(calendar_event_repeat_id for_repeat_on).freeze,
    'communication_channels' => %w(access_token_id internal_path).freeze,
    'content_exports' => %w(course_id).freeze,
    'content_tags' => %w(sequence_position context_module_association_id).freeze,
    'context_modules' => %w(downstream_modules).freeze,
    'conversation_messages' => %w(context_message_id).freeze,
    'course_sections' => %w(sis_cross_listed_section_id
                            sis_cross_listed_section_sis_batch_id
                            sticky_xlist
                            sis_name
                            students_can_participate_before_start_at
                            section_organization_name
                            long_section_code
                            account_id
                            section_code).freeze,
    'courses' => %w(section
                    hidden_tabs
                    sis_name
                    sis_course_code
                    hashtag
                    allow_student_assignment_edits
                    publish_grades_immediately).freeze,
    'discussion_topics' => %w(authorization_list_id).freeze,
    'enrollment_terms' => %w(sis_data
                             sis_name
                             ignore_term_date_restrictions).freeze,
    'enrollments' => %w(invitation_email
                        can_participate_before_start_at
                        limit_priveleges_to_course_sections
                        role_name).freeze,
    'eportfolio_entries' => %w(attachment_id artifact_type).freeze,
    'external_feeds' => %w(body_match feed_type feed_purpose).freeze,
    'failed_jobs' => %w(original_id).freeze,
    'gradebook_uploads' => %w(context_type context_id).freeze,
    'grading_periods' => %w(course_id account_id).freeze,
    'groups' => %w(sis_name type groupable_id groupable_type hashtag
                   show_public_context_messages).freeze,
    'messages' => %w(cc bcc).freeze,
    'notification_policies' => %w(user_id broadcast).freeze,
    'page_views' => %w(contributed).freeze,
    'pseudonyms' => %w(sis_update_data
                       deleted_unique_id
                       sis_source_id
                       crypted_webdav_access_code
                       type).freeze,
    'role_overrides' => %w(context_code enrollment_type).freeze,
    'rubric_assessments' => %w{comments}.freeze,
    'users' => %w(type
                  creation_unique_id
                  creation_sis_batch_id
                  creation_email
                  sis_name
                  bio).freeze,
    'quizzes' => %w(root_quiz_id).freeze,
    'sis_batches' => %w(batch_id).freeze,
    'stream_items' => %w(context_code item_asset_string).freeze,
    'stream_item_instances' => %w(context_code).freeze,
    'submissions' => %w(changed_since_publish late).freeze,
    'wiki_pages' => %w(hide_from_students).freeze,
    'lti_resource_placements' => %w(resource_handler_id).freeze,
    'moderated_grading_provisional_grades' => %w(position).freeze
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
