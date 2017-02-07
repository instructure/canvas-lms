#
# Copyright (C) 2016 Instructure, Inc.
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
class UserMergeDataRecord < ActiveRecord::Base
  belongs_to :previous_user, class_name: 'User'
  belongs_to :user_merge_data
  belongs_to :context, polymorphic: [:account_user, :enrollment, :pseudonym,:user_observer,
                                     :attachment, :communication_channel, :user_service]

end
