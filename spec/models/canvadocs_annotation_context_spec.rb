# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"

describe CanvadocsAnnotationContext do
  before(:once) do
    @course = course_model
    student = @course.enroll_student(User.create!).user
    assignment = assignment_model(course: @course)
    @sub = assignment.submissions.find_by(user: student)
    @att = attachment_model(context: student)
  end

  it "requires an attachment" do
    expect {
      CanvadocsAnnotationContext.create!(submission: @sub, attachment: nil, submission_attempt: 1)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "requires a submission" do
    expect {
      CanvadocsAnnotationContext.create!(submission: nil, attachment: @att, submission_attempt: 1)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "sets a root_account_id automatically" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect(annotation_context.root_account_id).to eq @course.root_account_id
  end

  it "does not allow setting the root_account_id to nil" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect { annotation_context.update!(root_account_id: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "sets a launch_id automatically" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect(annotation_context.launch_id).not_to be_nil
  end

  it "does not allow setting the launch_id to nil" do
    annotation_context = CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    expect { annotation_context.update!(launch_id: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "is unique for a combination of attachment_id, submission_attempt, and submission_id" do
    CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)

    expect {
      CanvadocsAnnotationContext.create!(submission: @sub, attachment: @att, submission_attempt: 1)
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
