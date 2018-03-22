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

describe "BaseWebpackConfig.js" do
  it "uses an IgnorePlugin to properly exlcude all the moment locales from the vendor bundle" do
    # this doesn't acutally need selenium but we put it in spec/selenium so
    # it runs in jenkins where it has already built our webpack bundles so
    # the .js files DO exist

    # it DOES include moment.js
    expect(`fgrep '!*** ./node_modules/moment/moment.js ***!' public/dist/webpack-*/vendor*`).to be_present

    # it DOESN'T include any of the moment bundles
    expect(`fgrep '!*** ./node_modules/moment/locale/' public/dist/webpack-*/vendor*`).not_to be_present
  end
end
