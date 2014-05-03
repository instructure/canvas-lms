#
# Copyright (C) 2014 Instructure, Inc.
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

describe ContextModuleProgression do
  describe "prerequisites_satisfied?" do
    before do
      @course = course(:active_all => true)
      @module = @course.context_modules.create!(:name => "some module")

      @assignment = @course.assignments.create!(:title => "some assignment")
      @tag = @module.add_item({:id => @assignment.id, :type => 'assignment'})
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
      @module.workflow_state = 'unpublished'
      @module.save!

      @module2 = @course.context_modules.create!(:name => "another module")
      @module2.publish
      @module2.prerequisites = "module_#{@module.id}"
      @module2.save!

      @module3 = @course.context_modules.create!(:name => "another module again")
      @module3.publish
      @module3.save!

      @user = User.create!(:name => "some name")
      @course.enroll_student(@user)
    end

    it "should correctly ignore already-calculated context_module_prerequisites" do
      mp = @user.context_module_progressions.create!(:context_module => @module2)
      mp.workflow_state = 'locked'
      mp.save!
      mp2 = @user.context_module_progressions.create!(:context_module => @module)
      mp2.workflow_state = 'locked'
      mp2.save!

      ContextModuleProgression.prerequisites_satisfied?(@user, @module2).should == true
    end

    it "should be satisfied if no prereqs" do
      ContextModuleProgression.prerequisites_satisfied?(@user, @module3).should == true
    end

    it "should be satisfied if prereq is unpublished" do
      ContextModuleProgression.prerequisites_satisfied?(@user, @module2).should == true
    end

    it "should be satisfied if prereq's prereq is unpublished" do
      @module3.prerequisites = "module_#{@module2.id}"
      @module3.save!
      ContextModuleProgression.prerequisites_satisfied?(@user, @module3).should == true
    end

    it "should be satisfied if dependant on both a published and unpublished module" do
      @module3.prerequisites = "module_#{@module.id}"
      @module3.prerequisites = [{:type=>"context_module", :id=>@module.id, :name=>@module.name}, {:type=>"context_module", :id=>@module2.id, :name=>@module2.name}]
      @module3.save!
      @module3.reload
      @module3.prerequisites.count.should == 2

      ContextModuleProgression.prerequisites_satisfied?(@user, @module3).should == true
    end

    it "should skip incorrect prereq hashes" do
      @module3.prerequisites = [{:type=>"context_module", :id=>@module.id},
                                {:type=>"not_context_module", :id=>@module2.id, :name=>@module2.name}]
      @module3.save!

      @module3.prerequisites.count.should == 0
    end

    it "should update when publishing or unpublishing" do
      @module.publish
      ContextModuleProgression.prerequisites_satisfied?(@user, @module2).should == false
      @module.unpublish
      ContextModuleProgression.prerequisites_satisfied?(@user, @module2).should == true
    end
  end
end
