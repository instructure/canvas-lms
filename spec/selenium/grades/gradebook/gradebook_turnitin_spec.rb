# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook - turnitin" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
    gradebook_data_setup
  end

  before { user_session(@teacher) }

  it "shows turnitin data when the New Gradebook Plagiarism Indicator feature flag is enabled" do
    @course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator)
    @first_assignment.update_attribute(:turnitin_enabled, true)
    s1 = @first_assignment.submit_homework(@student_1, submission_type: "online_text_entry", body: "asdf")
    s1.update_attribute :turnitin_data, {
      "submission_#{s1.id}": {
        similarity_score: 0.0,
        web_overlap: 0.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: "none"
      }
    }
    a = attachment_model(context: @student_2, content_type: "text/plain")
    s2 = @first_assignment.submit_homework(@student_2, submission_type: "online_upload", attachments: [a])
    s2.update_attribute :turnitin_data, {
      "attachment_#{a.id}": {
        similarity_score: 1.0,
        web_overlap: 5.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: "acceptable"
      }
    }

    Gradebook.visit(@course)
    icons = ff(".Grid__GradeCell__OriginalityScore")
    expect(icons).to have_size 2
  end

  it "shows turnitin data when the New Gradebook Plagiarism Indicator feature flag is not enabled" do
    @first_assignment.update_attribute(:turnitin_enabled, true)
    s1 = @first_assignment.submit_homework(@student_1, submission_type: "online_text_entry", body: "asdf")
    s1.update_attribute :turnitin_data, {
      "submission_#{s1.id}": {
        similarity_score: 0.0,
        web_overlap: 0.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: "none"
      }
    }
    a = attachment_model(context: @student_2, content_type: "text/plain")
    s2 = @first_assignment.submit_homework(@student_2, submission_type: "online_upload", attachments: [a])
    s2.update_attribute :turnitin_data, {
      "attachment_#{a.id}": {
        similarity_score: 1.0,
        web_overlap: 5.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: "acceptable"
      }
    }

    Gradebook.visit(@course)
    icons = ff(".gradebook-cell-turnitin")
    expect(icons).to have_size 2
  end
end

describe "Gradebook - turnitin" do
  it_behaves_like "Gradebook - turnitin", true
  it_behaves_like "Gradebook - turnitin", false
end
