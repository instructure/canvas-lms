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
    # Setup an existing record for shoulda-matcher's uniqueness validation since we have
    # not-null constraints
    course = Course.create!
    assignment = course.assignments.create!
    student = User.create!
    assignment.moderated_grading_selections.create! do |sel|
      sel.student_id = student.id
    end

    is_expected.to validate_uniqueness_of(:student_id).scoped_to(:assignment_id)
  end
end
