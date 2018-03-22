#
# Copyright (C) 2018 - present Instructure, Inc.
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

class OneTimePassword < ActiveRecord::Base
  belongs_to :user, inverse_of: :one_time_passwords

  validates :user_id, :code, presence: true
  before_validation :generate_code

  def generate_code
    self.code ||= SecureRandom.random_bytes(Setting.get('one_time_password_length', 8).to_i).each_byte.map do |b|
      (b % 10).to_s
    end.join
  end
end
