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

class CourseAccountAssociation < ActiveRecord::Base
  belongs_to :course
  belongs_to :course_section
  belongs_to :account
  has_many :account_users, :foreign_key => 'account_id', :primary_key => 'account_id'

  validates_presence_of :course_id, :account_id, :depth

  before_create :set_root_account_id

  def set_root_account_id
    self.root_account_id ||=
      if account.root_account?
        self.account.id
      else
        self.account&.root_account_id
      end
  end
end
