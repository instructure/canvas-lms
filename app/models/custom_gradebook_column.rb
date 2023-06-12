# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class CustomGradebookColumn < ActiveRecord::Base
  include Workflow
  acts_as_list scope: :course_id

  belongs_to :course
  has_many :custom_gradebook_column_data

  validates :title, presence: true

  validates :teacher_notes, inclusion: { in: [true, false], message: -> { t("teacher_notes must be true or false") } }
  validates :title,
            length: { maximum: maximum_string_length },
            exclusion: {
              in: GradebookImporter::GRADEBOOK_IMPORTER_RESERVED_NAMES,
              message: -> { t("cannot use gradebook importer reserved names") }
            },
            allow_nil: true

  before_create :set_root_account_id

  workflow do
    state :active
    state :hidden
    state :deleted
  end

  scope :active, -> { where(workflow_state: "active") }
  scope :not_deleted, -> { where("workflow_state != 'deleted'") }

  set_policy do
    given do |user, session|
      course.grants_any_right?(user, session, :view_all_grades, :manage_grades)
    end
    can :read, :manage
  end

  def hidden=(hidden)
    self.workflow_state = if Canvas::Plugin.value_to_boolean(hidden)
                            "hidden"
                          else
                            "active"
                          end
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end

  private

  def set_root_account_id
    self.root_account_id ||= course.root_account_id
  end
end
