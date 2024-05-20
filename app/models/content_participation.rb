# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

class ContentParticipation < ActiveRecord::Base
  include Workflow

  ACCESSIBLE_ATTRIBUTES = %i[content user workflow_state content_item].freeze
  CONTENT_ITEMS = %w[grade comment rubric].freeze

  belongs_to :content, polymorphic: [:submission]
  belongs_to :user

  before_create :set_root_account_id
  after_save :update_participation_count

  validates :content_type, :content_id, :user_id, :workflow_state, :content_item, presence: true
  validates :content_item, inclusion: { in: CONTENT_ITEMS }

  workflow do
    state :unread
    state :read
  end

  attr_accessor :unread_count_offset

  def self.create_or_update(opts = {})
    opts = opts.with_indifferent_access
    content = opts.delete(:content)
    user = opts.delete(:user)
    return nil unless user && content

    workflow_state = opts.fetch(:workflow_state, "unread")
    participate(content:, user:, workflow_state:)
  end

  def self.content_posted?(content)
    content.assignment.post_manually? ? content.posted? : true
  end

  def update_participation_count
    return unless saved_change_to_workflow_state?

    offset = ContentParticipation.content_posted?(content) ? unread_count_offset : 0
    ContentParticipationCount.create_or_update({
                                                 context: content.context,
                                                 user:,
                                                 content_type:,
                                                 offset:,
                                               })
  end

  def set_root_account_id
    self.root_account_id = content.assignment.root_account_id
  end

  def self.participate(content:, user:, workflow_state: "unread", content_item: "grade")
    raise "cannot read user and content" unless content.is_a?(Submission) && user.is_a?(User)

    participant = nil
    unique_constraint_retry do
      participations = content.content_participations.where(user_id: user)
      participant = create_first_participation_item(participations, content, user, workflow_state, content_item)
      participant ||= update_existing_participation_item(participations, workflow_state, content_item, content)
      participant ||= add_participation_item(participations, content, user, workflow_state, content_item)
      participant.save! if participant.new_record? || participant.changed?
    end

    participant
  end

  def self.create_first_participation_item(participations, content, user, workflow_state, content_item)
    return if participations.any?

    participant = build_item(content, user, workflow_state, content_item)
    participant.unread_count_offset = (workflow_state == "unread") ? 1 : 0

    participant
  end
  private_class_method :create_first_participation_item

  def self.update_existing_participation_item(participations, workflow_state, content_item, content)
    participant = participations.find { |p| p.content_item == content_item }

    return participant if participant.nil? || !content_posted?(content) || same_workflow_state?(participant, workflow_state)

    participations -= [participant]

    participant.unread_count_offset = if participations.empty? || all_read?(participations)
                                        (workflow_state == "unread") ? 1 : -1
                                      else
                                        0
                                      end
    participant.workflow_state = workflow_state
    participant
  end
  private_class_method :update_existing_participation_item

  def self.add_participation_item(participations, content, user, workflow_state, content_item)
    participant = build_item(content, user, workflow_state, content_item)
    participant.unread_count_offset = (all_read?(participations) && workflow_state == "unread") ? 1 : 0
    participant
  end
  private_class_method :add_participation_item

  def self.all_read?(items)
    items.all? { |participant| participant.workflow_state == "read" }
  end
  private_class_method :all_read?

  def self.build_item(content, user, workflow_state, content_item)
    content.content_participations.build(user:, workflow_state:, content_item:)
  end
  private_class_method :build_item

  def self.same_workflow_state?(participant, workflow_state)
    participant.present? && participant.workflow_state == workflow_state
  end
  private_class_method :same_workflow_state?

  def self.submission_read?(content:, user:)
    submission_read_state(content, user) != "unread"
  end

  def self.submission_item_read?(content:, user:, content_item:)
    submission_read_state(content, user, content_item) != "unread"
  end

  def self.submission_read_state(content, user, content_item = nil)
    raise "content is not a Submission" unless content.is_a?(Submission)
    raise "#{content_item} is invalid" if content_item.present? && !CONTENT_ITEMS.include?(content_item)

    states = if content_item.present?
               ContentParticipation.where(content:, user:, content_item:).pluck(:workflow_state)
             else
               ContentParticipation.where(content:, user:).pluck(:workflow_state)
             end

    return nil if states.empty?
    return "unread" if states.any?("unread")

    "read"
  end

  def self.items_by_submission(participations, workflow_state)
    unread_items = {}

    participations.each do |cp|
      unread_items[cp.content_id] ||= []
      unread_items[cp.content_id] << cp.content_item if cp.workflow_state == workflow_state
    end

    unread_items
  end

  def self.already_read_count(ids = [], user)
    ContentParticipation
      .group(:content_id)
      .where(
        content_type: "Submission",
        content_id: ids,
        user_id: user
      )
      .having("sum(case workflow_state when 'unread' then 1 else 0 end) = 0")
      .pluck(:content_id)
      .count
  end

  def self.create_read_item(user_id:, content_id:, content_item:)
    { user_id:, content_id:, content_type: "Submission", content_item:, workflow_state: "read" }
  end
  private_class_method :create_read_item

  def self.add_missing_content_participation_items(course, user)
    user_id = user.id
    potential_subs_by_type = ContentParticipationCount.potential_submissions_by_type(course, user)
    subs_with_grades, subs_with_comments, subs_with_assessments = potential_subs_by_type.values
    uniq_submission_ids = (subs_with_grades + subs_with_comments + subs_with_assessments).uniq

    cp = ContentParticipation.where(user:, content: uniq_submission_ids).pluck(:content_item, :content_id)

    grouped_cp_items = cp.group_by(&:first).transform_values { |values| values.map(&:last) }

    missing_subs_with_grades = subs_with_grades - (grouped_cp_items["grade"] || [])
    missing_subs_with_comments = subs_with_comments - (grouped_cp_items["comment"] || [])
    missing_subs_with_assessments = subs_with_assessments - (grouped_cp_items["rubric"] || [])

    new_content_participations = missing_subs_with_grades.map do |content_id|
      create_read_item(user_id:, content_id:, content_item: "grade")
    end
    missing_subs_with_comments.each do |content_id|
      new_content_participations << create_read_item(user_id:, content_id:, content_item: "comment")
    end
    missing_subs_with_assessments.each do |content_id|
      new_content_participations << create_read_item(user_id:, content_id:, content_item: "rubric")
    end

    ContentParticipation.insert_all(new_content_participations) if new_content_participations.any?

    new_content_participations
  end

  def self.mark_all_as_read_for_user(user, contents, course)
    content_participations = ContentParticipation.where(user:, content: contents, workflow_state: "unread")
    ids = content_participations.pluck(:id)
    content_participations.update_all(workflow_state: "read")
    cp_count = ContentParticipationCount.find_by(user:, context: course)
    cp_count.refresh_unread_count
    ids
  end
end
