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
      lambda{
        SubmissionVersion.index_version(@version)
      }.should change(SubmissionVersion, :count)
    end

    it "should set the index record's version_id" do
      index = SubmissionVersion.index_version(@version)
      index.version_id.should == @version.id
    end

    it "should set the index record's context" do
      index = SubmissionVersion.index_version(@version)
      index.context_type.should == 'Course'
      index.context_id.should == @course.id
    end

    it "should set the index record's user_id" do
      index = SubmissionVersion.index_version(@version)
      index.user_id.should == @submission.user_id
    end

    it "should set the index record's assignment_id" do
      index = SubmissionVersion.index_version(@version)
      index.assignment_id.should == @submission.assignment_id
    end
  end

  describe "index_versions" do
    it "should create a new record for each version" do
      n = 5

      submissions = n.times.map{ unversioned_submission }
      contexts = submissions.map{ |submission| submission.assignment.context }
      versions = submissions.map{ |submission| Version.create(:versionable => submission, :yaml => submission.attributes.to_yaml) }

      lambda{
        SubmissionVersion.index_versions(versions)
      }.should change(SubmissionVersion, :count).by(n)
    end
  end

  it "should skip submissions with no assignment" do
    attrs = YAML.load(@version.yaml)
    attrs.delete('assignment_id')
    @version.update_attribute(:yaml, attrs.to_yaml)
    lambda{
      SubmissionVersion.index_version(@version)
      SubmissionVersion.index_versions([@version])
    }.should_not change(SubmissionVersion, :count)
  end
end
