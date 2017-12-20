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

require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:new_section) { course.course_sections.create!(name: "section 2") }
  let(:section_student) do
    student_in_course(course: course,
                      section: new_section,
                      name: 'section 2 student',
                      active_all: true).user
  end
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:student_topic) { course.discussion_topics.create!(user: student, title: 'student topic title', message: 'student topic message') }
  let(:teacher_topic) { course.discussion_topics.create!(user: teacher, title: 'teacher topic title', message: 'teacher topic message') }
  let(:assignment_group) { course.assignment_groups.create!(name: 'assignment group') }
  let(:group_category) { course.group_categories.create!(name: 'group category') }
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

  context "on the index page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/" }

    context "as a student" do
      let(:topic) {student_topic}

      before(:each) do
        user_session(student)
      end

      it "should allow a student to create a discussion", priority: "1", test_id: 270941 do
        get url
        expect_new_page_load { f('#new-discussion-btn').click }
        edit_topic("from a student", "tell me a story")
      end

      it "should not allow students to create discussions according to setting", priority: "1", test_id: 270942 do
        course.allow_student_discussion_topics = false
        course.save!
        get url
        expect(f("#content")).not_to contain_css('#new-discussion-btn')
      end

      it "should not not be able to publish/unpublish discussions", priority: "1", test_id: 150508 do
        @course.discussion_topics.create!(user: teacher, title: 'Philip J. Fry', message: 'teacher topic message')
        get url
        expect(f("#content")).not_to contain_css('.icon-unpublished')
      end

      describe "gear menu" do
        it "should allow the student user who created the topic to delete/lock a topic", priority: "1", test_id: 270943 do
          student_topic
          check_permissions
        end

        it "should not allow a student to pin a topic, even if they are the author", priority: "1", test_id: 270943 do
          student_topic
          get(url)
          fj("[data-id=#{topic.id}] .al-trigger").click
          expect(f("#content")).not_to contain_jqcss('.icon-pin:visible')
        end

        it "should not allow a student to delete/edit topics if they didn't create any", priority: "1", test_id: 270944 do
          teacher_topic
          check_permissions(0)
        end

        it "should not allow a student to delete/edit topics if allow_student_discussion_editing = false", priority: "2", test_id: 270945 do
          course.update_attributes(:allow_student_discussion_editing => false)
          student_topic
          check_permissions(0)
        end

        it "should bucket topics based on section-specific locks", priority: "2", test_id: 270946 do
          assignment_topic.assignment.assignment_overrides.create! { |override|
            override.set = new_section
            override.lock_at = 1.day.ago
            override.lock_at_overridden = true
          }

          user_session(section_student)
          get url
          expect(f('#locked-discussions .collectionViewItems .discussion')).not_to be_nil
        end
      end

      describe "subscription icon" do
        it "should not allow subscribing to a topic that requires an initial post", priority: "1", test_id: 270947 do
          teacher_topic.unsubscribe(student)
          teacher_topic.require_initial_post = true
          teacher_topic.save!
          get url
          wait_for_subscription_icon_to_load("icon-discussion")
          expect(f('.icon-discussion')).to be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          expect(f("#content")).not_to contain_css('.icon-discussion-check')
          expect(f('.icon-discussion')).to be_displayed
          teacher_topic.reload
          expect(teacher_topic.subscribed?(student)).to be_falsey
        end

        it "should allow subscribing after an initial post", priority: "1", test_id: 270948 do
          teacher_topic.require_initial_post = true
          teacher_topic.save!
          teacher_topic.reply_from(:user => student, :text => 'initial post')
          teacher_topic.unsubscribe(student)
          get url
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          wait_for_subscription_icon_to_load("icon-discussion")
          expect(f('.icon-discussion')).to be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          wait_for_subscription_icon_to_load("icon-discussion-check")
          expect(f('.icon-discussion-check')).to be_displayed
          expect(teacher_topic.reload.subscribed?(student)).to be_truthy
        end

        it "should display subscription action icons on hover", priority: "1", test_id: 270949 do
          teacher_topic.subscribe(student)
          get url
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          wait_for_subscription_icon_to_load("icon-discussion-check")
          expect(f('.icon-discussion-check')).to be_displayed
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseenter')})
          expect(f("#content")).not_to contain_css('.icon-discussion-check')
          expect(f('.icon-discussion-x')).to be_displayed
          f('.subscription-toggler').click
          wait_for_ajaximations
          wait_for_subscription_icon_to_load("icon-discussion")
          expect(f("#content")).not_to contain_css('.icon-discussion-x')
          expect(f('.icon-discussion')).to be_displayed
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseleave')})
          expect(f('.icon-discussion')).to be_displayed
          teacher_topic.reload
          teacher_topic.require_initial_post = true
          teacher_topic.save!
          get url
          wait_for_ajaximations
          driver.execute_script(%{$('.subscription-toggler').trigger('mouseenter')})
          expect(f("#content")).not_to contain_css('.icon-discussion')
          expect(f('.icon-discussion-x')).to be_displayed
        end
      end
    end
  end
end
