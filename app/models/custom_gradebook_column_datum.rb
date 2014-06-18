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

class CustomGradebookColumnDatum < ActiveRecord::Base
  belongs_to :custom_gradebook_column

  attr_accessible :content

  EXPORTABLE_ATTRIBUTES = [:id, :content, :user_id, :custom_gradebook_column_id]
  EXPORTABLE_ASSOCIATIONS = [:custom_gradebook_column]

  validates_length_of :content, :maximum => maximum_string_length,
    :allow_nil => true
  validates_uniqueness_of :user_id, :scope => :custom_gradebook_column_id

  set_policy do
    given { |user|
      custom_gradebook_column.grants_right? user, :manage
    }
    can :update
  end
end
