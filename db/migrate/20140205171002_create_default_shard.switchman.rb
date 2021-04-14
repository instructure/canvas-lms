# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

# This migration comes from switchman (originally 20130328224244)
class CreateDefaultShard < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    unless Switchman::Shard.default.is_a?(Switchman::Shard)
      Switchman::Shard.reset_column_information
      Switchman::Shard.create!(:default => true)
      Switchman::Shard.default(reload: true)
    end
  end
end
