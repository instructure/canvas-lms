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

require File.expand_path(File.dirname(__FILE__) + '/../../helpers/discussions_common')

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:student_topic) { course.discussion_topics.create!(user: student, title: 'student topic title', message: 'student topic message') }
  let(:teacher_topic) { course.discussion_topics.create!(user: teacher, title: 'teacher topic title', message: 'teacher topic message') }
  let(:assignment_group) { course.assignment_groups.create!(name: 'assignment group') }
  let(:assignment) { course.assignments.create!(
      name: 'assignment',
      #submission_types: 'discussion_topic',
      assignment_group: assignment_group
  ) }
  let(:assignment_topic) do
    course.discussion_topics.create!(user: teacher,
                                     title: 'assignment topic title',
                                     message: 'assignment topic message',
                                     assignment: assignment)
  end
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: 'teacher entry') }

  let(:group) do
    @category1 = course.group_categories.create!(name: "category 1")
    @category1.configure_self_signup(true, false)
    @category1.save!
    @g1 = course.groups.create!(name: "some group", group_category: @category1)
    @g1.save!
  end

  before(:each) do
    stub_rcs_config
  end

  context "on the show page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/" }

    context "as a student" do
      let(:topic) { student_topic }

      before(:each) do
        user_session(student)
        enable_all_rcs @course.account
      end

      context "teacher topic" do
        let(:topic) { teacher_topic }

        it "should allow students to reply to a discussion even if they cannot create a topic", priority: "2", test_id: 344535 do
          course.allow_student_discussion_topics = false
          course.save!
          get url
          wait_for_animations
          new_student_entry_text = "Hello there"
          wait_for_animations
          expect(f('#content')).not_to include_text(new_student_entry_text)
          add_reply new_student_entry_text
          expect(f('#content')).to include_text(new_student_entry_text)
        end

        it "should display the subscribe button after an initial post", priority: "1", test_id: 150484 do
          topic.unsubscribe(student)
          topic.require_initial_post = true
          topic.save!

          get url

          wait_for_ajaximations
          expect(f('.topic-unsubscribe-button')).not_to be_displayed
          expect(f('.topic-subscribe-button')).not_to be_displayed

          f('.discussion-reply-action').click
          wait_for_ajaximations
          type_in_tiny 'textarea', 'initial post text'
          scroll_to_submit_button_and_click('.discussion-reply-form')
          wait_for_ajaximations
          expect(f('.topic-unsubscribe-button')).to be_displayed
        end

        it "should validate that a student can see it and reply to a discussion", priority: "1", test_id: 150475 do
          new_student_entry_text = 'new student entry'
          get url
          expect(f('.message_wrapper')).to include_text('teacher')
          expect(f('#content')).not_to include_text(new_student_entry_text)
          add_reply new_student_entry_text
          expect(f('#content')).to include_text(new_student_entry_text)
        end

        it "should let students post to a post-first discussion", priority: "1", test_id: 150476 do
          new_student_entry_text = 'new student entry'
          topic.require_initial_post = true
          topic.save
          entry
          get url
          # shouldn't see the existing entry until after posting
          expect(f('#content')).not_to include_text("new entry from teacher")
          add_reply new_student_entry_text
          # now they should see the existing entry, and their entry
          entries = get_all_replies
          expect(entries.length).to eq 2
          expect(entries[0]).to include_text("teacher entry")
          expect(entries[1]).to include_text(new_student_entry_text)
        end
      end
    end

    context "as a teacher" do
      let(:topic) { teacher_topic }

      before(:each) do
        resize_screen_to_normal
        user_session(teacher)
        enable_all_rcs @course.account
      end

      it "should create a group discussion", priority: "1", test_id: 150473 do
        group
        get "/courses/#{course.id}/discussion_topics"
        expect_new_page_load{f('#add_discussion').click}
        f('#discussion-title').send_keys('New Discussion')
        type_in_tiny 'textarea[name=message]', 'Discussion topic message'
        f('#has_group_category').click
        drop_down = get_options('#assignment_group_category_id').map(&:text).map(&:strip)
        expect(drop_down).to include('category 1')
        click_option('#assignment_group_category_id', @category1.name)
        expect_new_page_load {submit_form('.form-actions')}
        expect(f('#discussion_container').text).to include("Since this is a group discussion,"\
                                                  " each group has its own conversation for this topic."\
                                                  " Here are the ones you have access to:\nsome group")
      end

      it "should create a graded discussion", priority: "1", test_id: 150477 do
        assignment_group
        get "/courses/#{course.id}/discussion_topics"
        expect_new_page_load{f('#add_discussion').click}
        f('#discussion-title').send_keys('New Discussion')
        type_in_tiny 'textarea[name=message]', 'Discussion topic message'
        expect(f('#availability_options')).to be_displayed
        f('#use_for_grading').click
        wait_for_ajaximations
        expect(f('#availability_options')).to_not be_displayed
        f('#discussion_topic_assignment_points_possible').send_keys('10')
        wait_for_ajaximations
        click_option('#assignment_group_id', assignment_group.name)
        expect_new_page_load {submit_form('.form-actions')}
        expect(f('#discussion_container').text).to include('This is a graded discussion: 10 points possible')
      end

      it "should show attachment", priority: "1", test_id: 150478 do
        get "/courses/#{course.id}/discussion_topics"
        expect_new_page_load{f('#add_discussion').click}
        filename, fullpath, _data = get_file("graded.png")
        f('#discussion-title').send_keys('New Discussion')
        f('input[name=attachment]').send_keys(fullpath)
        type_in_tiny('textarea[name=message]', 'file attachment discussion')
        expect_new_page_load {submit_form('.form-actions')}
        expect(f('.image').text).to include(filename)
      end

      it "should escape correctly when posting an attachment", priority: "2", test_id: 344538 do
        get url
        message = "message that needs escaping ' \" & !@#^&*()$%{}[];: blah"
        add_reply(message, 'graded.png')
        expect(@last_entry.find_element(:css, '.message').text).to eq message
      end

      context "in student view" do
        it "should allow student view student to read/post", priority:"2", test_id: 344545 do
          skip_if_chrome('Can not get to student view in Chrome')
          enter_student_view
          get url
          expect(f("#content")).not_to contain_css("#discussion_subentries .discussion_entry")
          add_reply
          expect(get_all_replies.count).to eq 1
        end
      end
    end

    it "should show only 10 root replies per page"
    it "should paginate root entries"
    it "should show only three levels deep"
    it "should show only three children of a parent"
    it "should display unrendered unread and total counts accurately"
    it "should expand descendents"
    it "should expand children"
    it "should deep link to an entry rendered on the first page"
    it "should deep link to an entry rendered on a different page"
    it "should deep link to a non-rendered child entry of a rendered parent"
    it "should deep link to a child entry of a non-rendered parent"
    it "should allow users to 'go to parent'"
    it "should collapse a thread"
    it "should filter entries by user display name search term"
    it "should filter entries by content search term"
    it "should filter entries by unread"
    it "should filter entries by unread and search term"
    it "should link to an entry in context of the discussion when clicked in result view"
  end
end
