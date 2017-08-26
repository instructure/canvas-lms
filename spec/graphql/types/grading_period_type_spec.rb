require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::GradingPeriodType do
  let_once(:grading_period) {
    GradingPeriod.create! start_date: Date.yesterday,
      end_date: Date.tomorrow,
      title: "asdf",
      grading_period_group: GradingPeriodGroup.create!(course: course_factory)
  }

  let(:grading_period_type) {
    GraphQLTypeTester.new(Types::GradingPeriodType, grading_period)
  }

  it "works" do
    expect(grading_period_type._id).to eq grading_period.id
    expect(grading_period_type.title).to eq grading_period.title
    expect(grading_period_type.startDate).to eq grading_period.start_date
    expect(grading_period_type.endDate).to eq grading_period.end_date
  end
end
