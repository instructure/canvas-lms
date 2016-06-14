require 'spec_helper'

describe ModeratedGrading::Selection do
  it { is_expected.to belong_to(:assignment) }

  it do
    is_expected.to belong_to(:provisional_grade).
      with_foreign_key(:selected_provisional_grade_id).
      class_name('ModeratedGrading::ProvisionalGrade')
  end

  it do
    is_expected.to belong_to(:student).
      class_name('User')
  end

  it "is restricted to one selection per assignment/student pair" do
    course_with_student
    @assignment = @course.assignments.create!
    s = @assignment.moderated_grading_selections.build
    s.student_id = @student.id
    s.save!
    s2 = @assignment.moderated_grading_selections.build
    s2.student_id = @student.id
    expect { s2.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
