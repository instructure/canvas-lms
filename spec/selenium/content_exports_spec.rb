#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

require 'nokogiri'

describe "content exports" do
  include_context "in-process server selenium tests"

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    def run_export
      get "/courses/#{@course.id}/content_exports"
      yield if block_given?
      submit_form('#exporter_form')
      @export = keep_trying_until { ContentExport.last }
      @export.export_without_send_later
      new_download_link = f("#export_files a")
      expect(new_download_link).to have_attribute('href', %r{/files/\d+/download\?verifier=})
    end

    it "should allow course export downloads", priority: "1", test_id: 126678 do
      run_export
      expect(@export.export_type).to eq 'common_cartridge'
    end

    it "should allow qti export downloads", priority: "1", test_id: 126680 do
      run_export do
        f("input[value=qti]").click
      end
      expect(@export.export_type).to eq 'qti'
    end

    it "should selectively create qti export", priority: "2", test_id: 1341342 do
      q1 = @course.quizzes.create!(:title => 'quiz1')
      q2 = @course.quizzes.create!(:title => 'quiz2')

      run_export do
        f("input[value=qti]").click
        f(%{.quiz_item[name="copy[quizzes][#{CC::CCHelper.create_key(q2, global: true)}]"]}).click
      end

      expect(@export.export_type).to eq 'qti'

      file_handle = @export.attachment.open :need_local_file => true
      zip_file = Zip::File.open(file_handle.path)
      manifest_doc = Nokogiri::XML.parse(zip_file.read("imsmanifest.xml"))

      expect(manifest_doc.at_css("resource[identifier=#{CC::CCHelper.create_key(q1, global: true)}]")).not_to be_nil
      expect(manifest_doc.at_css("resource[identifier=#{CC::CCHelper.create_key(q2, global: true)}]")).to be_nil
    end
  end
end
