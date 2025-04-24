# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/files_common"
require_relative "../helpers/public_courses_context"

describe "file show page" do
  include_context "in-process server selenium tests"
  include FilesCommon

  describe "html file" do
    before(:once) do
      course_with_teacher(active_all: true)
      @html_file = add_file(
        fixture_file_upload("test.html", "text/html"),
        @course,
        "test.html"
      )
    end

    before do
      user_session @teacher
    end

    context "when disable_iframe_sandbox_file_show is disabled" do
      before do
        @course.account.root_account.disable_feature! :disable_iframe_sandbox_file_show
      end

      it "show the file in a sandboxed iframe" do
        get "/courses/#{@course.id}/files/#{@html_file.id}"

        iframe = f("#file_content")
        expect(iframe.attribute("sandbox")).to eq "allow-same-origin"
      end
    end

    context "when disable_iframe_sandbox_file_show is enabled" do
      before do
        @course.account.root_account.enable_feature! :disable_iframe_sandbox_file_show
      end

      it "show the file in an iframe without sandbox attribute" do
        get "/courses/#{@course.id}/files/#{@html_file.id}"

        iframe = f("#file_content")
        expect(iframe.attribute("sandbox")).to be_nil
      end
    end
  end
end
