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
                     ldap_domain
                     require_authorization_code
                    ).freeze,
    'account_authorization_configs' => %w(auth_uid
                                          login_handle_name
                                          change_password_url
                                          unknown_user_url).freeze,
    'account_notification_roles' => %w(role_type).freeze,
    'account_users' => %w(membership_type).freeze,
    'access_tokens' => %w(token).freeze,
    'assessment_question_bank_users' => %w{deleted_at permissions workflow_state}.freeze,
    'assessment_requests' => %w{comments}.freeze,
    'asset_user_accesses' => %w(asset_access_stat_id
                                interaction_seconds
                                progress
                                count
                                summarized_at
                              ).freeze,
    'assignments' => %w(sequence_position
                        minimum_required_blog_posts
                        minimum_required_blog_comments
                        reminders_created_for_due_at
                        publishing_reminder_sent
                        previously_published
                        before_quiz_submission_types
                        grading_scheme_id
                        location
                        needs_grading_count
                      ).freeze,
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
    'content_migrations' => %w{error_count error_data}.freeze,
    'content_tags' => %w(sequence_position context_module_association_id).freeze,
    'context_external_tools' => %w(integration_type).freeze,
    'context_modules' => %w(downstream_modules start_at end_at).freeze,
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
                    publish_grades_immediately
                    old_account_id
                    show_all_discussion_entries
                  ).freeze,
    'developer_keys' => %w(tool_id).freeze,
    'discussion_topics' => %w(authorization_list_id).freeze,
    'enrollment_terms' => %w(sis_data
                             sis_name
                             ignore_term_date_restrictions).freeze,
    'enrollments' => %w(invitation_email
                        can_participate_before_start_at
                        limit_priveleges_to_course_sections
                        role_name
                        sis_source_id).freeze,
    'enrollment_states' => %w{state_invalidated_at state_recalculated_at access_invalidated_at access_recalculated_at}.freeze,
    'eportfolio_entries' => %w(attachment_id artifact_type url).freeze,
    'eportfolios' => %w{context_id context_type}.freeze,
    'external_feeds' => %w(body_match feed_type feed_purpose).freeze,
    'external_feed_entries' => %w(start_at end_at).freeze,
    'failed_jobs' => %w(original_id).freeze,
    'feature_flags' => %w(locking_account_id).freeze,
    'gradebook_uploads' => %w(context_type context_id).freeze,
    'grading_periods' => %w(course_id account_id).freeze,
    'groups' => %w(sis_name type groupable_id groupable_type hashtag
                   show_public_context_messages default_wiki_editing_roles).freeze,
    'learning_outcome_results' => %w{comments}.freeze,
    'learning_outcome_question_results' => %w{context_code context_id context_type}.freeze,
    'lti_resource_placements' => %w(resource_handler_id).freeze,
    'messages' => %w(cc bcc notification_category).freeze,
    'moderated_grading_provisional_grades' => %w(position).freeze,
    'notification_policies' => %w(user_id broadcast).freeze,
    'page_views' => %w(contributed).freeze,
    'pseudonyms' => %w(sis_update_data
                       deleted_unique_id
                       sis_source_id
                       crypted_webdav_access_code
                       type
                       login_path_to_ignore).freeze,
    'quizzes' => %w(root_quiz_id).freeze,
    'role_overrides' => %w(context_code enrollment_type).freeze,
    'rubric_assessments' => %w{comments}.freeze,
    'rubric_associations' => %w{description}.freeze,
    'sis_batches' => %w(batch_id errored_attempts).freeze,
    'stream_items' => %w(context_code item_asset_string).freeze,
    'stream_item_instances' => %w(context_code).freeze,
    'submissions' => %w(changed_since_publish late).freeze,
    'submission_comments' => %w{recipient_id}.freeze,
    'users' => %w(type
                  creation_unique_id
                  creation_sis_batch_id
                  creation_email
                  sis_name
                  bio
                  merge_to
                  unread_inbox_items_count
                  visibility
                ).freeze,
    'web_conference_participants' => %w{workflow_state}.freeze,
    'wiki_pages' => %w(hide_from_students delayed_post_at recent_editors wiki_page_comments_count).freeze
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
    end unless self < Tableless
    instantiate_without_remove_dropped_columns(attributes, *args)
  end

  class << self
    alias_method_chain :columns, :remove_dropped_columns
    alias_method_chain :reset_column_information, :remove_dropped_columns
    alias_method_chain :instantiate, :remove_dropped_columns
  end
end
