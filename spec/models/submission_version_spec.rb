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

describe SubmissionVersion do
  def unversioned_submission
    # bypass the built-in submission versioning
    course_with_student
    submission = @user.submissions.build(:assignment => @course.assignments.create!)
    submission.without_versioning{ submission.save! }
    submission
  end

  before do
    @submission = unversioned_submission
    @version = Version.create(:versionable => @submission, :yaml => @submission.attributes.to_yaml)
  end

  describe "index_version" do
    it "should create a new record" do
      expect{
        SubmissionVersion.index_version(@version)
      }.to change(SubmissionVersion, :count)
    end

    it "should set the index record's version_id" do
      index = SubmissionVersion.index_version(@version)
      expect(index.version_id).to eq @version.id
    end

    it "should set the index record's context" do
      index = SubmissionVersion.index_version(@version)
      expect(index.context_type).to eq 'Course'
      expect(index.context_id).to eq @course.id
    end

    it "should set the index record's user_id" do
      index = SubmissionVersion.index_version(@version)
      expect(index.user_id).to eq @submission.user_id
    end

    it "should set the index record's assignment_id" do
      index = SubmissionVersion.index_version(@version)
      expect(index.assignment_id).to eq @submission.assignment_id
    end
  end

  describe "index_versions" do
    it "should create a new record for each version" do
      n = 5

      submissions = n.times.map{ unversioned_submission }
      contexts = submissions.map{ |submission| submission.assignment.context }
      versions = submissions.map{ |submission| Version.create(:versionable => submission, :yaml => submission.attributes.to_yaml) }

      expect{
        SubmissionVersion.index_versions(versions)
      }.to change(SubmissionVersion, :count).by(n)
    end

    context "invalid yaml" do
      before do
        @version.update_attribute(:yaml, "--- \n- 1\n- 2\n-")
      end

      it "should error on invalid yaml by default" do
        expect{
          SubmissionVersion.index_versions([@version])
        }.to raise_error
      end

      it "should allow ignoring invalid yaml errors" do
        expect{
          SubmissionVersion.index_versions([@version], ignore_errors: true)
        }.not_to raise_error
      end
    end
  end

  it "should skip submissions with no assignment" do
    attrs = YAML.load(@version.yaml)
    attrs.delete('assignment_id')
    @version.update_attribute(:yaml, attrs.to_yaml)
    expect{
      SubmissionVersion.index_version(@version)
      SubmissionVersion.index_versions([@version])
    }.not_to change(SubmissionVersion, :count)
  end
end
