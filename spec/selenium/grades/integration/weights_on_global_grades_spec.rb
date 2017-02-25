require_relative '../page_objects/global_grades_page'
require_relative './weighting_setup'
require_relative './a_gradebook_shared_example'

describe 'gradezilla' do
  include_context "in-process server selenium tests"
  include WeightingSetup

  let(:total_grade) do
    grading_period_titles = ["All Grading Periods", @gp1.title, @gp2.title]

    user_session(@student)
    GlobalGrades.visit()

    if @grading_period_index
      GlobalGrades.select_grading_period(@course, grading_period_titles[@grading_period_index])
    end
    GlobalGrades.get_score_for_course(@course)
  end

  let(:individual_view) { false }

  before(:once) do
    weighted_grading_setup
  end

  it_behaves_like 'a gradebook'
end
