require 'spec_helper'

describe DataFixup::MoveSubAccountGradingPeriodsToCourses do
  before(:each) do
    @root_account = Account.create(name: 'new account')
    @sub_account = @root_account.sub_accounts.create!
  end

  let(:run_data_fixup) { DataFixup::MoveSubAccountGradingPeriodsToCourses.run }

  describe "accounts" do
    context "root accounts" do
      before(:each) do
        create_grading_periods_for(@root_account, grading_periods: [:current])
        run_data_fixup
      end

      it "does not delete grading period groups" do
        expect(@root_account.grading_period_groups.active.count).to eq 1
        expect(@root_account.grading_period_groups.count).to eq 1
      end

      it "does not delete grading periods" do
        expect(@root_account.grading_periods.active.count).to eq 1
        expect(@root_account.grading_periods.count).to eq 1
      end
    end

    context "sub accounts" do
      before(:each) do
        create_grading_periods_for(@sub_account, grading_periods: [:current])
        run_data_fixup
      end

      it "soft deletes grading period groups" do
        expect(@sub_account.grading_period_groups.active).to be_empty
        expect(@sub_account.grading_period_groups.count).to eq 1
      end

      it "soft deletes grading periods" do
        expect(@sub_account.grading_periods.active).to be_empty
        expect(@sub_account.grading_periods.count).to eq 1
      end
    end
  end

  describe "sub-account courses" do
    before(:each) do
      @sub_account_of_sub_account = @sub_account.sub_accounts.create!
      @course = @sub_account_of_sub_account.courses.create!
    end

    context " with grading periods" do
      before(:each) do
        create_grading_periods_for(@course, grading_periods: [:old, :current, :future])
        @periods_before_fixup = @course.grading_periods.to_a
      end

      context "no accounts (root or sub) have grading periods" do
        it "does not have its grading periods altered in any way" do
          run_data_fixup
          @course.reload
          expect(@course.grading_periods).to eq(@periods_before_fixup)
        end
      end

      context "root and sub accounts have grading periods" do
        it "does not have its grading periods altered in any way" do
          create_grading_periods_for(@root_account, grading_periods: [:current])
          create_grading_periods_for(@sub_account, grading_periods: [:current])
          create_grading_periods_for(@sub_account_of_sub_account, grading_periods: [:current])
          run_data_fixup
          @course.reload
          expect(@course.grading_periods).to eq(@periods_before_fixup)
        end
      end

      context "sub accounts have grading periods, root account does not" do
        it "does not have its grading periods altered in any way" do
          create_grading_periods_for(@sub_account, grading_periods: [:current])
          create_grading_periods_for(@sub_account_of_sub_account, grading_periods: [:current])
          run_data_fixup
          @course.reload
          expect(@course.grading_periods).to eq(@periods_before_fixup)
        end
      end

      context "root account has grading periods, sub accounts do not" do
        it "does not have its grading periods altered in any way" do
          create_grading_periods_for(@root_account, grading_periods: [:current])
          run_data_fixup
          @course.reload
          expect(@course.grading_periods).to eq(@periods_before_fixup)
        end
      end
    end

    context " without grading periods" do
      let(:root_account_periods_attrs) do
        @root_account.grading_periods.map do |period|
          { title: period.title, start_date: period.start_date, end_date: period.end_date }
        end
      end

      let(:sub_account_periods_attrs) do
        @sub_account.grading_periods.map do |period|
          { title: period.title, start_date: period.start_date, end_date: period.end_date }
        end
      end

      let(:sub_account_of_sub_account_periods_attrs) do
        @sub_account_of_sub_account.grading_periods.map do |period|
          { title: period.title, start_date: period.start_date, end_date: period.end_date }
        end
      end

      let(:course_periods_attrs) do
        @course.grading_periods.map do |period|
          { title: period.title, start_date: period.start_date, end_date: period.end_date }
        end
      end

      context "no accounts (root or sub) have grading periods" do
        it "does not have its (non-existent) grading periods altered in any way" do
          run_data_fixup
          expect(course_periods_attrs).to be_empty
        end
      end

      context "root account has grading periods, sub accounts do not" do
        it "does not have its (non-existent) grading periods altered in any way" do
          create_grading_periods_for(@root_account, grading_periods: [:current])
          run_data_fixup
          expect(course_periods_attrs).to be_empty
        end
      end

      context "root and sub accounts have grading periods" do
        it "receives copies of the 'nearest' sub-account's grading periods" do
          create_grading_periods_for(@root_account, grading_periods: [:current])
          create_grading_periods_for(@sub_account, grading_periods: [:current])
          create_grading_periods_for(@sub_account_of_sub_account, grading_periods: [:current])
          run_data_fixup
          expect(course_periods_attrs).to eq(sub_account_of_sub_account_periods_attrs)
        end
      end

      context "sub accounts have grading periods, root account does not" do
        it "receives copies of the 'nearest' sub-account's grading periods" do
          create_grading_periods_for(@sub_account, grading_periods: [:current])
          create_grading_periods_for(@sub_account_of_sub_account, grading_periods: [:current])
          run_data_fixup
          expect(course_periods_attrs).to eq(sub_account_of_sub_account_periods_attrs)
        end
      end

      context "nearest sub-account does not have grading periods, next sub-account " \
      "does, and root account does not have grading periods" do
        before(:each) do
          create_grading_periods_for(@sub_account, grading_periods: [:current])
          run_data_fixup
        end

        it "receives copies of the next 'nearest' sub-account's grading periods " do
          expect(course_periods_attrs).to eq(sub_account_periods_attrs)
        end

        it "does not copy the grading_period_group_id over when copying grading periods" do
          grading_period_group_ids = @course.grading_periods.map(&:grading_period_group_id)
          sub_account_grading_period_group_ids = @sub_account.grading_periods.map(&:grading_period_group_id)
          intersection = grading_period_group_ids & sub_account_grading_period_group_ids
          expect(intersection).to be_empty
        end
      end

    end
  end
end
