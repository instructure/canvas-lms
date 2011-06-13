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

class ScribdAccount < ActiveRecord::Base
  belongs_to :scribdable, :polymorphic => true
  has_many :attachments

  attr_accessible :scribdable, :scribdable_id, :scribdable_type, :uuid

  before_create :assure_uuid
  
  def assure_uuid
    self.uuid ||= AutoHandle.generate_securish_uuid
  end
  private :assure_uuid
  
  def self.serialization_excludes; [:uuid]; end
end
