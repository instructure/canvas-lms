#
# Copyright (C) 2012 Instructure, Inc.
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
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

class UserProfileLink < ActiveRecord::Base
  belongs_to :user_profile

  validates :title, length: { maximum: maximum_string_length, allow_nil: true, allow_blank: true }
  validates :url, length: { maximum: 4.kilobytes-1, allow_nil: false, allow_blank: true }
  include CustomValidations
  validates_as_url :url
end
