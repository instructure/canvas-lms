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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'csv'

describe GradebookUploadsController do
  def course_with_graded_student
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user, :grade => "10")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @assignment2.grade_student(@user, :grade => "8")
    @course.recompute_student_scores
    @user.reload
    @course.reload
  end

  def check_create_response(include_sis_id=false)
    file = Tempfile.new("csv.csv")
    file.puts(@course.gradebook_to_csv(:include_sis_id => include_sis_id))
    file.close
    data = Rack::Test::UploadedFile.new(file.path, 'text/csv', true)
    post 'create', :course_id => @course.id, :gradebook_upload => {:uploaded_data => data}
    expect(response).to be_success
    upload = assigns[:uploaded_gradebook]
    expect(upload).not_to be_nil
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
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it "should redirect on failed csvs" do
      user_session(@teacher)
      file = Tempfile.new("csv.csv")
      file.puts("not a good csv")
      file.close
      data = Rack::Test::UploadedFile.new(file.path, 'text/csv', true)
      post 'create', :course_id => @course.id, :gradebook_upload => {:uploaded_data => data}
      expect(response).to be_redirect
    end

    it "should accept a valid csv upload" do
      user_session(@teacher)
      check_create_response
    end

    it "should accept a valid csv upload with a final grade column" do
      user_session(@teacher)
      @course.grading_standard_id = 0
      @course.save!
      check_create_response
    end

    it "should accept a valid csv upload with sis id columns" do
      user_session(@teacher)
      @course.grading_standard_id = 0
      @course.save!
      check_create_response(true)
    end
  end

  describe "POST 'update'" do
    before :each do
      user_session(@teacher)
    end

    it "should update grades and save new versions" do
      @assignment.reload
      @assignment2.reload
      expect(@assignment.submissions.first.grade).to eq '10'
      expect(@assignment2.submissions.first.grade).to eq '8'

      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Some Assignment", "Some Assignment 2"]
        csv << ["    Points Possible", "", "","", ""]
        csv << ["" , @student.id.to_s, "", "", "", 5, 7]
      end

      @gi = GradebookImporter.new(@course, uploaded_csv)
      @gi.parse!
      post 'update', :course_id => @course.id, :json_data_to_submit => @gi.to_json

      a_sub = @assignment.reload.submissions.first
      a2_sub = @assignment2.reload.submissions.first
      expect(a_sub.grade).to eq '5'
      expect(a_sub.graded_at).not_to be_nil
      expect(a_sub.grader_id).not_to be_nil
      expect(a_sub.version_number).to eq 2
      expect(a2_sub.grade).to eq '7'
      expect(a2_sub.graded_at).not_to be_nil
      expect(a2_sub.grader_id).not_to be_nil
      expect(a2_sub.version_number).to eq 2

      expect(response).to redirect_to(course_gradebook_url(@course))
    end

    it "should create new assignments" do
      uploaded_csv = CSV.generate do |csv|
        csv << ["Student", "ID", "SIS User ID", "SIS Login ID", "Section", "Some Assignment", "Some Assignment 2", "Third Assignment"]
        csv << ["    Points Possible", "", "","", "", "", "", "15"]
        csv << ["" , @student.id.to_s, "", "", "", 5, 7, 10]
      end

      @gi = GradebookImporter.new(@course, uploaded_csv)
      @gi.parse!
      post 'update', :course_id => @course.id, :json_data_to_submit => @gi.to_json

      a = @course.assignments.where(title: "Third Assignment").first
      expect(a).not_to be_nil
      expect(a.title).to eq "Third Assignment"
      expect(a.points_possible).to eq 15
      expect(a.submissions.first.grade).to eq '10'
    end

    it "should allow entering a percentage for a score" do
      @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :grading_type => 'percent', :assignment_group => @group)
      uploaded_json = <<-JSON
      {
        "students": [{
          "previous_id": #{@student.id},
          "name": "#{@student.name}",
          "submissions": [{
            "grade": "40%",
            "assignment_id": #{@assignment.id}
          }],
          "id": #{@student.id},
          "last_name_first": "#{@student.last_name_first}"
        }],
        "assignments": [{
          "previous_id": #{@assignment.id},
          "title": "#{@assignment.title}",
          "id": #{@assignment.id},
          "points_possible": #{@assignment.points_possible},
          "grading_type": "#{@assignment.grading_type}"
        }]
      }
      JSON
      post 'update', :course_id => @course.id, :json_data_to_submit => uploaded_json
      @submission = @assignment.reload.submissions.where(user_id: @student).first
      expect(@submission.grade).to eq "40%"
      expect(@submission.score).to eq 4
    end

    context "differentiated assignments" do
      before :once do
        @course.enable_feature!(:differentiated_assignments)
        setup_DA
        @assignment.grade_student(@student1, :grade => "3")
        @assignment2.grade_student(@student2, :grade => "3")
      end

      it "should ignore assignments not visible to a student" do
        uploaded_json = <<-JSON
        {
          "students": [{
            "previous_id": #{@student1.id},
            "name": "#{@student1.name}",
            "submissions": [{
              "grade": "7",
              "assignment_id": #{@assignment.id}
            }, {
              "grade": "9",
              "assignment_id": #{@assignment2.id}
            }],
            "id": #{@student1.id},
            "last_name_first": "#{@student1.last_name_first}"
          }, {
            "previous_id": #{@student2.id},
            "name": "#{@student2.name}",
            "submissions": [{
              "grade": "7",
              "assignment_id": #{@assignment.id}
            }, {
              "grade": "9",
              "assignment_id": #{@assignment2.id}
            }],
            "id": #{@student2.id},
            "last_name_first": "#{@student2.last_name_first}"
          }],
          "assignments": [{
            "previous_id": #{@assignment.id},
            "title": "#{@assignment.title}",
            "id": #{@assignment.id},
            "points_possible": #{@assignment.points_possible},
            "grading_type": "#{@assignment.grading_type}"
          }, {
            "previous_id": #{@assignment2.id},
            "title": "#{@assignment2.title}",
            "id": #{@assignment2.id},
            "points_possible": #{@assignment2.points_possible},
            "grading_type": "#{@assignment2.grading_type}"
          }]
        }
        JSON
        post 'update', :course_id => @course.id, :json_data_to_submit => uploaded_json

        a1_sub1 = @assignment.reload.submissions.where(user_id: @student1).first
        a1_sub2 = @assignment.reload.submissions.where(user_id: @student2).first
        expect(a1_sub1.grade).to eq '7'
        expect(a1_sub2).to eq nil
        a2_sub1 = @assignment2.reload.submissions.where(user_id: @student1).first
        a2_sub2 = @assignment2.reload.submissions.where(user_id: @student2).first
        expect(a2_sub1).to eq nil
        expect(a2_sub2.grade).to eq '9'
      end
    end
  end
end
