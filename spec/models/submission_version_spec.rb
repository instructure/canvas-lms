# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
    @user.submissions.find_by(assignment: @course.assignments.create!)
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

    it "sets the index record's root_account_id" do
      index = SubmissionVersion.index_version(@version)
      expect(index.root_account_id).to eq @course.root_account_id
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
        @version.update_attribute(:yaml, "--- \n- 1\n- 2\n--3")
      end

      it "should error on invalid yaml by default" do
        expect{
          SubmissionVersion.index_versions([@version])
        }.to raise_error(Psych::SyntaxError)
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

  it "should not create a SubmissionVersion when the Version doesn't save" do
    version = @submission.versions.build(yaml: {"assignment_id" => @submission.assignment_id}.to_yaml)
    expect(@submission.versions).to receive(:create).and_return(version)
    expect do
      @submission.with_versioning(explicit: true) do
        @submission.send(:simply_versioned_create_version)
      end
    end.not_to change(SubmissionVersion, :count)
  end

  it "should let you preload current_version in one query" do
    sub1 = unversioned_submission
    3.times { Version.create(:versionable => sub1, :yaml => sub1.attributes.to_yaml) }
    sub2 = unversioned_submission
    2.times { Version.create(:versionable => sub2, :yaml => sub2.attributes.to_yaml) }

    Version.preload_version_number([sub1, sub2])

    [sub1, sub2].each{|s| expect(s).to receive(:versions).never}

    expect(sub1.version_number).to eq 3
    expect(sub2.version_number).to eq 2
  end
end
