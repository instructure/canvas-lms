# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class MasterCourses::MasterContentTag < ActiveRecord::Base
  # i want to get off content tag's wild ride

  # stores restriction data on the blueprint side
  # i.e. which objects are locked and what parts
  # and makes for easy restriction lookup from the associated course side via matching migration_id columns
  # NOTE: this fact means that locking/unlocking an object takes immediate effect (and is independent of syncs)

  belongs_to :master_template, class_name: "MasterCourses::MasterTemplate"
  belongs_to :content, polymorphic: [:assessment_question_bank,
                                     :assignment,
                                     :assignment_group,
                                     :attachment,
                                     :calendar_event,
                                     :context_external_tool,
                                     :context_module,
                                     :course_pace,
                                     :discussion_topic,
                                     :learning_outcome,
                                     :media_track,
                                     :rubric,
                                     :wiki_page,
                                     quiz: "Quizzes::Quiz"]
  belongs_to :assignment, -> { where(master_courses_master_content_tags: { content_type: "Assignment" }) }, foreign_key: "content_id", inverse_of: :master_content_tag
  belongs_to :attachment, -> { where(master_courses_master_content_tags: { content_type: "Attachment" }) }, foreign_key: "content_id", inverse_of: :master_content_tag
  belongs_to :context_module, -> { where(master_courses_master_content_tags: { content_type: "ContextModule" }) }, foreign_key: "content_id", inverse_of: :master_content_tag
  belongs_to :discussion_topic, -> { where(master_courses_master_content_tags: { content_type: "DiscussionTopic" }) }, foreign_key: "content_id", inverse_of: :master_content_tag
  belongs_to :quiz, -> { where(master_courses_master_content_tags: { content_type: "Quizzes::Quiz" }) }, foreign_key: "content_id", class_name: "Quizzes::Quiz", inverse_of: :master_content_tag
  belongs_to :wiki_page, -> { where(master_courses_master_content_tags: { content_type: "WikiPage" }) }, foreign_key: "content_id", inverse_of: :master_content_tag

  belongs_to :root_account, class_name: "Account"
  validates_with MasterCourses::TagValidator

  serialize :restrictions, type: Hash
  validate :require_valid_restrictions

  before_create :set_migration_id
  before_create :set_root_account_id

  before_save :mark_touch_content_if_restrictions_tightened
  after_save :touch_content_if_restrictions_tightened

  def set_migration_id
    self.migration_id = master_template.migration_id_for(content)
  end

  def set_root_account_id
    self.root_account_id = master_template.root_account_id
  end

  def require_valid_restrictions
    # this may be changed in the future
    if restrictions_changed? &&
       restrictions.keys != [:all] &&
       (restrictions.keys - MasterCourses::LOCK_TYPES).any?
      errors.add(:restrictions, "Invalid settings")
    end
  end

  def mark_touch_content_if_restrictions_tightened
    if !new_record? && restrictions_changed? && restrictions.any? { |type, locked| locked && !restrictions_was[type] }
      @touch_content = true # set if restrictions for content or settings is true now when it wasn't before so we'll re-export and overwrite any changed content
    end
  end

  def touch_content_if_restrictions_tightened
    if @touch_content
      content.touch
      @touch_content = false
    end
  end

  def self.fetch_module_item_restrictions_for_child(item_ids)
    # does a silly fancy doublejoin so we can get all the restrictions in one query
    data =
      joins("INNER JOIN #{MasterCourses::ChildContentTag.quoted_table_name} ON
          #{table_name}.migration_id=#{MasterCourses::ChildContentTag.table_name}.migration_id")
      .joins("INNER JOIN #{ContentTag.quoted_table_name} ON
          #{MasterCourses::ChildContentTag.table_name}.content_type=#{ContentTag.table_name}.content_type AND
          #{MasterCourses::ChildContentTag.table_name}.content_id=#{ContentTag.table_name}.content_id")
      .where(content_tags: { id: item_ids })
      .pluck("content_tags.id", :restrictions)
    data.to_h
  end

  def self.fetch_module_item_restrictions_for_master(item_ids)
    data =
      joins("INNER JOIN #{ContentTag.quoted_table_name} ON
          #{table_name}.content_type=#{ContentTag.table_name}.content_type AND
          #{table_name}.content_id=#{ContentTag.table_name}.content_id")
      .where(content_tags: { id: item_ids })
      .pluck("content_tags.id", :restrictions)
    hash = data.to_h
    (item_ids - hash.keys).each do |missing_id| # populate blank restrictions for all items without mastercontenttags created yet
      hash[missing_id] = {}
    end
    hash
  end

  def quiz_lti_content?
    return false if content_type != Assignment.to_s

    content.quiz_lti?
  end

  def self.polymorphic_assoc_for(klass)
    return :quiz if klass == Quizzes::Quiz
    return :discussion_topic if klass == Announcement

    klass.name.underscore.to_sym
  end
end
