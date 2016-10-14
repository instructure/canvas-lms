#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

class Ignore < ActiveRecord::Base
  belongs_to :user
  belongs_to :asset, polymorphic: [:assignment, :assessment_request, :quiz => 'Quizzes::Quiz']

  attr_accessible :user, :asset, :purpose, :permanent
  validates_presence_of :user_id, :asset_id, :asset_type, :purpose
  validates_inclusion_of :permanent, :in => [false, true]

  def self.cleanup
    # This may need an index in the future. right now it's just a table scan,
    # cause I have no idea how many ignores are created
    Ignore.where("updated_at<?", 6.months.ago).delete_all
  end
end
