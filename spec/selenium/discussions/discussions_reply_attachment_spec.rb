# frozen_string_literal: true

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

require_relative "../helpers/discussions_common"
require_relative "../discussions/pages/discussion_page"

describe "reply attachment" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before do
    @topic_title = "discussion topic"
    course_with_teacher_logged_in
    @topic = create_discussion(@topic_title, "threaded")
    @student = student_in_course(active_all: true).user
  end

  before do
    stub_rcs_config
  end

  # ignoring unrelated rce errors
  context "when react_discussions_post ff is OFF", :ignore_js_errors do
    before :once do
      Account.site_admin.disable_feature! :react_discussions_post
    end

    it "prevents XSS by not loading rubric urls in user content" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        message: '{{<div id="rubric_dialog"><div class="select_rubric_link">Click me!</div><a class="select_rubric_url" href="https://google.com"></a></div>}}',
        assignment:
      )
      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f(".admin-links").click
      f(".rubric_dialog_trigger").click
      f(".ui-dialog-titlebar-close").click
      f(".select_rubric_link").click
      browser_logs = driver.logs.get(:browser)
      xss_requests = browser_logs.select { |e| e&.message&.include?("Failed to load resource: net::ERR_NAME_NOT_RESOLVED") }

      expect(xss_requests.length).to eq 0
    end

    it "searches for and adds a rubric" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        assignment:
      )
      rubric = rubric_model({ context: @course })
      rubric.associate_with(assignment, @course, purpose: "grading")

      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f(".admin-links").click
      f(".rubric_dialog_trigger").click
      fj(".find_rubric_link:visible").click
      fj(".select_rubric_link:visible").click

      expect(f(".rubric_title").text).to eq rubric.title
    end

    it "allows reply after cancel" do
      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      f(".discussion-reply-box").click
      wait_for_tiny(f("#root_reply_message_for_#{@topic.id}"))
      f(".cancel_button").click
      force_click(".discussion-reply-box")
      wait_for_ajaximations
      begin
        tinymce = f(".tox-tinymce")
        expect(tinymce.enabled?).to be true
      rescue Selenium::WebDriver::Error::NoSuchElementError
        expect("tinymce not loaded").to eq "loaded"
      end
    end

    it "replies to the discussion with attachment" do
      file_attachment = "graded.png"
      entry_text = "new entry"
      Discussion.visit(@course, @topic)

      add_reply(entry_text, file_attachment)
      expect(get_all_replies.count).to eq 1

      expect(@last_entry.find_element(:css, ".message").text).to eq entry_text
      expect(@last_entry.find_element(:css, ".comment_attachments a.image")).to be_displayed
    end

    it "deletes the attachment from the reply" do
      skip_if_chrome("Cancel button click does not reliably happen")
      file_attachment = "graded.png"
      entry_text = "new entry"
      Discussion.visit(@course, @topic)

      add_reply(entry_text, file_attachment)

      # open the gear menu
      @last_entry.find_element(:css, ".admin-links a").click
      # click on edit
      @last_entry.find_element(:css, ".al-options li.ui-menu-item:nth-of-type(2)").click
      # click on the cancel attachment button
      @last_entry.find_element(:css, ".comment_attachments .cancel_button").click
      # the attachment is hidden
      expect(@last_entry.find_element(:css, ".comment_attachments > div").displayed?).to be(false)

      # click Done
      @last_entry.find_element(:css, ".edit_html_done").click
      # attachment is gone
      expect(@last_entry).not_to contain_css(".comment_attachments")
    end
  end

  context "when react_discussions_post ff is ON", :ignore_js_errors do
    before :once do
      Account.site_admin.enable_feature! :react_discussions_post
    end

    def add_a_reply_react(message = "message!", attachment = nil, file = nil)
      f("button[data-testid='discussion-topic-reply']").click
      wait_for_ajaximations
      type_in_tiny "textarea", message
      if attachment.present? || file.present?
        filename, fullpath, _data = file.nil? ? get_file(attachment) : file

        @filename = filename

        f("[data-testid='attachment-input']").send_keys(fullpath)
      end

      f("button[data-testid='DiscussionEdit-submit'").click
      wait_for_ajaximations
    end

    it "prevents XSS by not loading rubric urls in user content" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        message: '{{<div id="rubric_dialog"><div class="select_rubric_link">Click me!</div><a class="select_rubric_url" href="https://google.com"></a></div>}}',
        assignment:
      )
      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Add Rubric')").click
      f(".ui-dialog-titlebar-close").click
      f(".select_rubric_link").click
      browser_logs = driver.logs.get(:browser)
      xss_requests = browser_logs.select { |e| e&.message&.include?("Failed to load resource: net::ERR_NAME_NOT_RESOLVED") }

      expect(xss_requests.length).to eq 0
    end

    it "searches for and adds a rubric" do
      assignment = @course.assignments.create!(
        name: "Assignment",
        submission_types: ["online_text_entry"],
        points_possible: 20
      )
      dt = @course.discussion_topics.create!(
        title: "Graded Discussion",
        discussion_type: "threaded",
        posted_at: "2017-07-09 16:32:34",
        user: @teacher,
        assignment:
      )
      rubric = rubric_model({ context: @course })
      rubric.associate_with(assignment, @course, purpose: "grading")

      get "/courses/#{@course.id}/discussion_topics/#{dt.id}"

      f("button[data-testid='discussion-post-menu-trigger']").click
      fj("span[role='menuitem']:contains('Show Rubric')").click
      fj(".find_rubric_link:visible").click
      fj(".select_rubric_link:visible").click

      expect(f(".rubric_title").text).to eq rubric.title
    end

    it "can add a mention from the mentions menu" do
      Discussion.visit(@course, @topic)
      f("button[data-testid='discussion-topic-reply']").click
      wait_for_ajaximations
      type_in_tiny "textarea", "@"
      ff("[data-testid='mention-dropdown-item']")[0].click
      f("button[data-testid='DiscussionEdit-submit'").click
      wait_for_ajaximations
      expect(f(".mceNonEditable.mention")).to be_displayed
    end

    it "replies to the discussion with attachment" do
      file_attachment = "graded.png"
      entry_text = "new entry"
      Discussion.visit(@course, @topic)

      add_a_reply_react(entry_text, file_attachment)
      entry = DiscussionEntry.last
      expect(entry.attachment.folder.full_name).to include("/unfiled")

      attachment_link = fj("a:contains('graded')")
      expect(attachment_link).to be_truthy
      expect(attachment_link.attribute("href")).to include("/files/#{entry.attachment.id}")
    end

    it "respects quota limits when replying to the discussion with attachment" do
      Setting.set("user_default_quota", -1)
      file_attachment = "graded.png"
      entry_text = "new entry"

      user_session(@student)
      Discussion.visit(@course, @topic)

      add_a_reply_react(entry_text, file_attachment)
      entry = DiscussionEntry.last

      expect(entry.attachment).to be_falsey
      expect(f("body")).not_to contain_jqcss("a:contains('graded')")
    end

    it "replies to a graded discussion with attachment regardless of quota limit" do
      discussion_assignment = @course.assignments.create!(name: "graded discussion")
      graded_discussion_topic = @course.discussion_topics.create!(title: "graded discussion", assignment: discussion_assignment)

      Setting.set("user_default_quota", -1)
      file_attachment = "graded.png"
      entry_text = "new entry"

      user_session(@student)
      Discussion.visit(@course, graded_discussion_topic)

      add_a_reply_react(entry_text, file_attachment)
      entry = DiscussionEntry.last
      expect(entry.attachment.folder.full_name).to include("/Submissions/#{@course.name}")

      attachment_link = fj("a:contains('graded')")
      expect(attachment_link).to be_truthy
      expect(attachment_link.attribute("href")).to include("/courses/#{@course.id}")
    end

    it "replies to a graded discussion with attachment regardless of quota limit while being a teacher" do
      discussion_assignment = @course.assignments.create!(name: "graded discussion")
      graded_discussion_topic = @course.discussion_topics.create!(title: "graded discussion", assignment: discussion_assignment)

      Setting.set("user_default_quota", -1)
      file_attachment = "graded.png"
      entry_text = "new entry"

      user_session(@teacher)
      Discussion.visit(@course, graded_discussion_topic)

      add_a_reply_react(entry_text, file_attachment)
      entry = DiscussionEntry.last
      expect(entry.attachment.folder.full_name).to include("/Submissions/#{@course.name}")

      attachment_link = fj("a:contains('graded')")
      expect(attachment_link).to be_truthy
      expect(attachment_link.attribute("href")).to include("/courses/#{@course.id}")
    end

    it "replies to a graded discussion topic while repeating attachment names as two different students have the correct context" do
      file_attachment = "graded.png"
      file = get_file(file_attachment)

      root_topic = group_discussion_assignment

      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(active_all: true).user

      @group1.add_user(student1)
      @group1.add_user(student2)

      group1_topic = root_topic.child_topics.where(context_id: @group1.id, context_type: "Group").first

      user_session(student1)

      get "/groups/#{@group1.id}/discussion_topics/#{group1_topic.id}"
      wait_for_ajaximations

      add_a_reply_react("1st entry by Student 1", nil, file)

      attachment_link1 = fj("a:contains('#{@filename}')")
      expect(attachment_link1).to be_truthy

      user_session(student2)

      get "/groups/#{@group1.id}/discussion_topics/#{group1_topic.id}"
      wait_for_ajaximations

      add_a_reply_react("2nd entry by Student 2", nil, file)

      attachment_link2 = fj("a:contains('#{@filename}')")
      expect(attachment_link2).to be_truthy

      attachments = Attachment.last(2)

      expect(attachments[0].context_type).to eq "User"
      expect(attachments[1].context_type).to eq "User"
    end

    it "can view and delete legacy reply attachments" do
      entry = @topic.discussion_entries.create!(
        user: @student,
        message: "new threaded reply from student",
        attachment: attachment_model
      )

      get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      attachment_link = fj("a:contains('#{entry.attachment.filename}')")
      expect(attachment_link).to be_truthy
      expect(attachment_link.attribute("href")).to include("/files/#{entry.attachment.id}")

      f("button[data-testid='thread-actions-menu']").click
      fj("li:contains('Edit')").click
      driver.action.move_to(fj("a:contains('#{entry.attachment.filename}')")).perform # hover
      f("button[data-testid='remove-button']").click
      expect(f("body")).not_to contain_jqcss("a:contains('#{entry.attachment.filename}')")
      fj("button:contains('Save')").click
      wait_for_ajaximations
      expect(f("body")).not_to contain_jqcss("a:contains('#{entry.attachment.filename}')")
    end
  end
end
