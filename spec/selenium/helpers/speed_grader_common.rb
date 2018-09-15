#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require_relative "../grades/pages/speedgrader_page"

module SpeedGraderCommon

  def student_submission(options = {})
    submission_model({:assignment => @assignment, :body => "first student submission text"}.merge(options))
  end

  def goto_section(section_id)
    f("#combo_box_container .ui-selectmenu-icon").click
    driver.execute_script("$('#section-menu-link').trigger('mouseenter')")
    f("#section-menu .section_#{section_id}").click
    wait_for_ajaximations
  end

  def goto_student(student_name)
    f("#combo_box_container .ui-selectmenu-icon").click
    student_selection = ff(".ui-selectmenu-item-header").find do |option|
      option.text.strip == student_name if option.text
    end
    raise ArgumentError, "There is no student named #{student_name}" unless student_selection
    student_selection.click
  end

  def set_turnitin_asset(asset, asset_data)
    @submission.turnitin_data ||= {}
    @submission.turnitin_data[asset.asset_string] = asset_data
    @submission.turnitin_data_changed!
    @submission.save!
  end

  def create_and_enroll_students(num_to_create)
    @students = []
    num_to_create.times do |i|
      s = User.create!(:name => "student #{i}")
      @course.enroll_student(s)
      @students << s
    end
    @students
  end

  def add_attachment_student_assignment(_file, student, path)
    attachment = student.attachments.new
    attachment.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
    attachment.save!
    @assignment.submit_homework(student, :submission_type => :online_upload, :attachments => [attachment])
  end

  # Creates a dummy rubric and scores its criteria as specified in the parameters (passed as strings)
  def setup_and_grade_rubric(score1, score2)
    student_submission
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    f('.toggle_full_rubric').click
    wait_for_ajaximations
    rubric = f('#rubric_full')

    rubric_inputs = rubric.find_elements(:css, 'input.criterion_points')
    rubric_inputs[0].send_keys(score1)
    rubric_inputs[1].send_keys(score2)
  end

  def clear_grade_and_validate
    @assignment.grade_student @students[0], grade: '', grader: @teacher
    @assignment.grade_student @students[1], grade: '', grader: @teacher

    refresh_page
    expect(f('#grading-box-extended')).to have_value ''
    f('#next-student-button').click
    expect(f('#grading-box-extended')).to have_value ''
  end

  def expand_right_pane
    # attempting to click things that were on the very edge of the page
    # was causing certain specs to flicker. this fixes that issue by
    # increasing the width of the right pane
    driver.execute_script("$('#right_side').width('500px')")
  end

  def submit_comment(text)
    f('#speed_grader_comment_textarea').send_keys(text)
    f('#add_a_comment button[type="submit"]').click
    wait_for_ajaximations
  end

  # returns a list of comment strings from right pane
  def comment_list
    ff('span.comment').map(&:text)
  end
end
