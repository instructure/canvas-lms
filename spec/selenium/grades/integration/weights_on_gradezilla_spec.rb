require_relative '../page_objects/gradezilla_page'
require_relative './weighting_setup'
require_relative './a_gradebook_shared_example'

describe 'gradezilla' do
  include_context "in-process server selenium tests"
  include WeightingSetup

  let(:total_grade) do
    gradezilla = Gradezilla::MultipleGradingPeriods.new
    grading_period_ids = [0, @gp1.id, @gp2.id]
    user_session(@teacher)
    gradezilla.visit(@course)

    if @grading_period_index
      gradezilla.select_grading_period(grading_period_ids[@grading_period_index])
    end
    gradezilla.total_score_for_row(1)
  end

  let(:individual_view) { false }

  before(:once) do
    weighted_grading_setup
  end

  it_behaves_like 'a gradebook'
end
