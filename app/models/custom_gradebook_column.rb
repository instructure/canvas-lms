#
# Copyright (C) 2013 Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under the
# terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

class CustomGradebookColumn < ActiveRecord::Base
  include Workflow
  acts_as_list :scope => :course_id

  belongs_to :course
  has_many :custom_gradebook_column_data

  attr_accessible :title, :position, :teacher_notes, :hidden

  EXPORTABLE_ATTRIBUTES = [:id, :title, :position, :workflow_state, :course_id, :created_at, :updated_at, :teacher_notes]
  EXPORTABLE_ASSOCIATIONS = [:course, :custom_gradebook_column_data]

  validates_presence_of :title
  validates_length_of :title, :maximum => maximum_string_length,
    :allow_nil => true

  workflow do
    state :active
    state :hidden
    state :deleted
  end

  scope :active, -> { where(workflow_state: "active") }
  scope :not_deleted, -> { where("workflow_state != 'deleted'") }

  set_policy do
    given { |user, session|
      course.grants_any_right?(user, session, :view_all_grades, :manage_grades)
    }
    can :read, :manage
  end

  def hidden=(hidden)
    self.workflow_state = Canvas::Plugin::value_to_boolean(hidden) ?
                            "hidden" :
                            "active"
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = "deleted"
    save!
  end
end
