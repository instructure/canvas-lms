#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "jammit" do
  describe "i18n" do
    it "should include core en translations" do
      get_via_redirect "/login"
      assert_response :success
      response.body.should include "/javascripts/translations/_core.js"
    end

    it "should include appropriate locale translations" do
      touch_js_translations(:common) do
        Jammit.reload!
        get_via_redirect "/login"
        assert_response :success
        response.body.should include "/javascripts/translations/common.js"
      end
    end

    def touch_js_translations(bundle)
      path = "public/javascripts/translations/#{bundle}.js"
      file_exists = File.exist?(path)
      FileUtils.touch path # we don't actually care about the contents, jammit will link to it if its present
      yield if block_given?
    ensure
      File.unlink path unless file_exists
    end
  end
end