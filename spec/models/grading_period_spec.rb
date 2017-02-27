#
# Copyright (C) 2014-2016 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require_relative '../spec_helper'

describe GradingPeriod do
  subject(:grading_period) { grading_period_group.grading_periods.build(params) }

  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
  let(:account) { Account.create! }
  let(:course) { account.courses.create! }
  let(:grading_period_group) do
    group = account.grading_period_groups.create!(title: "A Group")
    term = course.enrollment_term
    group.enrollment_terms << term
    group
  end
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:params) do
    {
      title: 'A Grading Period',
      start_date: now,
      end_date:   1.day.from_now(now),
      close_date: 5.days.from_now(now)
    }
  end

  it { is_expected.to be_valid }

  it "requires a start_date" do
    grading_period = GradingPeriod.new(params.except(:start_date))
    expect(grading_period).not_to be_valid
  end

  it "requires an end_date" do
    grading_period = GradingPeriod.new(params.except(:end_date))
    expect(grading_period).not_to be_valid
  end

  it "requires start_date to be before end_date" do
    subject.assign_attributes(start_date: Time.zone.now, end_date: 1.day.ago(now))
    is_expected.not_to be_valid
  end

  it "requires a title" do
    grading_period = GradingPeriod.new(params.except(:title))
    expect(grading_period).not_to be_valid
  end

  describe ".in_closed_grading_period?" do
    let(:in_closed_grading_period) { closed_period.start_date + 1.day }
    let(:in_not_closed_grading_period) { not_closed_period.start_date + 1.day }
    let(:outside_of_any_grading_period) { not_closed_period.end_date + 1.week }
    let!(:closed_period) do
      grading_period_group.grading_periods.create!(
        title: "closed",
        start_date: 2.weeks.ago(now),
        end_date:   1.week.ago(now),
        close_date: 3.days.ago(now)
      )
    end
    let!(:another_closed_period) do
      grading_period_group.grading_periods.create!(
        title: "another closed period",
        start_date: 4.weeks.ago(now),
        end_date:   3.weeks.ago(now),
        close_date: 2.weeks.ago(now)
      )
    end
    let!(:not_closed_period) do
      grading_period_group.grading_periods.create!(
        title: "a period",
        start_date: 3.days.ago(now),
        end_date:   3.days.from_now(now),
        close_date: 5.days.from_now(now)
      )
    end

    it "returns true if the submission is due in a closed grading period" do
      result = GradingPeriod.date_in_closed_grading_period?(
        course: course,
        date: in_closed_grading_period
      )
      expect(result).to be true
    end

    it "returns false if the submission is due in a not closed grading period" do
      result = GradingPeriod.date_in_closed_grading_period?(
        course: course,
        date: in_not_closed_grading_period
      )
      expect(result).to be false
    end

    it "returns false if the submission is due outside of any grading period" do
      result = GradingPeriod.date_in_closed_grading_period?(
        course: course,
        date: outside_of_any_grading_period
      )
      expect(result).to be false
    end

    it "returns true if the due date is null and the last grading period is closed" do
      not_closed_period.destroy
      result = GradingPeriod.date_in_closed_grading_period?(
        course: course,
        date: nil
      )
      expect(result).to be true
    end

    it "returns false if the due date is null and the last grading period is not closed" do
      result = GradingPeriod.date_in_closed_grading_period?(
        course: course,
        date: nil
      )
      expect(result).to be false
    end
  end

  describe ".current" do
    subject { grading_period_group.grading_periods.current }

    context "no periods" do
      it "finds no current periods" do
        is_expected.to be_empty
      end
    end

    context "one current period" do
      let!(:period) do
        grading_period_group.grading_periods.create!(
          title:      "a period",
          start_date: 1.day.ago(now),
          end_date:   1.day.from_now(now),
          close_date: 2.days.from_now(now)
        )
      end

      it "finds one current period" do
        is_expected.to eq [period]
      end

      context "where end_date equals Time.now" do
        it "does not include period" do
          Timecop.freeze(now.change(usec: 0)) do
            period.update!(end_date: now)
            is_expected.to be_present
          end
        end
      end

      context "where end_date equals Time.now + 1" do
        it "does not include period" do
          Timecop.freeze(now.change(usec: 0) + 1) do
            period.update!(end_date: now)
            is_expected.to be_empty
          end
        end
      end

      context "where start_date equals Time.now" do
        it "does not include period" do
          Timecop.freeze(now.change(usec: 0)) do
            period.update!(start_date: now)
            is_expected.to be_empty
          end
        end
      end

      context "where start_date equals Time.now + 1" do
        it "does not include period" do
          Timecop.freeze(now.change(usec: 0) + 1) do
            period.update!(start_date: now)
            is_expected.to be_present
          end
        end
      end
    end
  end

  describe "#as_json_with_user_permissions" do
    it "includes the close_date in the returned object" do
      json = grading_period.as_json_with_user_permissions(User.new)
      expect(json).to have_key("close_date")
    end
  end

  describe "close_date" do
    context "grading period group belonging to an account" do
      it "allows setting a close_date that is after the end_date" do
        grading_period = grading_period_group.grading_periods.create!(params)
        expect(grading_period.close_date).not_to eq(grading_period.end_date)
      end

      it "sets the close_date to the end_date if no close_date is provided" do
        grading_period = grading_period_group.grading_periods.create!(params.except(:close_date))
        expect(grading_period.close_date).to eq(grading_period.end_date)
      end

      it "is invalid if the close date is before the end date" do
        period_params = params.merge(close_date: 1.day.ago(params[:end_date]))
        grading_period = grading_period_group.grading_periods.build(period_params)
        expect(grading_period).to be_invalid
      end

      it "considers the grading period valid if the close date is equal to the end date" do
        period_params = params.merge(close_date: params.fetch(:end_date))
        grading_period = grading_period_group.grading_periods.build(period_params)
        expect(grading_period).to be_valid
      end
    end

    context "grading period group belonging to a course" do
      let(:course_grading_period_group) { group_helper.legacy_create_for_course(course) }

      it "does not allow setting a close_date that is different from the end_date" do
        grading_period = course_grading_period_group.grading_periods.create!(params)
        expect(grading_period.close_date).to eq(params[:end_date])
      end

      it "sets the close_date to the end_date if no close_date is provided" do
        grading_period = course_grading_period_group.grading_periods.create!(params.except(:close_date))
        expect(grading_period.close_date).to eq(grading_period.end_date)
      end

      it "sets the close_date to the end_date when the grading period is updated" do
        grading_period = course_grading_period_group.grading_periods.create!(params.except(:close_date))
        new_end_date = 5.weeks.from_now(now)
        grading_period.end_date = new_end_date
        grading_period.save!
        expect(grading_period.close_date).to eq(new_end_date)
      end
    end
  end

  describe "#closed?" do
    around { |example| Timecop.freeze(now, &example) }

    it "returns true if the current date is past the close date" do
      period = grading_period_group.grading_periods.build(
        title: "Closed Period",
        start_date: 10.days.ago(now),
        end_date: 5.days.ago(now),
        close_date: 3.days.ago(now)
      )
      expect(period).to be_closed
    end

    it "returns false if the current date is before the close date" do
      period = grading_period_group.grading_periods.build(
        title: "A Period",
        start_date: 10.days.ago(now),
        end_date: 5.days.ago(now),
        close_date: 2.days.from_now(now)
      )
      expect(period).not_to be_closed
    end

    it "returns false if the current date matches the close date" do
      period = grading_period_group.grading_periods.build(
        title: "A Period",
        start_date: 10.days.ago(now),
        end_date: 5.days.ago(now),
        close_date: now
      )
      expect(period).not_to be_closed
    end
  end

  describe '#destroy' do
    it_behaves_like 'soft deletion' do
      let(:creation_arguments) { params }
      subject { grading_period_group.grading_periods }
    end

    it 'destroys associated scores' do
      course = Course.create!
      enrollment = student_in_course(course: course)
      score = enrollment.scores.create!(grading_period: grading_period)
      grading_period.destroy
      expect(score.reload).to be_deleted
    end

    it 'does not destroy the set when the last grading period is destroyed (account grading periods)' do
      grading_period.save!
      grading_period.destroy
      expect(grading_period_group).not_to be_deleted
    end

    context 'course grading periods (legacy support)' do
      before(:once) do
        @grading_period_set = course.grading_period_groups.create!
        @period = @grading_period_set.grading_periods.create!(
          title: 'Grading Period',
          start_date: 5.days.ago,
          end_date: 2.days.ago
        )
      end

      it 'destroys the set when the last grading period is destroyed' do
        @period.destroy
        expect(@grading_period_set).to be_deleted
      end

      it 'does not destroy the set when a grading period is destroyed and it is not the last period' do
        @grading_period_set.grading_periods.create!(
          title: 'A New Grading Period',
          start_date: 2.days.from_now,
          end_date: 5.days.from_now
        )
        @period.destroy
        expect(@grading_period_set).not_to be_deleted
      end
    end
  end

  describe ".for" do
    let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
    let(:period_helper) { Factories::GradingPeriodHelper.new }
    let(:term) do
      enrollment_term = @root_account.enrollment_terms.create!
      @course.enrollment_term = enrollment_term
      @course.save!
      enrollment_term
    end

    context "when context is a course" do
      before(:once) do
        @root_account = account_model
        @sub_account = @root_account.sub_accounts.create!
        @course = Course.create!(account: @sub_account)
      end

      it "finds all grading periods on a course" do
        group_1 = group_helper.legacy_create_for_course(@course)
        group_2 = group_helper.legacy_create_for_course(@course)
        period_1 = period_helper.create_with_weeks_for_group(group_1, 5, 3)
        period_2 = period_helper.create_with_weeks_for_group(group_2, 3, 1)
        expect(GradingPeriod.for(@course)).to match_array([period_1, period_2])
      end

      it "ignores grading periods associated with unrelated courses" do
        other_course = Course.create!(account: @sub_account)
        group_1 = group_helper.legacy_create_for_course(@course)
        group_2 = group_helper.legacy_create_for_course(other_course)
        period_1 = period_helper.create_with_weeks_for_group(group_1, 5, 3)
        period_helper.create_with_weeks_for_group(group_2, 3, 1)
        expect(GradingPeriod.for(@course)).to match_array([period_1])
      end

      it "returns grading periods for the course enrollment term when the course has no grading period groups" do
        group = group_helper.create_for_account(@root_account)
        term.update_attribute(:grading_period_group_id, group)
        period = period_helper.create_with_weeks_for_group(group, 5, 3)
        expect(GradingPeriod.for(@course)).to match_array([period])
      end

      it "returns grading periods for the course enrollment term when the course has no grading periods" do
        group_helper.legacy_create_for_course(@course)
        group_2 = group_helper.create_for_account(@root_account)
        term.update_attribute(:grading_period_group_id, group_2)
        period = period_helper.create_with_weeks_for_group(group_2, 5, 3)
        expect(GradingPeriod.for(@course)).to match_array([period])
      end

      it "returns an empty array when the course has no grading periods groups" do
        expect(GradingPeriod.for(@course)).to match_array([])
      end

      it "returns an empty array when the course has no grading periods" do
        group_helper.legacy_create_for_course(@course)
        expect(GradingPeriod.for(@course)).to match_array([])
      end

      it "includes only 'active' grading periods from the course grading period group" do
        group_1 = group_helper.legacy_create_for_course(@course)
        group_2 = group_helper.legacy_create_for_course(@course)
        period_1 = period_helper.create_with_weeks_for_group(group_1, 5, 3)
        period_2 = period_helper.create_with_weeks_for_group(group_2, 3, 1)
        period_2.workflow_state = :deleted
        period_2.save
        expect(GradingPeriod.for(@course)).to match_array([period_1])
      end

      it "includes only 'active' grading periods from the course enrollment term group" do
        group = group_helper.create_for_account(@root_account)
        term.update_attribute(:grading_period_group_id, group)
        period_1 = period_helper.create_with_weeks_for_group(group, 5, 3)
        period_2 = period_helper.create_with_weeks_for_group(group, 3, 1)
        period_2.workflow_state = :deleted
        period_2.save
        expect(GradingPeriod.for(@course)).to match_array([period_1])
      end

      it "does not include grading periods from the course enrollment term group if inherit is false" do
        group = group_helper.create_for_account(@root_account)
        term.update_attribute(:grading_period_group_id, group)
        period_helper.create_with_weeks_for_group(group, 5, 3)
        period_2 = period_helper.create_with_weeks_for_group(group, 3, 1)
        period_2.workflow_state = :deleted
        period_2.save
        expect(GradingPeriod.for(@course, inherit: false)).to match_array([])
      end
    end

    context "when context is an account" do
      before(:once) do
        @root_account = account_model
        @sub_account = @root_account.sub_accounts.create!
        @course = Course.create!(account: @sub_account)
      end

      it "finds all grading periods on an account" do
        group_1 = group_helper.create_for_account(@root_account)
        group_2 = group_helper.create_for_account(@root_account)
        period_1 = period_helper.create_with_weeks_for_group(group_1, 5, 3)
        period_2 = period_helper.create_with_weeks_for_group(group_2, 3, 1)
        expect(GradingPeriod.for(@root_account)).to match_array([period_1, period_2])
      end

      it "returns an empty array when the account has no grading period groups" do
        expect(GradingPeriod.for(@root_account)).to match_array([])
      end

      it "returns an empty array when the account has no grading periods" do
        group_helper.create_for_account(@root_account)
        expect(GradingPeriod.for(@root_account)).to match_array([])
      end

      it "does not return grading periods on the course directly" do
        group = group_helper.legacy_create_for_course(@course)
        period_helper.create_with_weeks_for_group(group, 5, 3)
        period_helper.create_with_weeks_for_group(group, 3, 1)
        expect(GradingPeriod.for(@root_account)).to match_array([])
      end

      it "includes only 'active' grading periods from the account grading period group" do
        group_1 = group_helper.create_for_account(@root_account)
        group_2 = group_helper.create_for_account(@root_account)
        period_1 = period_helper.create_with_weeks_for_group(group_1, 5, 3)
        period_2 = period_helper.create_with_weeks_for_group(group_2, 3, 1)
        period_2.workflow_state = :deleted
        period_2.save
        expect(GradingPeriod.for(@root_account)).to match_array([period_1])
      end
    end
  end

  describe ".current_period_for" do
    let(:account) { Account.new }
    let(:not_current_grading_period) { mock }
    let(:current_grading_period) { mock }

    it "returns the current grading period given a context" do
      GradingPeriod.expects(:for).with(account).returns([not_current_grading_period, current_grading_period])
      not_current_grading_period.expects(:current?).returns(false)
      current_grading_period.expects(:current?).returns(true)
      expect(GradingPeriod.current_period_for(account)).to eq(current_grading_period)
    end

    it "returns nil if grading periods exist for the given context, but none are current" do
      GradingPeriod.expects(:for).with(account).returns([not_current_grading_period])
      not_current_grading_period.expects(:current?).returns(false)
      expect(GradingPeriod.current_period_for(account)).to be_nil
    end

    it "returns nil if no grading periods exist for the given context" do
      GradingPeriod.expects(:for).with(account).returns([])
      expect(GradingPeriod.current_period_for(account)).to be_nil
    end
  end

  # TODO: move all of this to filter_with_overrides_by_due_at_for_class.rb
  describe "#assignments" do
    let!(:first_assignment)  { course.assignments.create!(due_at: first_grading_period.start_date + 1.second) }
    let!(:second_assignment) { course.assignments.create!(due_at: second_grading_period.start_date + 1.seconds) }
    let!(:third_assignment)  { course.assignments.create!(due_at: nil) }

    let(:first_grading_period) do
        grading_period_group.grading_periods.create!(
          title:      '1st period',
          start_date: 2.months.from_now(now),
          end_date:   3.months.from_now(now)
        )
    end
    let(:second_grading_period) do
      grading_period_group.grading_periods.create!(
        title:      '2nd period',
        start_date: 3.months.from_now(now),
        end_date:   4.months.from_now(now)
      )
    end
    let(:grading_period_group) { group_helper.legacy_create_for_course(course) }

    it "filters the first grading period" do
      assignments = first_grading_period.assignments(course.assignments)
      expect(assignments).to eq [first_assignment]
    end

    it "filters assignments without a due_at into the last grading period" do
      assignments = second_grading_period.assignments(course.assignments)
      expect(assignments).to eq [second_assignment, third_assignment]
    end

    describe "when due at is near the edge of a period" do
      let!(:fourth_assignment) do
        course.assignments.create!(
          due_at: third_grading_period.end_date - 0.995.seconds
        )
      end

      let!(:fifth_assignment) do
        course.assignments.create!(
          due_at: fourth_grading_period.start_date - 0.005.seconds
        )
      end

      let(:third_grading_period) do
        grading_period_group.grading_periods.create!(
          title:      '3rd period',
          start_date: 5.months.from_now(now),
          end_date:   6.months.from_now(now)
        )
      end

      let(:fourth_grading_period) do
        grading_period_group.grading_periods.create!(
          title:      '4th period',
          start_date: 7.months.from_now(now),
          end_date:   8.months.from_now(now)
        )
      end

      it "includes assignments if they are on the future edge of end date" do
        assignments = third_grading_period.assignments(course.assignments)
        expect(assignments).to include fourth_assignment
      end

      it "does NOT include assignments if they are on the past edge of start date" do
        assignments = fourth_grading_period.assignments(course.assignments)
        expect(assignments).not_to include fifth_assignment
      end
    end
  end

  describe "#current?" do
    subject(:grading_period) { GradingPeriod.new }

    it "returns false for a grading period in the past" do
      grading_period.assign_attributes(
        start_date: 2.months.ago(now),
        end_date:   1.month.ago(now)
      )
      expect(grading_period).to_not be_current
    end

    it "returns true if the current time falls between the start date and end date (inclusive)",
    test_id: 2528634, priority: "2" do
      grading_period.assign_attributes(
        start_date: 1.month.ago(now),
        end_date:   1.month.from_now(now)
      )
      expect(grading_period).to be_current
    end

    it "returns false for a grading period in the future" do
      grading_period.assign_attributes(
        start_date: 1.month.from_now(now),
        end_date:   2.months.from_now(now)
      )
      expect(grading_period).to_not be_current
    end
  end

  context 'given an existing grading_period' do
    let(:course) { Course.create! }
    let(:grading_period_group) { group_helper.legacy_create_for_course(course) }
    let(:existing_grading_period) do
      grading_period_group.grading_periods.create!(
        title: 'a title',
        start_date: now,
        end_date: 2.days.from_now(now)
      )
    end

    describe '#overlapping?' do
      context 'given a new grading period with a start_date and an end_date' \
        'that overlaps with the existing grading_period' do
        subject { grading_period_group.grading_periods.build(start_date: start_date, end_date: end_date) }
        let(:start_date) { existing_grading_period.start_date }
        let(:end_date)   { existing_grading_period.end_date }
        it { is_expected.to be_overlapping }
      end

      context 'given a new grading period with a start_date that is the' \
        'end_date of existing grading_period' do
        subject { grading_period_group.grading_periods.build(start_date: start_date, end_date: end_date)}
        let(:start_date) { existing_grading_period.end_date }
        let(:end_date)   { existing_grading_period.end_date + 1.month }
        it { is_expected.not_to be_overlapping }
      end

      context 'given a new grading period with an end_date that is the ' \
        'start_date of existing grading_period' do
        subject { grading_period_group.grading_periods.build(start_date: start_date, end_date: end_date)}
        let(:start_date) { existing_grading_period.start_date - 1.month }
        let(:end_date)   { existing_grading_period.start_date }
        it { is_expected.not_to be_overlapping }
      end
    end

    it "after a grading period is persisted it continues to not overlap" do
      expect(existing_grading_period).not_to be_overlapping
    end
  end

  describe "Soft deletion" do
    subject { grading_period_group.grading_periods }
    let(:creation_arguments) { [period_one, period_two] }
    let(:period_one) { { title: 'an title', start_date: 1.week.ago(now), end_date: 2.weeks.from_now(now) } }
    let(:period_two) { { title: 'an title', start_date: 2.weeks.from_now(now), end_date: 5.weeks.from_now(now) } }
    include_examples "soft deletion"
  end

  describe ".in_date_range?" do
    subject(:period) do
      grading_period_group.grading_periods.build(
        title:      'a period',
        start_date: 1.week.ago(now),
        end_date:   2.weeks.from_now(now)
      )
    end

    it "is in date range for a date that equals end_date" do
      is_expected.to be_in_date_range(period.end_date)
    end

    it "is not in date range for a date before the period" do
      is_expected.not_to be_in_date_range(2.weeks.ago(now))
    end

    it "is not in date range for or a date after the period" do
      is_expected.not_to be_in_date_range(3.weeks.from_now(now))
    end

    it "is not in date range for a date that equals end_date" do
      is_expected.not_to be_in_date_range(period.start_date)
    end
  end

  describe ".json_for" do
    context "when given a course" do
      it "returns a list sorted by date with is_last" do
        group = group_helper.legacy_create_for_course(course)
        group.grading_periods.create!(
          start_date: 1.week.ago(now),
          end_date: 2.weeks.from_now(now),
          title: 'C'
        )
        group.grading_periods.create!(
          start_date: 4.weeks.ago(now),
          end_date: 3.weeks.ago(now),
          title: 'A'
        )
        group.grading_periods.create!(
          start_date: 3.weeks.ago(now),
          end_date: 2.weeks.ago(now),
          title: 'B'
        )
        json = GradingPeriod.json_for(course, nil)
        expect(json.map { |el| el['title'] }).to eq %w(A B C)
        expect(json.map { |el| el['is_last'] }).to eq [false, false, true]
      end
    end
  end

  describe '#account_group?' do
    context "given an account grading period group" do
      it { is_expected.to be_account_group }
    end

    context "given a course grading period group" do
      subject(:course_period) { grading_period_group.grading_periods.create!(params) }
      let(:grading_period_group) { group_helper.legacy_create_for_course(course) }

      it { is_expected.not_to be_account_group }
    end
  end

  describe '#course_group?' do
    context "given a course grading period group" do
      subject(:course_period) { grading_period_group.grading_periods.create!(params) }
      let(:grading_period_group) { group_helper.legacy_create_for_course(course) }

      it { is_expected.to be_course_group }
    end

    context "given an account grading period group" do
      it { is_expected.not_to be_course_group }
    end
  end

  describe '#weight' do
    it "can persist double precision values" do
      subject.update!(weight: 1.5)
      expect(subject.reload.weight).to eql 1.5
    end
  end

  describe 'grading period scores' do
    before do
      student_in_course(course: course, active_all: true)
      teacher_in_course(course: course, active_all: true)
      @assignment = course.assignments.create!(due_at: 10.days.from_now(now), points_possible: 10)
      @assignment.grade_student(@student, grade: 8, grader: @teacher)
    end

    it 'creates scores for the grading period upon its creation' do
      expect{ grading_period.save! }.to change{ Score.count }.from(1).to(2)
    end

    it 'updates grading period scores when the grading period end date is changed' do
      grading_period.save!
      expect do
        day_after_assignment_is_due = 1.day.from_now(@assignment.due_at)
        grading_period.update!(
          end_date: day_after_assignment_is_due,
          close_date: day_after_assignment_is_due
        )
      end.to change{
        Score.where(grading_period_id: grading_period).first.current_score
      }.from(nil).to(80.0)
    end

    it 'updates grading period scores when the grading period start date is changed' do
      day_before_grading_period_starts = 1.day.ago(grading_period.start_date)
      @assignment.update!(due_at: day_before_grading_period_starts)
      grading_period.save!
      expect{ grading_period.update!(start_date: 1.day.ago(@assignment.due_at)) }.to change{
        Score.where(grading_period_id: grading_period).first.current_score
      }.from(nil).to(80.0)
    end
  end
end
