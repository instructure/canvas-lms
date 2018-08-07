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

  belongs_to :child_subscription, :class_name => "MasterCourses::ChildSubscription"

  belongs_to :content, polymorphic: [:assessment_question_bank,
                                     :assignment,
                                     :assignment_group,
                                     :attachment,
                                     :calendar_event,
                                     :context_external_tool,
                                     :context_module,
                                     :content_tag,
                                     :discussion_topic,
                                     :learning_outcome,
                                     :learning_outcome_group,
                                     :rubric,
                                     :wiki,
                                     :wiki_page,
                                     quiz: 'Quizzes::Quiz'
  ]
  validates_with MasterCourses::TagValidator

  serialize :downstream_changes, Array # an array of changed columns

  before_create :set_migration_id

  def set_migration_id
    self.migration_id ||= content.migration_id if content.respond_to?(:migration_id)
  end
end
