require 'spec_helper'

describe DataFixup::ReassociateGradingPeriodGroups do
  let(:root_account_grading_period_group) { GradingPeriodGroup.find_by(account_id: @root_account) }
  let(:root_account_grading_period) { root_account_grading_period_group.grading_periods.first }
  let(:first_term) { @root_account.enrollment_terms.first }
  let(:second_term) { @root_account.enrollment_terms.second }
  let(:sub_account_term) { @sub_account.enrollment_terms.first }
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
  let(:period_helper) { Factories::GradingPeriodHelper.new }

  before(:each) do
    @root_account = Account.create(name: 'new account')
    group = group_helper.legacy_create_for_account(@root_account)
    period_helper.create_presets_for_group(group, :current)
    @root_account.enrollment_terms.create!
    @sub_account = @root_account.sub_accounts.create!
    group = group_helper.legacy_create_for_account(@sub_account)
    period_helper.create_presets_for_group(group, :future)
    @sub_account.enrollment_terms.create!
    course = @root_account.courses.create!
    group = group_helper.create_for_course(course)
    period_helper.create_presets_for_group(group, :past)
  end

  context "pre-fixup" do
    it "root account enrollment terms do not have an associated grading period group" do
      expect(first_term.grading_period_group).to eq nil
      expect(second_term.grading_period_group).to eq nil
    end

    it "root account enrollment terms do not have associated grading periods" do
      expect(first_term.grading_periods).to be_empty
      expect(second_term.grading_periods).to be_empty
    end

    it "sub account enrollment terms do not have an associated grading period group" do
      expect(sub_account_term.grading_period_group).to eq nil
    end

    it "sub account enrollment terms do not have associated grading periods" do
      expect(sub_account_term.grading_periods).to be_empty
    end
  end

  context "post-fixup" do
    before(:each) do
      DataFixup::ReassociateGradingPeriodGroups.run
    end

    it "root account enrollment terms belong to the root account's grading period group after the fixup " \
    "(and not the sub account grading period group or course grading period group)" do
      expect(first_term.grading_period_group).to eq root_account_grading_period_group
      expect(second_term.grading_period_group).to eq root_account_grading_period_group
    end

    it "root account enrollment terms have grading periods after the fixup" do
      expect(first_term.grading_periods.first).to eq root_account_grading_period
      expect(second_term.grading_periods.first).to eq root_account_grading_period
    end

    it "sub account enrollment terms do not have an associated grading period group" do
      expect(sub_account_term.grading_period_group).to eq nil
    end

    it "sub account enrollment terms do not have associated grading periods" do
      expect(sub_account_term.grading_periods).to be_empty
    end
  end
end
