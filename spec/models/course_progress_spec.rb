#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CourseProgress do
  let(:progress_error) { {:error=>{:message=>'no progress available because this course is not module based (has modules and module completion requirements) or the user is not enrolled as a student in this course'}} }

  before do
    class CourseProgress
      def course_context_modules_item_redirect_url(opts = {})
        "course_context_modules_item_redirect_url(:course_id => #{opts[:course_id]}, :id => #{opts[:id]}, :host => HostUrl.context_host(Course.find(#{opts[:course_id]}))"
      end
    end
  end

  before(:each) do
    course_with_teacher(:active_all => true)
  end

  it "should return nil for non module_based courses" do
    user = student_in_course(:active_all => true)
    progress = CourseProgress.new(@course, user).to_json
    progress.should == progress_error
  end

  it "should return nil for non student users" do
    user = user_model
    @course.stubs(:module_based?).returns(true)
    progress = CourseProgress.new(@course, user).to_json
    progress.should == progress_error
  end

  context "module based and for student" do
    before do
      @module = @course.context_modules.create!(:name => "some module", :require_sequential_progress => true)
      @module2 = @course.context_modules.create!(:name => "another module", :require_sequential_progress => true)
      @module3 = @course.context_modules.create!(:name => "another module again", :require_sequential_progress => true)

      @assignment = @course.assignments.create!(:title => "some assignment")
      @assignment2 = @course.assignments.create!(:title => "some assignment2")
      @assignment3 = @course.assignments.create!(:title => "some assignment3")
      @assignment4 = @course.assignments.create!(:title => "some assignment4")
      @assignment5 = @course.assignments.create!(:title => "some assignment5")

      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @tag2 = @module.add_item({:id => @assignment2.id, :type => 'assignment'})

      @tag3 = @module2.add_item({:id => @assignment3.id, :type => 'assignment'})
      @tag4 = @module2.add_item({:id => @assignment4.id, :type => 'assignment'})

      @tag5 = @module3.add_item({:id => @assignment5.id, :type => 'assignment'})

      @module.completion_requirements = {@tag.id => {:type => 'must_submit'},
                                         @tag2.id => {:type => 'must_submit'}}
      @module2.completion_requirements = {@tag3.id => {:type => 'must_submit'},
                                          @tag4.id => {:type => 'must_submit'}}
      @module3.completion_requirements = {@tag5.id => {:type => 'must_submit'}}

      [@module, @module2, @module3].each do |m|
        m.require_sequential_progress = true
        m.publish
        m.save!
      end

      student_in_course(:active_all => true)
    end

    it "should return correct progress for newly enrolled student" do
      progress = CourseProgress.new(@course, @user).to_json
      progress.should == {
          requirement_count: 5,
          requirement_completed_count: 0,
          next_requirement_url: "course_context_modules_item_redirect_url(:course_id => #{@course.id}, :id => #{@tag.id}, :host => HostUrl.context_host(Course.find(#{@course.id}))",
          completed_at: nil
      }
    end

    it "should return correct progress for student who has completed some requirements" do
      # turn in first two assignments (module 1)
      @module.update_for(@user, :submitted, @tag)
      @module.update_for(@user, :submitted, @tag2)
      progress = CourseProgress.new(@course, @user).to_json
      progress.should == {
          requirement_count: 5,
          requirement_completed_count: 2,
          next_requirement_url: "course_context_modules_item_redirect_url(:course_id => #{@course.id}, :id => #{@tag3.id}, :host => HostUrl.context_host(Course.find(#{@course.id}))",
          completed_at: nil
      }
    end

    it "should return correct progress for student who has completed all requirements" do
      # turn in all assignments
      @module.update_for(@user, :submitted, @tag)
      @module.update_for(@user, :submitted, @tag2)
      @module2.update_for(@user, :submitted, @tag3)
      @module2.update_for(@user, :submitted, @tag4)
      @module3.update_for(@user, :submitted, @tag5)
      progress = CourseProgress.new(@course, @user).to_json
      progress.should == {
          requirement_count: 5,
          requirement_completed_count: 5,
          next_requirement_url: nil,
          completed_at: @module3.context_module_progressions.first.completed_at.iso8601
      }
    end

    it "treats a nil requirements_met as an incomplete requirement" do
      # create a progression with requirements_met uninitialized (nil)
      ContextModuleProgression.create!(user: @user, context_module: @module)
      progress = CourseProgress.new(@course, @user).to_json
      progress.should == {
          requirement_count: 5,
          requirement_completed_count: 0,
          next_requirement_url: "course_context_modules_item_redirect_url(:course_id => #{@course.id}, :id => #{@tag.id}, :host => HostUrl.context_host(Course.find(#{@course.id}))",
          completed_at: nil
      }
    end

    it "does not count obsolete requirements" do
      # turn in first two assignments
      @module.update_for(@user, :submitted, @tag)
      @module.update_for(@user, :submitted, @tag2)

      # remove assignment 2 from the list of requirements
      @module.completion_requirements = [{id: @tag.id, type: 'must_submit'}]
      @module.save

      progress = CourseProgress.new(@course, @user).to_json

      # assert that assignment 2 is no longer a requirement (5 -> 4)
      progress[:requirement_count].should == 4

      # assert that assignment 2 doesn't count toward the total (2 -> 1)
      progress[:requirement_completed_count].should == 1
    end
  end
end