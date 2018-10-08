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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PlannerApiHelper do
  include PlannerApiHelper

  describe "#formatted_planner_date" do
    it 'should create errors for bad dates' do
      expect {formatted_planner_date('start_date', '123-456-789')}.to raise_error(PlannerApiHelper::InvalidDates)
      expect {formatted_planner_date('end_date', '9876-5-4321')}.to raise_error(PlannerApiHelper::InvalidDates)
    end
  end

  context "mark-done and planner-complete synchronization" do
    before(:once) do
      student_in_course(active_all: true)
      @module1 = @course.context_modules.create!(:name => "module1")
      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
      @assignment.publish
      @wiki_page = @course.wiki_pages.create!(:title => "my page")
      @wiki_page.publish

      # add assignment as a completion requirement in one module
      @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
      @wiki_page_tag = @module1.add_item(:id => @wiki_page.id, :type => 'wiki_page')
      @module1.completion_requirements = {
        @assignment_tag.id => { :type => 'must_mark_done' },
        @wiki_page_tag.id => { :type => 'must_mark_done' }
      }
      @module1.save!
    end

    describe "#sync_module_requirement_done" do
        it "sets module requirement as done when completed in planner for assignment" do
          planner_override_model({"plannable": @assignment, "marked_complete": true})
          sync_module_requirement_done(@assignment, @user, true)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@assignment_tag)).to eq true
        end

        it "sets module requirement as not done when un-completed in planner for assignment" do
          @assignment_tag.context_module_action(@user, :done)
          planner_override_model({"plannable": @assignment, "marked_complete": false})
          sync_module_requirement_done(@assignment, @user, false)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@assignment_tag)).to eq false
        end

        it "sets module requirement as done when completed in planner for wiki page" do
          planner_override_model({"plannable": @wiki_page, "marked_complete": true})
          sync_module_requirement_done(@wiki_page, @user, true)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@wiki_page_tag)).to eq true
        end

        it "sets module requirement as not done when un-completed in planner for wiki page" do
          @wiki_page_tag.context_module_action(@user, :done)
          planner_override_model({"plannable": @wiki_page, "marked_complete": false})
          sync_module_requirement_done(@wiki_page, @user, false)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@wiki_page_tag)).to eq false
        end

        it "catches error if tried on non-module object types" do
          expect { sync_module_requirement_done(@user, @user, true) }.not_to raise_error
        end
    end

    describe "#sync_planner_completion" do
      it "updates existing override for assignment" do
        planner_override_model({"plannable": @assignment,
                                "marked_complete": false,
                                "dismissed": false})

        override = sync_planner_completion(@assignment, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true

        override = sync_planner_completion(@assignment, @user, false)
        expect(override.marked_complete).to eq false
        expect(override.dismissed).to eq false
      end

      it "creates new override if none exists for assignment" do
        override = sync_planner_completion(@assignment, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true
      end

      it "updates existing override for wiki page" do
        planner_override_model({"plannable": @wiki_page,
                                "marked_complete": false,
                                "dismissed": false})

        override = sync_planner_completion(@wiki_page, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true

        override = sync_planner_completion(@wiki_page, @user, false)
        expect(override.marked_complete).to eq false
        expect(override.dismissed).to eq false
      end

      it "creates new override if none exists for wiki page" do
        override = sync_planner_completion(@wiki_page, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true
      end

      it "does not throw error if tried on object type not valid for override" do
        expect { sync_planner_completion(@user, @user, true) }.not_to raise_error
      end

      it "does nothing if mark-doneable in zero modules" do
        @module1.completion_requirements = {}
        @module1.save!
        override = sync_planner_completion(@assignment, @user, true)
        expect(override).to eq nil
      end

      it "does nothing if mark-doneable in multiple modules" do
        @module2 = @course.context_modules.create!(:name => "module1")
        @assignment_tag2 = @module2.add_item(:id => @assignment.id, :type => 'assignment')
        @module2.completion_requirements = {
          @assignment_tag2.id => { :type => 'must_mark_done' }
        }
        @module2.save!
        override = sync_planner_completion(@assignment, @user, true)
        expect(override).to eq nil
      end
    end
  end
end
