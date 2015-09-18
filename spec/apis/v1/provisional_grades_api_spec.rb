#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

describe 'Provisional Grades API', type: :request do
  describe "copy_to_final_mark" do
    before(:once) do
      course_with_student :active_all => true
      ta_in_course :active_all => true
      @course.root_account.allow_feature! :moderated_grading
      @course.enable_feature! :moderated_grading
      @assignment = @course.assignments.create! submission_types: 'online_text_entry', moderated_grading: true
      @assignment.moderated_grading_selections.create! student: @student
      @submission = @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'hallo')
      @pg = @submission.find_or_create_provisional_grade! scorer: @ta, score: 80
      @submission.add_comment(:commenter => @ta, :comment => 'huttah!', :provisional => true)

      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/provisional_grades/#{@pg.id}/copy_to_final_mark"
      @params = { :controller => 'provisional_grades', :action => 'copy_to_final_mark',
                  :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.to_param,
                  :provisional_grade_id => @pg.to_param }
    end

    it "requires moderate_grades permission" do
      api_call_as_user @student, :post, @path, @params, {}, {}, { :expected_status => 401 }
    end

    it "fails if the student isn't in the moderation set" do
      @assignment.moderated_grading_selections.where(student_id: @student).delete_all
      json = api_call_as_user @teacher, :post, @path, @params, {}, {}, { :expected_status => 400 }
      expect(json['message']).to eq 'student not in moderation set'
    end

    it "fails if the mark is already final" do
      @pg.update_attributes(:final => true)
      json = api_call_as_user @teacher, :post, @path, @params, {}, {}, { :expected_status => 400 }
      expect(json['message']).to eq 'provisional grade is already final'
    end

    it "copies the selected provisional grade" do
      json = api_call_as_user @teacher, :post, @path, @params
      final_mark = ModeratedGrading::ProvisionalGrade.find(json['provisional_grade_id'])
      expect(final_mark.score).to eq 80
      expect(final_mark.scorer).to eq @teacher
      expect(final_mark.final).to eq true

      expect(json['score']).to eq 80
      expect(json['submission_comments'].first['comment']).to eq 'huttah!'
    end
  end
end