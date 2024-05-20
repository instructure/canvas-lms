# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class DiscussionEntry < ActiveRecord::Base
  # The maximum discussion entry threading depth that is allowed
  MAX_DEPTH = 50

  include Workflow
  include SendToStream
  include TextHelper
  include HtmlTextHelper
  include Api

  attr_readonly :discussion_topic_id, :user_id, :parent_id, :is_anonymous_author
  has_many :discussion_entry_drafts, inverse_of: :discussion_entry
  has_many :discussion_entry_versions, -> { order(version: :desc) }, inverse_of: :discussion_entry, dependent: :destroy
  has_many :legacy_subentries, class_name: "DiscussionEntry", foreign_key: "parent_id"
  has_many :root_discussion_replies, -> { where("parent_id=root_entry_id") }, class_name: "DiscussionEntry", foreign_key: "root_entry_id"
  has_many :discussion_subentries, -> { order(:created_at) }, class_name: "DiscussionEntry", foreign_key: "parent_id"
  has_many :unordered_discussion_subentries, class_name: "DiscussionEntry", foreign_key: "parent_id"
  has_many :flattened_discussion_subentries, class_name: "DiscussionEntry", foreign_key: "root_entry_id"
  has_many :discussion_entry_participants
  has_one :last_discussion_subentry, -> { order(created_at: :desc) }, class_name: "DiscussionEntry", foreign_key: "root_entry_id"
  belongs_to :discussion_topic, inverse_of: :discussion_entries
  belongs_to :quoted_entry, class_name: "DiscussionEntry"
  # null if a root entry
  belongs_to :parent_entry, class_name: "DiscussionEntry", foreign_key: :parent_id
  # also null if a root entry
  belongs_to :root_entry, class_name: "DiscussionEntry"
  belongs_to :user
  has_many :mentions, inverse_of: :discussion_entry
  belongs_to :attachment
  belongs_to :editor, class_name: "User"
  belongs_to :root_account, class_name: "Account"
  has_one :external_feed_entry, as: :asset

  before_create :infer_root_entry_id
  before_create :set_root_account_id
  after_save :update_discussion
  after_save :context_module_action_later
  after_save :create_discussion_entry_versions
  after_create :create_participants
  after_create :log_discussion_entry_metrics
  after_create :clear_planner_cache_for_participants
  after_create :update_topic
  validates :message, length: { maximum: maximum_text_length, allow_blank: true }
  validates :discussion_topic_id, presence: true
  before_validation :set_depth, on: :create
  validate :validate_depth, on: :create
  validate :discussion_not_deleted, on: :create
  validate :must_be_reply_to_same_discussion, on: :create

  sanitize_field :message, CanvasSanitize::SANITIZE

  # parse_and_create_mentions has to run before has_a_broadcast_policy and the
  # after_save hook it adds.
  after_save :parse_and_create_mentions
  has_a_broadcast_policy
  attr_accessor :new_record_header

  workflow do
    state :active
    state :deleted
  end

  def delete_draft
    discussion_topic.discussion_entry_drafts.where(user_id:, root_entry_id:).delete_all
  end

  def delete_edit_draft(user_id:)
    discussion_entry_drafts.where(user_id:).delete_all
  end

  def log_discussion_entry_metrics
    InstStatsd::Statsd.increment("discussion_entry.created")
  end

  def parse_and_create_mentions
    mention_data = Nokogiri::HTML.fragment(message).search("[data-mention]")
    user_ids = mention_data.pluck("data-mention")
    User.where(id: user_ids).each do |u|
      mentions.find_or_create_by!(user: u, root_account_id:)
    end
  end

  def mentioned_users
    User.where(id: mentions.distinct.select("user_id")).to_a
  end

  def course_broadcast_data
    discussion_topic.context&.broadcast_data
  end

  set_broadcast_policy do |p|
    p.dispatch :new_discussion_entry
    p.to { discussion_topic.subscribers - [user] - mentioned_users }
    p.whenever do |record|
      record.just_created && record.active?
    end
    p.data { course_broadcast_data }

    p.dispatch :announcement_reply
    p.to { discussion_topic.user }
    p.whenever do |record|
      record.discussion_topic.is_announcement && record.just_created && record.active?
    end
    p.data { course_broadcast_data }
  end

  on_create_send_to_streams do
    if root_entry_id.nil?
      participants = discussion_topic.active_participants_with_visibility

      # If the topic has been going for more than two weeks, only show
      # people who have been participating in the topic
      if created_at > discussion_topic.created_at + 2.weeks
        participants.map(&:id) & DiscussionEntry.active
                                                .where("discussion_topic_id=? AND created_at > ?", discussion_topic_id, 2.weeks.ago)
                                                .distinct.pluck(:user_id)
      else
        participants
      end
    else
      []
    end
  end

  def self.rating_sums(entry_ids)
    sums = where(id: entry_ids).where("COALESCE(rating_sum, 0) != 0")
    sums.to_h { |x| [x.id, x.rating_sum] }
  end

  def set_depth
    self.depth ||= (parent_entry.try(:depth) || 0) + 1
  end

  def validate_depth
    if !self.depth || self.depth > MAX_DEPTH
      errors.add(:base, "Maximum entry depth reached")
    end
  end

  def discussion_not_deleted
    errors.add(:base, "Requires non-deleted discussion topic") if discussion_topic.deleted?
  end

  def must_be_reply_to_same_discussion
    if parent_entry && parent_entry.discussion_topic_id != discussion_topic_id
      errors.add(:parent_id, "Parent entry must belong to the same discussion topic")
    end
  end

  def reply_from(opts)
    raise IncomingMail::Errors::UnknownAddress if context.root_account.deleted?
    raise IncomingMail::Errors::ReplyToDeletedDiscussion if discussion_topic.deleted?

    user = opts[:user]
    if opts[:html]
      message = opts[:html].strip
    else
      message = opts[:text].strip
      message = format_message(message).first
    end
    user = nil unless user && context.users.include?(user)
    if user
      shard.activate do
        entry = discussion_topic.discussion_entries.new(message:,
                                                        user:,
                                                        parent_entry: self)
        if entry.grants_right?(user, :create)
          entry.save!
          entry
        else
          raise IncomingMail::Errors::ReplyToLockedTopic
        end
      end
    else
      raise IncomingMail::Errors::InvalidParticipant
    end
  end

  def plaintext_message=(val)
    self.message = format_message(val).first
  end

  def truncated_message(length = nil)
    plaintext_message(length)
  end

  def summary(length = 150)
    HtmlTextHelper.strip_and_truncate(message, max_length: length)
  end

  def plaintext_message(length = 250)
    truncate_html(message, max_length: length)
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save!
    update_topic_submission
    decrement_unread_counts_for_this_entry
    update_topic_subscription
  end

  def update_discussion
    if %w[workflow_state message attachment_id editor_id].any? { |a| saved_change_to_attribute?(a) }
      dt = discussion_topic
      loop do
        dt.touch
        dt = dt.root_topic
        break if dt.blank?
      end
      self.class.connection.after_transaction_commit { discussion_topic.update_materialized_view }
    end
  end

  def create_discussion_entry_versions
    if saved_changes.key?("message")
      user = current_user || self.user

      message_old, message_new = saved_changes["message"]
      updated_at_old = saved_changes.key?("updated_at") ? saved_changes["updated_at"][0] : 1.minute.ago
      updated_at_new = saved_changes.key?("updated_at") ? saved_changes["updated_at"][1] : Time.now

      if discussion_entry_versions.count == 0 && !message_old.nil?
        discussion_entry_versions.create!(root_account:, user:, version: 1, message: message_old, created_at: updated_at_old, updated_at: updated_at_old)
      end

      new_version = (discussion_entry_versions.maximum(:version) || 0) + 1
      discussion_entry_versions.create!(root_account:, user:, version: new_version, message: message_new, created_at: updated_at_new, updated_at: updated_at_new)
    end
  end

  def update_topic_submission
    if discussion_topic.for_assignment?
      entries = discussion_topic.discussion_entries.where(user_id:, workflow_state: "active")
      submission = discussion_topic.assignment.submissions.where(user_id:).take
      return unless submission

      if entries.any?
        submission_date = entries.order(:created_at).limit(1).pluck(:created_at).first
        if submission_date > created_at
          submission.submitted_at = submission_date
          submission.save!
        end
      else
        submission.workflow_state = "unsubmitted"
        submission.submission_type = nil
        submission.submitted_at = nil
        submission.save!
      end
    end
  end

  def decrement_unread_counts_for_this_entry
    # decrement unread_entry_count for every participant that has not read the
    transaction do
      # get a list of users who have not read the entry yet
      users = discussion_topic.discussion_topic_participants
                              .where.not(user_id: discussion_entry_participants.read.pluck(:user_id)).pluck(:user_id)
      # decrement unread_entry_count for topic participants
      if users.present?
        DiscussionTopicParticipant.where(discussion_topic_id:, user_id: users)
                                  .update_all("unread_entry_count = unread_entry_count - 1")
      end
    end
  end

  def update_topic_subscription
    discussion_topic.user_ids_who_have_posted_and_admins
    unless discussion_topic.user_can_see_posts?(user)
      discussion_topic.unsubscribe(user)
    end
  end

  def user_name
    user.name rescue t :default_user_name, "User Name"
  end

  def infer_root_entry_id
    # don't allow parent ids for flat discussions
    self.parent_entry = nil if discussion_topic.discussion_type == DiscussionTopic::DiscussionTypes::FLAT

    # only allow non-root parents for threaded discussions
    unless discussion_topic.try(:threaded?)
      self.parent_entry = parent_entry.try(:root_entry) || parent_entry
    end
    self.root_entry_id = parent_entry.try(:root_entry_id) || parent_entry.try(:id)
  end
  protected :infer_root_entry_id

  def update_topic
    # only update last_reply_at if it is nil or
    # it is older than this entry's creation for over 60 seconds
    if discussion_topic.last_reply_at.nil? || (discussion_topic.last_reply_at && ((created_at.utc - discussion_topic.last_reply_at.utc).to_i > 60))
      last_reply_at = [discussion_topic.last_reply_at, created_at].compact.max
      DiscussionTopic.where(id: discussion_topic_id).update_all(last_reply_at:, updated_at: Time.now.utc)
    end
  end

  set_policy do
    given { |user| self.user && self.user == user }
    can :read

    given { |user| self.user && self.user == user && discussion_topic.available_for?(user) && discussion_topic.can_participate_in_course?(user) && !discussion_topic.comments_disabled? }
    can :reply

    given { |user| self.user && self.user == user && discussion_topic.available_for?(user) && context.user_can_manage_own_discussion_posts?(user) && discussion_topic.can_participate_in_course?(user) }
    can :update and can :delete

    given { |user, session| discussion_topic.is_announcement && context.grants_right?(user, session, :read_announcements) && discussion_topic.visible_for?(user) }
    can :read

    given { |user, session| !discussion_topic.is_announcement && context.grants_right?(user, session, :read_forum) && discussion_topic.visible_for?(user) }
    can :read

    given { |user, session| discussion_topic.is_announcement && context.grants_right?(user, session, :participate_as_student) && discussion_topic.visible_for?(user) && !discussion_topic.locked_for?(user, check_policies: true) && !discussion_topic.comments_disabled? }
    can :create

    given { |user, session| context.grants_right?(user, session, :post_to_forum) && !discussion_topic.locked_for?(user) && discussion_topic.visible_for?(user) }
    can :read

    given { |user, session| context.grants_right?(user, session, :post_to_forum) && !discussion_topic.locked_for?(user) && discussion_topic.visible_for?(user) && !discussion_topic.comments_disabled? }
    can :reply and can :create

    given { |user, session| context.grants_right?(user, session, :post_to_forum) && discussion_topic.visible_for?(user) }
    can :read

    given { |user, session| context.respond_to?(:allow_student_forum_attachments) && context.allow_student_forum_attachments && context.grants_right?(user, session, :post_to_forum) && discussion_topic.available_for?(user) }
    can :attach

    given { |user, session| !discussion_topic.root_topic_id && context.grants_right?(user, session, :moderate_forum) && !discussion_topic.locked_for?(user, check_policies: true) }
    can :update and can :delete and can :read and can :attach

    given { |user, session| !discussion_topic.root_topic_id && context.grants_right?(user, session, :moderate_forum) && !discussion_topic.locked_for?(user, check_policies: true) && !discussion_topic.comments_disabled? }
    can :reply and can :create

    given { |user, session| !discussion_topic.root_topic_id && context.grants_right?(user, session, :moderate_forum) }
    can :update and can :delete and can :read

    given { |user, session| discussion_topic.root_topic&.context&.grants_right?(user, session, :moderate_forum) && !discussion_topic.locked_for?(user, check_policies: true) }
    can :update and can :delete and can :read and can :attach

    given { |user, session| discussion_topic.root_topic&.context&.grants_right?(user, session, :moderate_forum) && !discussion_topic.locked_for?(user, check_policies: true) && !discussion_topic.comments_disabled? }
    can :reply and can :create

    given { |user, session| discussion_topic.root_topic&.context&.grants_right?(user, session, :moderate_forum) }
    can :update and can :delete and can :read

    given { |user, session| discussion_topic.grants_right?(user, session, :rate) }
    can :rate
  end

  scope :active, -> { where.not(workflow_state: "deleted") }
  scope :deleted, -> { where(workflow_state: "deleted") }
  scope :for_user, ->(user) { where(user_id: user).order("discussion_entries.created_at") }
  scope :for_users, ->(users) { where(user_id: users) }
  scope :after, ->(date) { where("created_at>?", date) }
  scope :top_level_for_topics, ->(topics) { where(root_entry_id: nil, discussion_topic_id: topics) }
  scope :all_for_topics, ->(topics) { where(discussion_topic_id: topics) }
  scope :newest_first, -> { order("discussion_entries.created_at DESC, discussion_entries.id DESC") }
  # when there is no discussion_entry_participant for a user, it is considered unread
  scope :unread_for_user, ->(user) { joins(participant_join_sql(user)).where(discussion_entry_participants: { workflow_state: ["unread", nil] }) }
  scope :unread_for_user_before, ->(user, unread_before = 1.minute.ago.utc) { where(discussion_entry_participants: { workflow_state: ["unread", nil] }).or(where("discussion_entry_participants.workflow_state = 'read' AND COALESCE(discussion_entry_participants.read_at, '2022-10-28') >= ?", unread_before)).joins(participant_join_sql(user)) }
  scope :all_for_user, ->(user) { active.where(user_id: user) }
  scope :top_level_for_user, ->(user) { all_for_user(user).where(root_entry_id: nil) }
  scope :non_top_level_for_user, ->(user) { all_for_user(user).where.not(root_entry_id: nil) }

  def self.participant_join_sql(current_user)
    sanitize_sql(["LEFT OUTER JOIN #{DiscussionEntryParticipant.quoted_table_name} ON discussion_entries.id = discussion_entry_participants.discussion_entry_id
      AND discussion_entry_participants.user_id = ?",
                  current_user.id])
  end

  def to_atom(opts = {})
    author_name = user.present? ? user.name : t("atom_no_author", "No Author")
    subject = [discussion_topic.title]
    subject << discussion_topic.context.name if opts[:include_context]
    title = if parent_id
              t "#subject_reply_to", "Re: %{subject}", subject: subject.to_sentence
            else
              subject.to_sentence
            end

    {
      title:,
      author: author_name,
      updated: updated_at,
      published: created_at,
      id: "tag:#{HostUrl.default_host},#{created_at.strftime("%Y-%m-%d")}:/discussion_entries/#{feed_code}",
      link: "http://#{HostUrl.context_host(discussion_topic.context)}/#{discussion_topic.context_prefix}/discussion_topics/#{discussion_topic_id}",
      content: message
    }
  end

  delegate :context, to: :discussion_topic

  delegate :context_id, to: :discussion_topic

  delegate :context_type, to: :discussion_topic

  delegate :title, to: :discussion_topic

  def context_module_action_later
    delay_if_production.context_module_action
  end
  protected :context_module_action_later

  # If this discussion topic is part of an assignment this method is what
  # submits the assignment or updates the submission for the user
  def context_module_action
    if discussion_topic && user
      action = deleted? ? :deleted : :contributed
      discussion_topic.context_module_action(user, action)
    end
  end

  def create_participants
    self.class.connection.after_transaction_commit do
      scope = DiscussionTopicParticipant.where(discussion_topic_id:)
      if discussion_topic.root_topic?
        group_ids = discussion_topic.group_category.groups.active.pluck(:id)
        scope = scope.where.not(
          GroupMembership.where.not(workflow_state: "deleted")
                         .where("group_memberships.user_id=discussion_topic_participants.user_id")
                         .where(group_id: group_ids)
                         .arel.exists
        )
      end
      scope = scope.where("user_id<>?", user) if user
      scope.in_batches(of: 10_000).update_all("unread_entry_count = unread_entry_count + 1")

      if user
        update_or_create_participant(current_user: user, new_state: "read")

        existing_topic_participant = nil
        DiscussionTopicParticipant.unique_constraint_retry do
          existing_topic_participant = discussion_topic.discussion_topic_participants.where(user_id: user).first
          unless existing_topic_participant
            new_count = discussion_topic.default_unread_count - 1
            discussion_topic.discussion_topic_participants.create!(
              user:,
              unread_entry_count: new_count,
              workflow_state: "unread",
              subscribed: !discussion_topic.subscription_hold(user, nil)
            )
          end
        end
        if existing_topic_participant && !existing_topic_participant.subscribed? && !discussion_topic.subscription_hold(user, nil)
          existing_topic_participant.update!(subscribed: true)
        end
      end
    end
  end

  def clear_planner_cache_for_participants
    # If this is a top level reply we do not need to clear the cache here,
    # because the creation of this object will also create a stream item which
    # takes care of clearing the cache
    self.class.connection.after_transaction_commit do
      if root_entry_id.present? && (discussion_topic.for_assignment? || discussion_topic.todo_date.present?)
        User.where(id: discussion_topic.discussion_topic_participants.select(:user_id)).in_batches(of: 10_000).touch_all
      end
    end
  end

  attr_accessor :current_user

  def read_state(current_user = nil)
    current_user ||= self.current_user
    return "read" unless current_user # default for logged out users

    find_existing_participant(current_user).workflow_state
  end

  def rating(current_user = nil)
    current_user ||= self.current_user
    return nil unless current_user # default for logged out users

    find_existing_participant(current_user).rating
  end

  def read?(current_user = nil)
    read_state(current_user) == "read"
  end

  def unread?(current_user = nil)
    !read?(current_user)
  end

  def report_type?(current_user = nil)
    find_existing_participant(current_user).report_type
  end

  # Public: Change the workflow_state of the entry for the specified user.
  #
  # new_state    - The new workflow_state.
  # current_user - The User to to change state for. This function does nothing
  #                if nil is passed. (default: self.current_user)
  # opts         - Additional named arguments (default: {})
  #                :forced - Also set the forced_read_state to this value.
  #
  # Returns nil if current_user is nil, the id of the DiscussionEntryParticipant
  # if the read_state was changed, or true if the read_state was not changed.
  # If the read_state is not changed, a participant record will not be created.
  def change_read_state(new_state, current_user = nil, opts = {})
    current_user ||= self.current_user
    return nil unless current_user

    if new_state == read_state(current_user)
      true
    else
      entry_participant = update_or_create_participant(
        opts.merge(current_user:, new_state:)
      )
      StreamItem.update_read_state_for_asset(self, new_state, current_user.id)
      if entry_participant.present?
        discussion_topic.update_or_create_participant(
          opts.merge(current_user:, offset: ((new_state == "unread") ? 1 : -1))
        )
      end
      entry_participant
    end
  end

  # Public: Change the rating of the entry for the specified user.
  #
  # new_rating    - The new rating.
  # current_user - The User to to change state for. This function does nothing
  #                if nil is passed. (default: self.current_user)
  #
  # Returns nil if current_user is nil, the DiscussionEntryParticipant.id if the
  # rating was changed, or true if the rating was not changed. If the
  # rating is not changed, a participant record will not be created.
  def change_rating(new_rating, current_user = nil)
    current_user ||= self.current_user
    return nil unless current_user

    entry_participant = nil
    transaction do
      lock!
      old_rating = rating(current_user)
      if new_rating == old_rating
        entry_participant = true
        raise ActiveRecord::Rollback
      end

      entry_participant = update_or_create_participant(current_user:, rating: new_rating).first

      update_aggregate_rating(old_rating, new_rating)
    end

    entry_participant
  end

  def change_report_type(report_type, current_user)
    return unless report_type && current_user

    participant_id = update_or_create_participant(current_user:, report_type:).first
    delay.broadcast_report_notification(report_type) if participant_id
  end

  def broadcast_report_notification(report_type)
    return unless context.feature_enabled?(:react_discussions_post)

    to_list = context.instructors_in_charge_of(user_id)

    notification_type = "Reported Reply"
    notification = BroadcastPolicy.notification_finder.by_name(notification_type)

    data = course_broadcast_data
    data[:report_type] = report_type

    GuardRail.activate(:primary) do
      BroadcastPolicy.notifier.send_notification(self, notification_type, notification, to_list, data)
    end
  end

  def update_aggregate_rating(old_rating, new_rating)
    count_delta = (new_rating.nil? ? 0 : 1) - (old_rating.nil? ? 0 : 1)
    sum_delta = new_rating.to_i - old_rating.to_i

    DiscussionEntry.where(id:).update_all([
                                            'rating_count = COALESCE(rating_count, 0) + ?,
        rating_sum = COALESCE(rating_sum, 0) + ?',
                                            count_delta,
                                            sum_delta
                                          ])
    discussion_topic.update_materialized_view
  end

  # Public: Update and save the DiscussionEntryParticipant for a specified user,
  # creating it if necessary. This function properly handles race conditions of
  # calling this function simultaneously in two separate processes.
  #
  # opts - The options for this operation
  #        :current_user - The User that should have its participant updated.
  #                        (default: self.current_user)
  #        :new_state    - The new workflow_state for the participant.
  #        :forced       - The new forced_read_state for the participant.
  #
  # Returns id or nil if no current_user is specified.
  def update_or_create_participant(opts = {})
    current_user = opts[:current_user] || self.current_user
    return nil unless current_user

    DiscussionEntryParticipant.upsert_for_entries(
      self,
      current_user,
      new_state: opts[:new_state],
      forced: opts[:forced],
      rating: opts[:rating],
      report_type: opts[:report_type]
    ).first
  end

  # Public: Find the existing DiscussionEntryParticipant, or create a default
  # participant, for the specified user.
  #
  # user - The User or user_id to lookup the participant for.
  #
  # Returns the DiscussionEntryParticipant for the user, or a participant with
  # default values set. The returned record is marked as readonly! If you need
  # to update a participant, use the #update_or_create_participant method
  # instead.
  def find_existing_participant(user)
    user_id = user.is_a?(User) ? user.id : user
    participant = if discussion_entry_participants.loaded?
                    discussion_entry_participants.detect { |dep| dep.user_id == user_id }
                  else
                    discussion_entry_participants.where(user_id:).first
                  end
    unless participant
      # return a temporary record with default values
      participant = DiscussionEntryParticipant.new({
                                                     workflow_state: "unread",
                                                     forced_read_state: false,
                                                   })
      participant.discussion_entry = self
      participant.user_id = user_id
    end

    # Do not save this record. Use update_or_create_participant instead if you need to save it
    participant.readonly!
    participant
  end

  def set_root_account_id
    self.root_account_id ||= discussion_topic.root_account_id
  end

  def author_name(current_user = nil)
    current_user ||= self.current_user

    if discussion_topic.anonymous?
      discussion_topic_participant = DiscussionTopicParticipant.find_by(discussion_topic_id:, user_id: user.id)
      roles = if context.is_a?(Course)
                Enrollment
                  .joins(:course)
                  .where.not(enrollments: { workflow_state: "deleted" })
                  .where.not(courses: { workflow_state: "deleted" })
                  .where(course_id: context.id)
                  .where(user_id: user.id)
                  .select(:type, :user_id)
                  .distinct
                  .pluck(:type)
              else
                []
              end

      if discussion_topic_participant.user == current_user || roles&.include?("TeacherEnrollment") || roles&.include?("TaEnrollment") || roles&.include?("DesignerEnrollment") || (discussion_topic.anonymous_state == "partial_anonymity" && !is_anonymous_author)
        user.short_name
      else
        t("Anonymous") + " " + discussion_topic_participant&.id.to_s(36)
      end
    else
      user.short_name
    end
  end

  def report_type_counts
    counts = discussion_entry_participants.where.not(report_type: nil).group(:report_type).count

    final_counts = {}
    final_counts["inappropriate_count"] = counts["inappropriate"] || 0
    final_counts["offensive_count"] = counts["offensive"] || 0
    final_counts["other_count"] = counts["other"] || 0
    final_counts["total"] = final_counts["inappropriate_count"] + final_counts["offensive_count"] + final_counts["other_count"]

    final_counts
  end
end
