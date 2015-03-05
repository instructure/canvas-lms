#
# Copyright (C) 2014 Instructure, Inc.
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
  subject { grading_period }
  let(:grading_period) { grading_period_group.grading_periods.build(params) }
  let(:grading_period_group) { account.grading_period_groups.create!(account: account) }
  let(:account) { Account.create! }

  let(:params) do
    { start_date: Time.zone.now, end_date: 1.day.from_now }
  end

  it { is_expected.to be_valid }

  it "requires a start_date" do
    grading_period =  GradingPeriod.new(params.except(:start_date))
    expect(grading_period).to_not be_valid
  end

  it "requires an end_date" do
    grading_period = GradingPeriod.new(params.except(:end_date))
    expect(grading_period).to_not be_valid
  end

  it "requires start_date to be before end_date" do
    subject.update_attributes(start_date: Time.zone.now, end_date: 1.day.ago)
    is_expected.to_not be_valid
  end

  describe "#destroy" do
    before { subject.destroy }

    it "marks workflow as deleted" do
      expect(subject.workflow_state).to eq "deleted"
    end

    it "does not destroy" do
      expect(subject).to_not be_destroyed
    end
  end

  describe "#destroy!" do
    before { subject.destroy! }

    it { is_expected.to be_destroyed }
  end

  describe ".for" do

    context "when context is an account" do
      let(:account) { Account.new }
      let(:finder) { mock }

      it "delegates calls" do
        GradingPeriod::AccountGradingPeriodFinder.expects(:new).with(account).once.returns(finder)
        finder.expects(:grading_periods).once
        GradingPeriod.for(account)
      end
    end

    context "when context is a course" do
      let(:course) { Course.new }
      let(:finder) { mock }

      it "delegates calls" do
        GradingPeriod::CourseGradingPeriodFinder.expects(:new).with(course).once.returns(finder)
        finder.expects(:grading_periods).once
        GradingPeriod.for(course)
      end
    end
  end

  describe ".context_find" do
    let(:account) { mock }
    let(:finder) { mock }
    let(:grading_period) { mock }
    let(:id) { 1 }

    it "delegates" do
      grading_period.expects(:id).returns(1)
      GradingPeriod.expects(:for).with(account).returns([grading_period])

      expect(GradingPeriod.context_find(context: account, id: id)).to eq grading_period
    end
  end

  describe "#assignments" do
    it "filters assignments for grading period" do
      course_with_teacher active_all: true
      gp1, gp2 = grading_periods count: 2
      a1, a2 = [gp1, gp2].map { |gp|
        @course.assignments.create! due_at: gp.start_date + 1
      }
      # no due date goes in final grading period
      a3 = @course.assignments.create!
      expect(gp1.assignments(@course.assignments)).to eq [a1]
      expect(gp2.assignments(@course.assignments)).to eq [a2, a3]
    end
  end
end

