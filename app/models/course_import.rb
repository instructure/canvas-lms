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

class CourseImport < ActiveRecord::Base
  include Workflow
  attr_accessible :course, :source, :import_type
  serialize :log
  belongs_to :course
  belongs_to :source, :class_name => 'Course'
  validates_length_of :added_item_codes, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  
  workflow do
    state 'started'
    state 'completed'
    state 'failed'
  end
  
  def tick(max_tick=100)
    self.progress ||= 0
    update_attribute(:progress, [(self.progress + 1), max_tick, 100].min)
  end
  
  named_scope :for_course, lambda{|course, type|
    {:conditions => ['course_imports.course_id = ? AND course_imports.import_type = ?', course.id, type], :order => 'course_imports.created_at DESC' }
  }
end
