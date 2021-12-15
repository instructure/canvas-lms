# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative "../discussions/discussion_helpers"
require_relative "../helpers/shared_examples_common"

describe "discussion permissions" do
  include SharedExamplesCommon
  include DiscussionHelpers
  include_context "in-process server selenium tests"
  include_context "discussions_page_shared_context"
  extend DiscussionHelpers::SetupContext

  context "discussion created by teacher" do
    before do
      course_with_teacher(active_all: true, name: "teacher1")
      @discussion_topic = DiscussionHelpers.create_discussion_topic(
        @course,
        @teacher,
        "Discussion 1 Title",
        "Discussion 1 message",
        nil
      )
    end

    shared_examples "no viewing discussion title, no discussion link" do |context|
      before do
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        DiscussionHelpers.disable_create_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "disallows discussion title view", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_page
        expect(find(unauthorized_message)).to be_displayed
      end

      it "does not show course page discusions link", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2") do
        get course_page
        expect(f(course_navigation_items)).not_to contain_link(discussions_link)
      end
    end

    it_behaves_like "no viewing discussion title, no discussion link", :student do
      setup_student_context
    end

    it_behaves_like "no viewing discussion title, no discussion link", :teacher do
      let(:context_user) { @teacher }
      let(:context_role) { teacher_role }
    end

    it_behaves_like "no viewing discussion title, no discussion link", :ta do
      setup_ta_context
    end

    it_behaves_like "no viewing discussion title, no discussion link", :observer do
      setup_observer_context
    end

    it_behaves_like "no viewing discussion title, no discussion link", :designer do
      setup_designer_context
    end

    shared_examples "no viewing discussion details" do |context|
      before do
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "disallows discussion detail view", priority: pick_priority(context, student: "1", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(find(unauthorized_message)).to be_displayed
      end
    end

    it_behaves_like "no viewing discussion details", :student do
      setup_student_context
    end

    it_behaves_like "no viewing discussion details", :ta do
      setup_ta_context
    end

    it_behaves_like "no viewing discussion details", :observer do
      setup_observer_context
    end

    it_behaves_like "no viewing discussion details", :designer do
      setup_designer_context
    end

    shared_examples "allow viewing discussions, not edit or post" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows discussion view, not edit or post", priority: pick_priority(context, student: "1", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_container)).not_to contain_css(discussion_reply_button)
        expect(f(discussion_container)).not_to contain_css(discussion_edit_button)
      end
    end

    it_behaves_like "allow viewing discussions, not edit or post", :student do
      setup_student_context
    end

    it_behaves_like "allow viewing discussions, not edit or post", :ta do
      setup_ta_context
    end

    it_behaves_like "allow viewing discussions, not edit or post", :observer do
      setup_observer_context
    end

    it_behaves_like "allow viewing discussions, not edit or post", :designer do
      setup_designer_context
    end

    shared_examples "allow viewing and posting to discussions, not edit" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.enable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows discussion view and post, not edit", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_reply_button)).to be_displayed
        expect(f(discussion_container)).not_to contain_css(discussion_edit_button)
      end
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :student do
      setup_student_context
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :teacher do
      let(:context_user) { @teacher }
      let(:context_role) { teacher_role }
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :ta do
      setup_ta_context
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :observer do
      setup_observer_context
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :designer do
      setup_designer_context
    end

    shared_examples "allow viewing and editing discussions, not posting" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.enable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows discussion view and edit, not post", priority: pick_priority(context, student: "1", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_container)).not_to contain_css(discussion_reply_button)
        expect(f(discussion_edit_button)).to be_displayed
      end
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :student do
      setup_student_context
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :ta do
      setup_ta_context
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :observer do
      setup_observer_context
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :designer do
      setup_designer_context
    end

    shared_examples "allow view, edit and post to discussions" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.enable_moderate_discussions(@course, context_role)
        DiscussionHelpers.enable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows discussion view, edit, and post", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_reply_button)).to be_displayed
        expect(f(discussion_edit_button)).to be_displayed
      end
    end

    it_behaves_like "allow view, edit and post to discussions", :student do
      setup_student_context
    end

    it_behaves_like "allow view, edit and post to discussions", :teacher do
      let(:context_user) { @teacher }
      let(:context_role) { teacher_role }
    end

    it_behaves_like "allow view, edit and post to discussions", :ta do
      setup_ta_context
    end

    it_behaves_like "allow view, edit and post to discussions", :observer do
      setup_observer_context
    end

    it_behaves_like "allow view, edit and post to discussions", :designer do
      setup_designer_context
    end
  end # context 'discussion created by teacher'

  context "discussion created by student" do
    before do
      course_with_student(active_all: true, name: "student1")
      @discussion_topic = DiscussionHelpers.create_discussion_topic(
        @course,
        @student,
        "Student Discussion 1 Title",
        "Student Discussion 1 message",
        nil
      )
    end

    shared_examples "no viewing discussion title" do |context|
      before do
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "does not allow user to view discussion title", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_page
        expect(find(unauthorized_message)).to be_displayed
      end
    end

    it_behaves_like "no viewing discussion title", :student do
      let(:context_user) { @student }
      let(:context_role) { student_role }
    end

    it_behaves_like "no viewing discussion title", :teacher do
      setup_teacher_context
    end

    it_behaves_like "no viewing discussion title", :ta do
      setup_ta_context
    end

    it_behaves_like "no viewing discussion title", :observer do
      setup_observer_context
    end

    it_behaves_like "no viewing discussion title", :designer do
      setup_designer_context
    end

    shared_examples "no viewing discussion details" do |context|
      before do
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "does not allow user to view discussion details", priority: pick_priority(context, teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(find(unauthorized_message)).to be_displayed
      end
    end

    it_behaves_like "no viewing discussion details", :teacher do
      setup_teacher_context
    end

    it_behaves_like "no viewing discussion details", :ta do
      setup_ta_context
    end

    it_behaves_like "no viewing discussion details", :observer do
      setup_observer_context
    end

    it_behaves_like "no viewing discussion details", :designer do
      setup_designer_context
    end

    shared_examples "allow viewing discussions, not edit or post" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows viewing discussions, not edit or post", priority: pick_priority(context, teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_container)).not_to contain_css(discussion_reply_button)
        expect(f(discussion_container)).not_to contain_css(discussion_edit_button)
      end
    end

    it_behaves_like "allow viewing discussions, not edit or post", :teacher do
      setup_teacher_context
    end

    it_behaves_like "allow viewing discussions, not edit or post", :ta do
      setup_ta_context
    end

    it_behaves_like "allow viewing discussions, not edit or post", :observer do
      setup_observer_context
    end

    it_behaves_like "allow viewing discussions, not edit or post", :designer do
      setup_designer_context
    end

    shared_examples "allow viewing and posting to discussions, not edit" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.enable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows discussion view and post, not edit", priority: pick_priority(context, teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_reply_button)).to be_displayed
        expect(f(discussion_container)).not_to contain_css(discussion_edit_button)
      end
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :teacher do
      setup_teacher_context
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :ta do
      setup_ta_context
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :observer do
      setup_observer_context
    end

    it_behaves_like "allow viewing and posting to discussions, not edit", :designer do
      setup_designer_context
    end

    shared_examples "allow viewing and editing discussions, not posting" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.enable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows discussion view and edit, not post", priority: pick_priority(context, teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_container)).not_to contain_css(discussion_reply_button)
        expect(f(discussion_edit_button)).to be_displayed
      end
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :teacher do
      setup_teacher_context
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :ta do
      setup_ta_context
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :observer do
      setup_observer_context
    end

    it_behaves_like "allow viewing and editing discussions, not posting", :designer do
      setup_designer_context
    end

    shared_examples "allow view, edit and post to discussions" do |context|
      before do
        DiscussionHelpers.enable_view_discussions(@course, context_role)
        DiscussionHelpers.enable_moderate_discussions(@course, context_role)
        DiscussionHelpers.enable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows discussion view, edit and post", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2") do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_reply_button)).to be_displayed
        expect(f(discussion_edit_button)).to be_displayed
      end

      it "shows the discusions link on the course page", priority: pick_priority(context, student: "1", teacher: "2", ta: "2", observer: "1", designer: "2") do
        get course_page
        expect(find(discussion_link)).to be_displayed
      end
    end

    it_behaves_like "allow view, edit and post to discussions", :student do
      let(:context_user) { @student }
      let(:context_role) { student_role }
    end

    it_behaves_like "allow view, edit and post to discussions", :teacher do
      setup_teacher_context
    end

    it_behaves_like "allow view, edit and post to discussions", :ta do
      setup_ta_context
    end

    it_behaves_like "allow view, edit and post to discussions", :observer do
      setup_observer_context
    end

    it_behaves_like "allow view, edit and post to discussions", :designer do
      setup_designer_context
    end

    shared_examples "allow view, edit and post to own discussions with permissions off" do
      before do
        DiscussionHelpers.disable_view_discussions(@course, context_role)
        DiscussionHelpers.disable_moderate_discussions(@course, context_role)
        DiscussionHelpers.disable_post_to_discussions(@course, context_role)
        context_user.touch
        user_session(context_user)
      end

      it "allows own discussion view, edit, and post with permissions off", priority: "1" do
        get discussions_topic_detail_page
        expect(fj(discussion_message)).to be_displayed
        expect(f(discussion_reply_button)).to be_displayed
        expect(f(discussion_edit_button)).to be_displayed
      end
    end

    it_behaves_like "allow view, edit and post to own discussions with permissions off", :student do
      let(:context_user) { @student }
      let(:context_role) { student_role }
    end
  end # context 'discussion created by student'
end # describe "discussion permissions"
