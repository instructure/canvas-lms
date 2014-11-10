#
# Copyright (C) 2013 Instructure, Inc.
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
require 'lib/data_fixup/populate_submission_versions.rb'

describe DataFixup::PopulateSubmissionVersions do
  it "should not migrate a non-submission version" do
    wiki_page_model
    version = Version.create(:versionable => @page, :yaml => @page.attributes.to_yaml)
    expect{
      DataFixup::PopulateSubmissionVersions.run
    }.not_to change(SubmissionVersion, :count)
  end

  it "should not migrate a submission version already having a submission_version" do
    course_with_student
    submission = @user.submissions.create(:assignment => @course.assignments.create!)
    expect{
      DataFixup::PopulateSubmissionVersions.run
    }.not_to change(SubmissionVersion, :count)
  end

  it "should migrate all submission version rows without submission_versions" do
    n = 5
    course_with_student
    submission = @user.submissions.build(:assignment => @course.assignments.create!)
    submission.without_versioning{ submission.save! }
    expect(submission.versions.exists?).to be_falsey
    n.times { |x| Version.create(:versionable => submission, :yaml => submission.attributes.to_yaml) }
    expect{
      DataFixup::PopulateSubmissionVersions.run
    }.to change(SubmissionVersion, :count).by(n)
  end

  it "should skip submission version rows without a corresponding submission object" do
    course_with_student
    submission = @user.submissions.build(:assignment => @course.assignments.create!)
    submission.without_versioning{ submission.save! }
    Version.create(:versionable => submission, :yaml => submission.attributes.to_yaml)

    submission.reload
    expect(submission.versions.exists?).to be_truthy
    submission.delete

    expect{
      DataFixup::PopulateSubmissionVersions.run
    }.not_to change(SubmissionVersion, :count)
  end
end
