require_relative '../page_objects/student_grades_page'
require_relative './weighting_setup'
require_relative './a_gradebook_shared_example'

describe 'gradezilla' do
  include_context "in-process server selenium tests"
  include WeightingSetup

  let(:total_grade) do
    student_grades = StudentGradesPage.new
    grading_period_titles = ["All Grading Periods", @gp1.title, @gp2.title]
    user_session(@teacher)
    student_grades.visit_as_teacher(@course, @student)

    if @grading_period_index
      student_grades.select_period_by_name(grading_period_titles[@grading_period_index])
    end
    student_grades.final_grade.text
  end

  let(:individual_view) { false }

  before(:once) do
    weighted_grading_setup
  end

  it_behaves_like 'a gradebook'
end
