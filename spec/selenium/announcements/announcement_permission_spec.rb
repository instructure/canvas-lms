#
# Copyright (C) 2016 Instructure, Inc.
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

require_relative '../common'
require_relative '../announcements/announcement_helpers'
require_relative '../discussions/discussion_helpers'
require_relative '../helpers/shared_examples_common'

describe 'announcement permissions' do
  include DiscussionHelpers
  include AnnouncementHelpers
  include SharedExamplesCommon

  include_context "in-process server selenium tests"
  include_context "announcements_page_shared_context"
  include_context "discussions_page_shared_context"
  extend DiscussionHelpers::SetupContext

  context 'discussion created by teacher' do
    before :each do
      course_with_teacher(active_all: true, name: 'teacher1')
      @discussion_topic = DiscussionHelpers.create_discussion_topic(
        @course,
        @teacher,
        'Discussion 1 Title',
        'Discussion 1 message',
        nil
      )
      new_announcement(@course)
    end


    shared_examples 'allow announcement view with discussions disallowed' do |context|
      before :each do
        enable_view_announcements(@course, context_role)
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        user_session(context_user)
      end

      it "allows viewing announcements with discussions disallowed", priority: pick_priority(context, student: "1", observer: "1", teacher: "2", ta: "2", designer: "2"), test_id: pick_test_id(context, student: "779908", teacher: "779909", ta: "779910", observer: "779911", designer: "779912") do
        get announcements_page
        expect(fj(announcement_message)).to be_displayed
      end
    end

    it_behaves_like 'allow announcement view with discussions disallowed', :student do
      setup_student_context
    end

    it_behaves_like 'allow announcement view with discussions disallowed', :teacher do
      let(:context_user) { @teacher }
      let(:context_role) { teacher_role }
    end

    it_behaves_like 'allow announcement view with discussions disallowed', :ta do
      setup_ta_context
    end

    it_behaves_like 'allow announcement view with discussions disallowed', :observer do
      setup_observer_context
    end

    it_behaves_like 'allow announcement view with discussions disallowed', :designer do
      setup_designer_context
    end


    shared_examples 'disallow announcement view with discussions disallowed' do |context|
      before :each do
        disable_view_announcements(@course, context_role)
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        user_session(context_user)
      end

      it "does not allow user to view announcements", priority: pick_priority(context, student: "1", observer: "1"), test_id: pick_test_id(context, student: "790700", observer: "790701") do
        get announcements_page
        assert_flash_notice_message course_page_disabled_notice
      end

      it "shows no announcements link on course page", priority: pick_priority(context, student: "1", observer: "1"), test_id: pick_test_id(context, student: "790702", observer: "790703") do
        get course_page
        expect(f(course_section_tabs)).not_to contain_css(announcement_link)
      end
    end

    it_behaves_like 'disallow announcement view with discussions disallowed', :student do
      setup_student_context
    end

    it_behaves_like 'disallow announcement view with discussions disallowed', :observer do
      setup_observer_context
    end


    shared_examples 'disallow discussion topic view with announcements allowed' do |context|
      before :each do
        enable_view_announcements(@course, context_role)
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        user_session(context_user)
      end

      it "allows announcement view, discussion topic view disabled", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2"), test_id: pick_test_id(context, student: "803850", teacher: "804384", ta: "804385", observer: "804386", designer: "804387") do
        get discussions_topic_page
        expect(find(unauthorized_message)).to be_displayed
      end

      it "shows announcements link on course page", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2"), test_id: pick_test_id(context, student: "804655", teacher: "804656", ta: "804657", observer: "804658", designer: "804659") do
        get course_page
        expect(f(announcement_link)).to be_displayed
      end
    end

    it_behaves_like 'disallow discussion topic view with announcements allowed', :student do
      setup_student_context
    end

    it_behaves_like 'disallow discussion topic view with announcements allowed', :teacher do
      let(:context_user) { @teacher }
      let(:context_role) { teacher_role }
    end

    it_behaves_like 'disallow discussion topic view with announcements allowed', :ta do
      setup_ta_context
    end

    it_behaves_like 'disallow discussion topic view with announcements allowed', :observer do
      setup_observer_context
    end

    it_behaves_like 'disallow discussion topic view with announcements allowed', :designer do
      setup_designer_context
    end


    shared_examples 'disallow discussion detail view with announcements allowed' do |context|
      before :each do
        enable_view_announcements(@course, context_role)
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        user_session(context_user)
      end

      it "allows user to view announcements, discussion detail view disabled", priority: pick_priority(context, student: "1", ta: "2", observer: "1", designer: "2"), test_id: pick_test_id(context, student: "805192", ta: "805193", observer: "805194", designer: "805195") do
        get discussions_topic_detail_page
        expect(find(unauthorized_message)).to be_displayed
      end
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :student do
      setup_student_context
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :ta do
      setup_ta_context
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :observer do
      setup_observer_context
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :designer do
      setup_designer_context
    end
  end


  context 'discussion created by student' do
    before :each do
      course_with_student(active_all: true, name: 'student1')
      @discussion_topic = DiscussionHelpers.create_discussion_topic(
        @course,
        @student,
        'Discussion 1 Title',
        'Discussion 1 message',
        nil
      )
      new_announcement(@course)
    end


    shared_examples 'disallow discussion detail view with announcements allowed' do |context|
      before :each do
        enable_view_announcements(@course, context_role)
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        user_session(context_user)
      end

      it "does not allow user to view discussion details with announcements allowed", priority: pick_priority(context, teacher: "2", ta: "2", observer: "1", designer: "2"), test_id: pick_test_id(context, teacher: "805196", ta: "805463", observer: "805464", designer: "805465") do
        get discussions_topic_detail_page
        expect(find(unauthorized_message)).to be_displayed
      end
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :teacher do
      setup_teacher_context
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :ta do
      setup_ta_context
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :observer do
      setup_observer_context
    end

    it_behaves_like 'disallow discussion detail view with announcements allowed', :designer do
      setup_designer_context
    end
  end
end
