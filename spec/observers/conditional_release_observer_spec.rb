#
# Copyright (C) 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConditionalReleaseObserver do
  before :once do
    course.offer!

    @module = @course.context_modules.create!(:name => "cyoe module")
    @assignment = @course.assignments.create!(:name => "cyoe asgn", :submission_types => ["online_text_entry"], :points_possible => 100)
    @assignment.publish! if @assignment.unpublished?
    @assignment_tag = @module.add_item(:id => @assignment.id, :type => 'assignment')
  end

  describe "submission" do
    it "clears cache on create" do
      ConditionalRelease::Service.expects(:clear_submissions_cache_for).at_least(1)
      ConditionalRelease::Service.expects(:clear_rules_cache_for).at_least(1)
      submission_model(assignment: @assignment)
    end

    it "clears cache on update" do
      ConditionalRelease::Service.expects(:clear_submissions_cache_for).at_least(2)
      ConditionalRelease::Service.expects(:clear_rules_cache_for).at_least(2)
      submission_model(assignment: @assignment)
      @submission.body = "yas"
      @submission.save
    end

    it "clears cache on delete" do
      ConditionalRelease::Service.expects(:clear_submissions_cache_for).at_least(2)
      ConditionalRelease::Service.expects(:clear_rules_cache_for).at_least(2)
      submission_model(assignment: @assignment)
      @submission.destroy
    end
  end

  describe "assignment" do
    it "clears cache on create" do
      ConditionalRelease::Service.expects(:clear_active_rules_cache).at_least(1)
      ConditionalRelease::Service.expects(:clear_applied_rules_cache).at_least(1)
      assignment_model
    end

    it "clears cache on update" do
      ConditionalRelease::Service.expects(:clear_active_rules_cache).at_least(1)
      ConditionalRelease::Service.expects(:clear_applied_rules_cache).at_least(1)
      @assignment.name = "different name"
      @assignment.save!
    end

    it "clears cache on delete" do
      ConditionalRelease::Service.expects(:clear_active_rules_cache).at_least(1)
      ConditionalRelease::Service.expects(:clear_applied_rules_cache).at_least(1)
      @assignment.destroy
    end
  end
end
