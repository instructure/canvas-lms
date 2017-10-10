#
# Copyright (C) 2017 - present Instructure, Inc.
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


# This needs to run any time someone changes either app/stylesheets/brandable_variables.json
# or one of the images it references. There has to be a predeploy AND a postdeploy migration
# to handle case of anyone saving a new theme in theme editor between when we run predeploys
# and the new code is active. There is code in BrandableCSS that makes sure these 2
# migrations get renamed and ran again when they need to.
class RegenerateBrandFilesBasedOnNewDefaultsPostdeploy < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    BrandConfig.find_each(&:save_all_files!)
  end
end
