#
# Copyright (C) 2019 - present Instructure, Inc.
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

class ContentShare < ActiveRecord::Base

  belongs_to :user
  belongs_to :content_export
  belongs_to :sender, class_name: 'User', inverse_of: :content_shares
  has_many :receiver_content_shares, through: :content_export, source: :sent_content_shares
  has_many :receivers, through: :receiver_content_shares, source: :user

end
