require 'spec_helper'

describe DataFixup::PopulateGradingPeriodCloseDates do
  before(:each) do
    root_account = Account.create(name: 'new account')
    group = Factories::GradingPeriodGroupHelper.new.create_for_account(root_account)
    period_helper = Factories::GradingPeriodHelper.new
    @first_period = period_helper.create_presets_for_group(group, :past).first
    @first_period.close_date = nil
    @first_period.save!
    @second_period = period_helper.create_presets_for_group(group, :current).first
    @second_period.close_date = 3.days.from_now(@second_period.end_date)
    @second_period.save!
  end

  before(:each) do
    DataFixup::PopulateGradingPeriodCloseDates.run
  end

  it "does not alter already-set close dates" do
    @second_period.reload
    expect(@second_period.close_date).to eq 3.days.from_now(@second_period.end_date)
  end

  it "sets the close date to the end date for periods with nil close dates" do
    @first_period.reload
    expect(@first_period.close_date).to eq @first_period.end_date
  end
end
