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

class SisBatchLogEntry < ActiveRecord::Base
  validates_length_of :text, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  belongs_to :sis_batch
  
  def text=(val)
    if !val || val.length < self.class.maximum_text_length
      write_attribute(:text, val)
    else
      write_attribute(:text, val[0,self.class.maximum_text_length])
    end
  end
  
end
