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

shared_examples_for "submittable" do
  describe "#update_assignment" do
    context "with course paces" do
      before do
        @course = course_factory(active_course: true)
        @item_without_assignment = submittable_without_assignment
        @item_with_assignment, @assignment = submittable_and_assignment

        @course.root_account.enable_feature!(:course_paces)
        @course.enable_course_paces = true
        @course.save!
        @course_pace = course_pace_model(course: @course)
        @module = @course.context_modules.create!(name: "some module")
        @module.add_item(type: @item_without_assignment.model_name.param_key, id: @item_without_assignment.id)
        @module.add_item(type: @item_with_assignment.model_name.param_key, id: @item_with_assignment.id)
        @module.save!
        # #update_assignment is only called if conditional_release is enabled
        if submittable_class == WikiPage
          @course.conditional_release = true
          @course.save!
        end
        # Reset progresses to verify progresses are added during tests
        Progress.destroy_all
      end

      it "runs update_course_pace_module_items on content tags when an assignment is created" do
        expect(Progress.last).to be_nil
        @item_without_assignment.update(assignment: @course.assignments.create!)
        expect(Progress.last.context).to eq(@course_pace)
      end

      it "runs update_course_pace_module_items on content tags when an assignment is removed" do
        expect(Progress.last).to be_nil
        @item_with_assignment.update(assignment: nil)
        expect(Progress.last.context).to eq(@course_pace)
      end
    end
  end
end

describe DiscussionTopic do
  let(:submittable_class) { DiscussionTopic }

  include_examples "submittable" do
    def submittable_without_assignment
      discussion_topic_model(user: @teacher)
    end

    def submittable_and_assignment(opts = {})
      assignment = @course.assignments.create!({
        title: "some discussion assignment",
        submission_types: "discussion_topic"
      }.merge(opts))
      [assignment.discussion_topic, assignment]
    end
  end
end

describe WikiPage do
  let(:submittable_class) { WikiPage }

  include_examples "submittable" do
    def submittable_without_assignment
      wiki_page_model(course: @course)
    end

    def submittable_and_assignment(opts = {})
      assignment = @course.assignments.create!({
        title: "glorious page assignment",
        submission_types: "wiki_page"
      }.merge(opts))
      page = submittable_without_assignment
      page.assignment_id = assignment.id
      page.save!
      [page, assignment]
    end
  end
end
