#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'csv'

describe GradebookUploadsController do
  def course_with_graded_student
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user, grade: "10", grader: @teacher)
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @assignment2.grade_student(@user, grade: "8", grader: @teacher)
    @course.recompute_student_scores
    @user.reload
    @course.reload
  end

  def generate_file(include_sis_id=false)
    file = Tempfile.new("csv.csv")
    file.puts(GradebookExporter.new(@course, @teacher, :include_sis_id => include_sis_id).to_csv)
    file.close
    file
  end

  def upload_gradebook_import(course, file)
    data = Rack::Test::UploadedFile.new(file.path, 'text/csv', true)
    post 'create', params: {course_id: course.id, gradebook_upload: {uploaded_data: data}}
  end

  def check_create_response(include_sis_id=false)
    file = generate_file(include_sis_id)
    upload_gradebook_import(@course, file)
    expect(response).to be_successful
  end

  def setup_DA
    @course_section = @course.course_sections.create
    @student1, @student2, @student3 = create_users(3, return_type: :record)
    @assignment.only_visible_to_overrides = true
    @assignment.save
    @course.enroll_student(@student3, :enrollment_state => 'active')
    @section = @course.course_sections.create!(name: "test section")
    @section2 = @course.course_sections.create!(name: "second test section")
    student_in_section(@section, user: @student1)
    student_in_section(@section2, user: @student2)
    create_section_override_for_assignment(@assignment, {course_section: @section})
    @assignment2.only_visible_to_overrides = true
    @assignment2.save
    create_section_override_for_assignment(@assignment2, {course_section: @section2})
    @course.reload
    @assignment.reload
    @assignment2.reload
  end

  before :once do
    course_with_teacher active_all: true
    student_in_course active_all: true
    course_with_graded_student
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', params: {:course_id => @course.id}
      assert_unauthorized
    end

    context "with authorized teacher" do
      before(:each) { user_session(@teacher) }

      it "should accept a valid csv upload" do
        check_create_response
      end

      it "puts the uploaded data into a durable attachment so it's recoverable" do
        gradebook_import_file = generate_file
        upload_gradebook_import(@course, gradebook_import_file)
        attachment = Attachment.last
        expect(gradebook_import_file.path).to include(attachment.filename)
      end

      context "and final grade column" do
        before(:each) do
          @course.grading_standard_id = 0
          @course.save!
        end

        it "should accept a valid csv upload with a final grade column" do
          check_create_response
        end

        it "should accept a valid csv upload with sis id columns" do
          check_create_response(true)
        end
      end
    end
  end

  describe "GET 'data'" do
    it "requires authorization" do
      get 'data', params: {course_id: @course.id}
      assert_unauthorized
    end

    it "retrieves an uploaded gradebook" do
      user_session(@teacher)
      progress = Progress.create!(tag: "test", context: @teacher)

      @gb_upload = GradebookUpload.new course: @course, user: @teacher, progress: progress, gradebook: {foo: 'bar'}
      @gb_upload.save

      get 'data', params: {course_id: @course.id}
      expect(response).to be_successful
      expect(response.body).to eq("while(1);{\"foo\":\"bar\"}")
    end

    it "destroys an uploaded gradebook after retrieval" do
      user_session(@teacher)
      progress = Progress.create!(tag: "test", context: @teacher)
      @gb_upload = GradebookUpload.new course: @course, user: @teacher, progress: progress, gradebook: {foo: 'bar'}
      @gb_upload.save
      get 'data', params: {course_id: @course.id}
      expect { GradebookUpload.find(@gb_upload.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to be_successful
    end
  end
end
