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
require File.expand_path(File.dirname(__FILE__) + '/../../common')

describe "discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
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

  context "on the edit page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/edit" }

    context "as a teacher" do
      let(:topic) { teacher_topic }

      before(:each) do
        user_session(teacher)
        enable_all_rcs @course.account
        stub_rcs_config
      end

      context "graded" do
        let(:topic) { assignment_topic }

        it "should warn user when leaving page unsaved", priority: "1", test_id: 270919 do
          skip_if_safari(:alert)
          title = 'new title'
          get url

          replace_content(f('input[name=title]'), title)
          fln('Home').click

          expect(alert_present?).to be_truthy

          driver.switch_to.alert.dismiss
        end
      end

      context "with a group attached" do
        let(:graded_topic) { assignment_topic }
        before do
          @gc = GroupCategory.create(:name => "Sharks", :context => @course)
          @student = student_in_course(:course => @course, :active_all => true).user
          group = @course.groups.create!(:group_category => @gc)
          group.users << @student
        end

        it "group discussions with entries should lock and display the group name", priority: "1", test_id: 270920 do
          topic.group_category = @gc
          topic.save!
          topic.child_topics[0].reply_from({:user => @student, :text => "I feel pretty"})
          @gc.destroy
          get url

          expect(f("#assignment_group_category_id")).to be_disabled
          expect(get_value("#assignment_group_category_id")).to eq topic.group_category.id.to_s
        end

        it "should prompt for creating a new group category if original group is deleted with no submissions", priority: "1", test_id: 270921 do
          topic.group_category = @gc
          topic.save!
          @gc.destroy
          get url
          wait_for_ajaximations
          expect(f("#assignment_group_category_id")).not_to be_displayed
        end

        context "graded" do
          let(:topic) { assignment_topic }
          it "should lock and display the group name", priority: "1", test_id: 270922 do
            topic.group_category = @gc
            topic.save!
            topic.reply_from({:user => @student, :text => "I feel pretty"})
            @gc.destroy
            get url

            expect(f("#assignment_group_category_id")).to be_disabled
            expect(get_value("#assignment_group_category_id")).to eq topic.group_category.id.to_s
          end
        end
      end

      it "should save and display all changes", priority: "2", test_id: 270923 do
        course.require_assignment_group

        confirm(:off)
        toggle(:on)
        confirm(:on)
        toggle(:off)
        confirm(:off)
      end

      it "should show correct date when saving" do
        Timecop.freeze do
          topic.lock_at = Time.zone.now - 5.days
          topic.save!
          teacher.time_zone = "Hawaii"
          teacher.save!
          get url
          f('.form-actions button[type=submit]').click
          get url
          expect(topic.reload.lock_at).to eq (Time.zone.now - 5.days).beginning_of_minute
        end
      end

      it "should toggle checkboxes when clicking their labels", priority: "1", test_id: 270924 do
        get url

        expect(is_checked('input[type=checkbox][name=threaded]')).not_to be_truthy
        driver.execute_script(%{$('input[type=checkbox][name=threaded]').parent().click()})
        expect(is_checked('input[type=checkbox][name=threaded]')).to be_truthy
      end
    end
  end
end
