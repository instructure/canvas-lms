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

class MasterCourses::ChildContentTag < ActiveRecord::Base
  # can never have too many content tags

  # stores change data on the associated course
  # i.e. which objects were changed from their blueprint versions and what columns (and pseudo-columns)
  # so we don't overwrite intentional changes during a sync (unless the object gets locked)

  belongs_to :child_subscription, class_name: "MasterCourses::ChildSubscription"

  belongs_to :content, polymorphic: [:assessment_question_bank,
                                     :assignment,
                                     :assignment_group,
                                     :attachment,
                                     :calendar_event,
                                     :context_external_tool,
                                     :context_module,
                                     :content_tag,
                                     :course_pace,
                                     :discussion_topic,
                                     :learning_outcome,
                                     :learning_outcome_group,
                                     :media_track,
                                     :rubric,
                                     :wiki,
                                     :wiki_page,
                                     quiz: "Quizzes::Quiz"]
  belongs_to :root_account, class_name: "Account"

  validates_with MasterCourses::TagValidator

  serialize :downstream_changes, type: Array # an array of changed columns

  before_create :set_migration_id
  before_create :set_root_account_id

  def set_migration_id
    self.migration_id ||= content.migration_id if content.respond_to?(:migration_id)
  end

  def set_root_account_id
    self.root_account_id ||= child_subscription.root_account_id
  end
end
