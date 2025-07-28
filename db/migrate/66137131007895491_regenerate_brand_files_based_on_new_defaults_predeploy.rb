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

# If you've made changes to app/stylesheets/brandable_variables.json or changed
# any of the static assets (like images) referenced in it, you must rename this
# migration file along with its "postdeploy.rb" counterpart in order for your
# changes to take effect.
#
# The numerical prefix for this migration file can be retrieved by running
# the following command in a Rails console after you've compiled the assets
# (the "gulp rev" part specifically):
#
#     BrandableCSS.migration_version
#
# And for the "postdeploy.rb" counterpart:
#
#     BrandableCSS.migration_version + 1
#
# Again, make sure to compile the assets (gulp rev) before running this
# migration:
#
#     rake canvas:compile_assets
#
# The reason there has to be a predeploy AND a postdeploy migration is to handle
# the case of anyone saving a new theme in theme editor between when we run
# predeploys and the new code is active.
class RegenerateBrandFilesBasedOnNewDefaultsPredeploy < ActiveRecord::Migration[5.0]
  tag :predeploy

  def self.runnable?
    !Rails.env.test?
  end

  def up
    BrandConfig.find_each(&:save_all_files!)
  end
end
