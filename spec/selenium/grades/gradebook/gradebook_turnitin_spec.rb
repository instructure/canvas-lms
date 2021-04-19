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

require_relative '../../helpers/gradebook_common'
require_relative '../pages/gradebook_page'

describe "Gradebook - turnitin" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  it "shows turnitin data when the New Gradebook Plagiarism Indicator feature flag is enabled" do
    @course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator)
    @first_assignment.update_attribute(:turnitin_enabled, true)
    s1 = @first_assignment.submit_homework(@student_1, submission_type: 'online_text_entry', body: 'asdf')
    s1.update_attribute :turnitin_data, {
      "submission_#{s1.id}": {
        similarity_score: 0.0,
        web_overlap: 0.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: 'none'
      }
    }
    a = attachment_model(context: @student_2, content_type: 'text/plain')
    s2 = @first_assignment.submit_homework(@student_2, submission_type: 'online_upload', attachments: [a])
    s2.update_attribute :turnitin_data, {
      "attachment_#{a.id}": {
        similarity_score: 1.0,
        web_overlap: 5.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: 'acceptable'
      }
    }

    Gradebook.visit(@course)
    icons = ff('.Grid__GradeCell__OriginalityScore')
    expect(icons).to have_size 2
  end

  it "shows turnitin data when the New Gradebook Plagiarism Indicator feature flag is not enabled" do
    @first_assignment.update_attribute(:turnitin_enabled, true)
    s1 = @first_assignment.submit_homework(@student_1, submission_type: 'online_text_entry', body: 'asdf')
    s1.update_attribute :turnitin_data, {
      "submission_#{s1.id}": {
        similarity_score: 0.0,
        web_overlap: 0.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: 'none'
      }
    }
    a = attachment_model(context: @student_2, content_type: 'text/plain')
    s2 = @first_assignment.submit_homework(@student_2, submission_type: 'online_upload', attachments: [a])
    s2.update_attribute :turnitin_data, {
      "attachment_#{a.id}": {
        similarity_score: 1.0,
        web_overlap: 5.0,
        publication_overlap: 0.0,
        student_overlap: 0.0,
        state: 'acceptable'
      }
    }

    Gradebook.visit(@course)
    icons = ff('.gradebook-cell-turnitin')
    expect(icons).to have_size 2
  end
end
