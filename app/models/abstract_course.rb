#
# Copyright (C) 2011 Instructure, Inc.
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

class AbstractCourse < ActiveRecord::Base
  attr_accessible :department, :college, :root_account, :course_code, :name
  belongs_to :root_account, :class_name => 'Account'
  belongs_to :department, :class_name => 'Account'
  belongs_to :college, :class_name => 'Account'
  has_many :course_sections
  named_scope :sis_courses, lambda{|account, *source_ids|
    {:conditions => {:root_account_id => account.id, :sis_source_id => source_ids}, :order => :sis_source_id}
  }
end
