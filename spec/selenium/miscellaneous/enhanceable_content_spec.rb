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
  it "automatically enhances content using jQuery UI" do
    stub_kaltura
    course_with_teacher_logged_in
    page = @course.wiki_pages.build(title: "title")
    page.body = %{
      <div id="dialog_for_link1" class="enhanceable_content dialog">dialog for link 1</div>
      <a href="#dialog_for_link1" id="link1">link 1</a>
      <div class="enhanceable_content draggable" style="width: 100px;">draggable</div>
      <div class="enhanceable_content resizable" style="width: 100px;">resizable</div>
      <ul class="enhanceable_content sortable" style="display: none;">
        <li>item 1</li>
        <li>item 2</li>
      </ul>
      <div class="enhanceable_content tabs">
        <ul>
            <li><a href="#fragment-1"><span>One</span></a></li>
            <li><a href="#fragment-2"><span>Two</span></a></li>
            <li><a href="#fragment-3"><span>Three</span></a></li>
        </ul>
        <div id="fragment-1">
            <p>First tab is active by default:</p>
            <pre><code>$('#example').tabs();</code></pre>
        </div>
        <div id="fragment-2">
            Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.
        </div>
        <div id="fragment-3">
            Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.
        </div>
      </div>
      <a id="media_comment_0_deadbeef" class="instructure_file_link instructure_video_link" title="Video.mp4" href="/courses/1/files/1/download?wrap=1">Video</a>
    }
    page.save!
    get "/courses/#{@course.id}/wiki/#{page.url}"
    dialog = f(".enhanceable_content.dialog")
    f("#link1").click
    expect(dialog).to be_displayed
    expect(dialog).to have_class("ui-dialog")
    f(".ui-dialog .ui-dialog-titlebar-close").click
    expect(dialog).not_to be_displayed
    expect(f(".enhanceable_content.draggable")).to have_class("ui-draggable")
    expect(f(".enhanceable_content.resizable")).to have_class("ui-resizable")
    ul = f(".enhanceable_content.sortable")
    expect(ul).to be_displayed
    expect(ul).to have_class("ui-sortable")
    tabs = f(".enhanceable_content.tabs")
    expect(tabs).to have_class("ui-tabs")
    headers = tabs.find_elements(:css, ".ui-tabs-nav li")
    expect(headers.length).to eq 3
    divs = tabs.find_elements(:css, ".ui-tabs-panel")
    expect(divs.length).to eq 3
    expect(headers[0]).to have_class("ui-state-active")
    expect(headers[1]).to have_class("ui-state-default")
    expect(divs[0]).to be_displayed
    expect(divs[1]).not_to be_displayed
    expect(f("#media_comment_0_deadbeef span.media_comment_thumbnail")).not_to be_nil
  end

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
