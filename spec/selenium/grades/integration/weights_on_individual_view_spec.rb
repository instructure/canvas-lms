require_relative '../page_objects/srgb_page'
require_relative './weighting_setup'
require_relative './a_gradebook_shared_example'

describe 'individual view' do
  include_context "in-process server selenium tests"
  include WeightingSetup

  let(:total_grade) do
    user_session(@teacher)
    grading_period_titles = ['All Grading Periods', @gp1.title, @gp2.title]
    SRGB.visit(@course.id)

    if @grading_period_index
      SRGB.select_grading_period(grading_period_titles[@grading_period_index])
      refresh_page
    end
    SRGB.select_student(@student)
    SRGB.total_score()
  end

  let(:individual_view) { true }

  before(:once) do
    weighted_grading_setup
  end

  after(:each) do
    clear_local_storage
  end

  it_behaves_like 'a gradebook'
end
