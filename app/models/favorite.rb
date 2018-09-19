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

class Favorite < ActiveRecord::Base
  belongs_to :context, polymorphic: [:course, :group]
  belongs_to :user
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Group'].freeze
  scope :by, lambda { |type| where(:context_type => type) }

  after_save :touch_user

  def touch_user
    self.class.connection.after_transaction_commit { user.touch }
  end
end
