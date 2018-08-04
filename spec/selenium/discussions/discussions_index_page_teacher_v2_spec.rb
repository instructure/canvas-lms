#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative './pages/discussions_index_page'

describe "discussions index" do
  include_context "in-process server selenium tests"

  context "as a teacher" do
    discussion1_title = 'Meaning of life'
    discussion2_title = 'Meaning of the universe'

    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
      course_with_student(course: @course, active_enrollment: true)

      # Discussion attributes: title, message, delayed_post_at, user
      @discussion1 = @course.discussion_topics.create!(
        title: discussion1_title,
        message: 'Is it really 42?',
        user: @teacher,
        pinned: false
      )
      @discussion2 = @course.discussion_topics.create!(
        title: discussion2_title,
        message: 'Could it be 43?',
        delayed_post_at: 1.day.from_now,
        user: @teacher,
        locked: true,
        pinned: false
      )

      @discussion1.discussion_entries.create!(user: @student, message: "I think I read that somewhere...")
      @discussion1.discussion_entries.create!(user: @student, message: ":eyeroll:")
    end

    def login_and_visit_course(teacher, course)
      user_session(teacher)
      DiscussionsIndex.visit(course)
    end

    def create_course_and_discussion(opts)
      opts.reverse_merge!({ locked: false, pinned: false })
      course = course_factory(:active_all => true)
      discussion = course.discussion_topics.create!(
        title: opts[:title],
        message: opts[:message],
        user: @teacher,
        locked: opts[:locked],
        pinned: opts[:pinned]
      )
      [course, discussion]
    end

    it "discussions can be filtered", test_id:3481189, priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.select_filter("Unread")

      # Attempt to make this test less brittle. It's doing client side filtering
      # with a debounce function, so we need to give it time to perform the filtering
      expect(DiscussionsIndex.discussion(discussion1_title)).to be_displayed
      expect(f('#content')).not_to contain_jqcss(DiscussionsIndex.discussion_title_css(discussion2_title))
    end

    it "search by title works correctly", test_id:3481190, priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.enter_search(discussion1_title)

      # Attempt to make this test less brittle. It's doing client side filtering
      # with a debounce function, so we need to give it time to perform the filtering
      expect(DiscussionsIndex.discussion(discussion1_title)).to be_displayed
      expect(f('#content')).not_to contain_jqcss(DiscussionsIndex.discussion_title_css(discussion2_title))
    end

    it 'clicking the Add Discussion button redirects to new discussion page', test_id:3481193, priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect_new_page_load { DiscussionsIndex.click_add_discussion }
      expect(driver.current_url).to include(DiscussionsIndex.new_discussion_url)
    end

    it 'clicking the publish button changes the published status', test_id:3481203, priority: "1" do
      # Cannot use @discussion[12] here because unpublish requires there to be no posts
      course, discussion = create_course_and_discussion(
        title: 'foo',
        message: 'foo',
      )
      expect(discussion.published?).to be true
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_publish_button('foo')
      wait_for_ajaximations
      discussion.reload
      expect(discussion.published?).to be false
    end

    it 'clicking the subscribe button changes the subscribed status', test_id:3481204, priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect(@discussion1.subscribed?(@teacher)).to be true
      DiscussionsIndex.click_subscribe_button(discussion1_title)
      wait_for_ajaximations
      expect(@discussion1.subscribed?(@teacher)).to be false
    end

    it 'discussion can be moved between groups using Pin menu item', test_id:3481207, priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_pin_menu_option(discussion1_title)
      group = DiscussionsIndex.discussion_group("Pinned Discussions")
      expect(group).to include_text(discussion1_title)
      @discussion1.reload
      expect(@discussion1.pinned).to be true
    end

    it 'unpinning an unlocked discussion goes to the regular bin' do
      course, discussion = create_course_and_discussion(
        title: 'Discussion about aaron',
        message: 'Aaron is aaron',
        locked: false,
        pinned: true
      )
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_pin_menu_option(discussion.title)
      group = DiscussionsIndex.discussion_group("Discussions")
      expect(group).to include_text(discussion.title)
      discussion.reload
      expect(discussion.pinned).to be false
    end

    it 'unpinning a locked discussion goes to the locked bin' do
      course, discussion = create_course_and_discussion(
        title: 'Discussion about landon',
        message: 'Landon is landon',
        locked: true,
        pinned: true
      )
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_pin_menu_option(discussion.title)
      group = DiscussionsIndex.discussion_group("Closed for Comments")
      expect(group).to include_text(discussion.title)
      discussion.reload
      expect(discussion.pinned).to be false
    end

    it 'discussion can be moved to Closed For Comments group using menu item', test_id:3481191, priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_close_for_comments_menu_option(discussion1_title)
      group = DiscussionsIndex.discussion_group("Closed for Comments")
      expect(group).to include_text(discussion1_title)
      @discussion1.reload
      expect(@discussion1.locked).to be true
    end

    it 'closing a pinned discussion stays pinned' do
      course, discussion = create_course_and_discussion(
        title: 'Discussion about steven',
        message: 'Steven is steven',
        locked: false,
        pinned: true
      )
      login_and_visit_course(@teacher, course)
      DiscussionsIndex.click_close_for_comments_menu_option(discussion.title)
      group = DiscussionsIndex.discussion_group("Pinned Discussions")
      expect(group).to include_text(discussion.title)
      discussion.reload
      expect(discussion.locked).to be true
    end

    it 'opening an unpinned discussion moves to "regular"' do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_close_for_comments_menu_option(discussion2_title)
      group = DiscussionsIndex.discussion_group("Discussions")
      expect(group).to include_text(discussion1_title)
      @discussion2.reload
      expect(@discussion2.locked).to be false
    end

    it 'clicking the discussion goes to the discussion page', test_id:3481194, priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect_new_page_load { DiscussionsIndex.click_on_discussion(discussion1_title) }
      expect(driver.current_url).to include(DiscussionsIndex.individual_discussion_url(@discussion1))
    end

    it 'a discussion can be deleted by using Delete menu item and modal', test_id:3481192, priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_delete_menu_option(discussion1_title)
      DiscussionsIndex.click_delete_modal_confirm
      expect(f('#content')).not_to contain_jqcss(DiscussionsIndex.discussion_title_css(discussion1_title))
      expect(DiscussionTopic.where(title: discussion1_title).first.workflow_state).to eq 'deleted'
    end

    it 'a discussion can be duplicated by using Duplicate menu item', test_id:3481202, priority: "1" do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_duplicate_menu_option(discussion1_title)
      expect(DiscussionsIndex.discussion(discussion1_title + " Copy")).to be_displayed
    end

    it 'pill on announcement displays correct number of unread replies', test_id:3481195, priority: "1" do
      login_and_visit_course(@teacher, @course)
      expect(DiscussionsIndex.discussion_unread_pill(discussion1_title)).to eq "2"
    end

    it 'should allow teachers to edit discussions settings' do
      login_and_visit_course(@teacher, @course)
      DiscussionsIndex.click_discussion_settings_button
      DiscussionsIndex.click_create_discussions_checkbox
      DiscussionsIndex.submit_discussion_settings
      wait_for_stale_element(".discussion-settings-v2-spinner-container")
      @course.reload
      expect(@course.allow_student_discussion_topics).to eq false
    end
  end
end
