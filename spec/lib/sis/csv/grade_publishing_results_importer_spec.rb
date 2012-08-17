#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::CSV::GradePublishingResultsImporter do

  before { account_model }

  it 'should skip bad content' do
    importer = process_csv_data(
      "enrollment_id,grade_publishing_status",
      ",published",
      "1,published",
      "2,asplode")

    importer.errors.should == []
    warnings = importer.warnings.map { |r| r.last }
    warnings.should == ["No enrollment_id given",
                      "Enrollment 1 doesn't exist",
                      "Improper grade_publishing_status \"asplode\" for enrollment 2"]
  end

  it 'should properly update the db' do
    course_with_student
    @course.account = @account
    @course.save!

    @enrollment.grade_publishing_status = 'publishing'
    @enrollment.save!

    process_csv_data_cleanly(
      "enrollment_id,grade_publishing_status",
      "#{@enrollment.id},published")

    @enrollment.reload
    @enrollment.grade_publishing_status.should == 'published'
  end

  it 'should properly pass in messages' do
    course_with_student
    @course.account = @account
    @course.save!

    @enrollment.grade_publishing_status = 'publishing'
    @enrollment.save!

    @course.reload.grade_publishing_statuses[1].should == "publishing"

    process_csv_data_cleanly(
      "enrollment_id,grade_publishing_status,message",
      "#{@enrollment.id},published,message1")

    statuses = @course.reload.grade_publishing_statuses
    statuses[1].should == "published"
    statuses[0].should == { "Published: message1" => [@enrollment] }

    @enrollment.reload
    @enrollment.grade_publishing_status.should == 'published'
  end

  it 'should give a proper error if you try to reference an enrollment from another root account' do
    account = Account.create!
    course_with_student(:account => account)

    importer = process_csv_data(
      "enrollment_id,grade_publishing_status,message",
      "#{@enrollment.id},published,message1")
    importer.errors.should == []
    warnings = importer.warnings.map { |r| r.last }
    warnings.should == ["Enrollment #{@enrollment.id} doesn't exist"]
  end
end
