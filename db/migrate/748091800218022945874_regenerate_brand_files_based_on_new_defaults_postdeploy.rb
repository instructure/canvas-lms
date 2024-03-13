# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

# !!-----------------~__~_~_-`-`-`-`-------------------_+++++++
#     READ THE NOTES IN THE COUNTERPART "predeploy.rb" FILE.
# !!-----------------~__~_~_-`-`-`-`-------------------_+++++++
class RegenerateBrandFilesBasedOnNewDefaultsPostdeploy < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def self.runnable?
    !Rails.env.test?
  end

  def up
    BrandConfig.find_each(&:save_all_files!)
  end
end
