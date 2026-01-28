# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../common"
describe "enhanceable_content" do
  include_context "in-process server selenium tests"

  context "media file preview thumbnails" do
    before do
      stub_kaltura
      course_factory(active_all: true)
      @attachment = @course.attachments.create!(uploaded_data: stub_file_data("video1.mp4", nil, "video/mp4"))
      @page = @course.wiki_pages.build(title: "title")
      @page.body = <<~HTML
        <a id="media_comment_0_deadbeef" class="instructure_file_link instructure_video_link" title="Video.mp4"
          href="/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1">Video</a>
      HTML
      @page.saving_user = @teacher
      @page.save!
    end

    it "shows for students" do
      student_in_course(course: @course, active_user: true)
      user_session(@student)
      get "/courses/#{@course.id}/wiki/#{@page.url}"
      expect(f("#media_comment_0_deadbeef span.media_comment_thumbnail")).to_not be_nil
    end

    describe "for locked files" do
      before do
        @attachment.locked = true
        @attachment.save!
      end

      it "does not show for students" do
        student_in_course(course: @course, active_user: true)
        user_session(@student)
        get "/courses/#{@course.id}/wiki/#{@page.url}"
        expect(f("#content")).not_to contain_css("#media_comment_0_deadbeef span.media_comment_thumbnail")
      end

      it "shows for teachers" do
        teacher_in_course(course: @course, active_user: true)
        user_session(@teacher)
        get "/courses/#{@course.id}/wiki/#{@page.url}"
        expect(f("#media_comment_0_deadbeef span.media_comment_thumbnail")).to_not be_nil
      end
    end
  end
end
