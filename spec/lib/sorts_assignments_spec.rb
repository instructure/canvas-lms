#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SortsAssignments do

  before do
    @time_now = Time.parse("October 31 2012")
    allow(Time).to receive(:now).and_return(@time_now)
  end

  let(:due_yesterday) {double({:id => 1, :due_at => 1.days.ago }) }
  let(:due_today) {double({ :id => 2, :due_at => @time_now }) }
  let(:due_tomorrow) {double({ :id => 3, :due_at =>  1.days.from_now }) }
  let(:no_due_date) {double({:id => 4, :due_at => nil }) }
  let(:due_in_one_week) {double({ :id => 5, :due_at => 1.week.from_now }) }
  let(:due_in_two_weeks) {double({ :id => 6, :due_at => 2.weeks.from_now }) }
  let(:assignments) {
    [
      due_yesterday,
      due_today,
      due_tomorrow,
      due_in_one_week,
      due_in_two_weeks,
      no_due_date
    ]
  }

  describe "past" do

    it "and_return an array of assignments that are due before now" do
      expect(SortsAssignments.past(assignments)).to match_array [ due_yesterday ]
    end

  end

  describe "undated" do

    it "and_return an array of assignments without a due date" do
      expect(SortsAssignments.undated(assignments)).to match_array [ no_due_date ]
    end

  end

  describe "future" do

    it "and_return an array of assignments due in the future (>= Time.now)" do
      expect(SortsAssignments.future(assignments)).to match_array(
      [
        no_due_date,
        due_today,
        due_tomorrow,
        due_in_one_week,
        due_in_two_weeks
      ]
      )
    end

  end

  describe "upcoming" do

    it "and_return an array of assignments due between right now and 1 week " +
      "from now" do
      expect(SortsAssignments.upcoming(assignments)).to match_array(
      [
        due_today,
        due_tomorrow,
        due_in_one_week
      ]
      )
    end
  end

  describe "up_to" do

    it "gives all the assignments due before the given time" do
      expect(SortsAssignments.up_to(assignments, 2.weeks.from_now)).to match_array(
        [
          due_yesterday,
          due_today,
          due_tomorrow,
          due_in_one_week
        ]
      )
    end

    it "does not include assignments due exactly at the given time" do
      expect(SortsAssignments.up_to(assignments, 2.weeks.from_now)).not_to(
        include( due_in_two_weeks )
      )
    end

  end

  describe "down_to" do

    it "and_return all assignments after the given time" do
      expect(SortsAssignments.down_to(assignments, 1.days.ago )).to match_array(
        [
          due_today,
          due_tomorrow,
          due_in_one_week,
          due_in_two_weeks
        ]
      )
    end

    it "does not include assignments with a due_at equal to the given time" do
      expect(SortsAssignments.down_to(assignments, 1.days.ago)).not_to include(
        due_yesterday
      )
    end

  end

  describe "ungraded_for_user_and_session" do
    let(:user) { double }
    let(:current_user) { double }
    let(:session) { double }
    let(:assignment1) { double }
    let(:assignment2) { double }
    let(:assignment3) { double }
    let(:assignments) { [ assignment1, assignment2, assignment3 ] }
    let(:one_count_query){double(count: 1)}
    let(:zero_count_query){double(count: 0) }
    let(:bad_count_query){double(count: -1) }

    before :each do
      assignments.each { |assignment|
        allow(assignment).to receive_messages(
          :grants_right? => true,
          :expects_submission? => true
        )
      }

      allow(Assignments::NeedsGradingCountQuery).to receive_messages(new: one_count_query)
    end

    it "only includes assignments that current user has permission to view" do
      expect(assignment3).to receive(:grants_right?).with(current_user,session,:grade).
        and_return false
      expect(SortsAssignments.ungraded_for_user_and_session(assignments,user,current_user,session)).
        to match_array [ assignment1, assignment2 ]
    end

    it "only includes assignments that are expecting a submission" do
      expect(assignment3).to receive(:expects_submission?).and_return false
      expect(SortsAssignments.ungraded_for_user_and_session(assignments,user,current_user,session)).
        to match_array [ assignment1, assignment2 ]
    end

    it "only includes assignments that have a grading_count_for_user > 0" do
      allow(Assignments::NeedsGradingCountQuery).to receive(:new).with(assignment2, user).and_return(bad_count_query)
      allow(Assignments::NeedsGradingCountQuery).to receive(:new).with(assignment3, user).and_return(zero_count_query)
      expect(SortsAssignments.ungraded_for_user_and_session(assignments,user,current_user,session)).
        to match_array [ assignment1 ]
    end

  end

  describe "by_due_date" do
    let(:user) { double }
    let(:session) { double }
    let(:submissions) { [] }
    let(:sorted_assignments) {
      SortsAssignments.by_due_date({
        :assignments => assignments,
        :user => user,
        :session => session,
        :upcoming_limit => 1.week.from_now,
        :submissions => []
      })
    }

    before :each do
      assignments.each { |assignment|
        allow(assignment).to receive_messages(
          :grants_right? => true,
          :expects_submission? => true,
          :submission_for_student => {id: nil}
        )
      }
    end

    it "raises an IndexError if a required field is not passed" do
      expect { SortsAssignments.by_due_date({}) }.
        to raise_error IndexError
    end

    describe "the Struct returned" do

      before :each do
        ungraded_assignments = []
        allow(SortsAssignments).to receive(:vdd_map).and_return(assignments)
        allow(SortsAssignments).to receive(:ungraded_for_user_and_session).
          and_return(ungraded_assignments)
        allow(SortsAssignments).to receive(:overdue).with(assignments,user,session,submissions).
          and_return []
      end

      it "stores the past assignments" do
        expect(sorted_assignments.past.call).to eq SortsAssignments.past(assignments)
      end

      it "stores the undated assignments" do
        expect(sorted_assignments.undated.call).to eq(
          SortsAssignments.undated(assignments)
        )
      end

      it "stores the ungraded assignments" do
        expect(sorted_assignments.ungraded.call).to eq(
          SortsAssignments.ungraded_for_user_and_session(
            assignments,user,session
        )
        )
      end

      it "stores the upcoming assignments" do
        expect(sorted_assignments.upcoming.call).to eq(
          SortsAssignments.upcoming(assignments,1.week.from_now)
        )
      end

      it "stores the future events" do
        expect(sorted_assignments.future.call).to eq SortsAssignments.future(assignments)
      end

      it "and_return the overdue assignments" do
        expect(sorted_assignments.overdue.call).to eq SortsAssignments.overdue(assignments, user, session, submissions)
      end

    end

  end

  describe "without_graded_submission" do
    let(:submission1) {double(:assignment_id => due_yesterday.id,
                           :without_graded_submission? => false)}
    let(:submission2) {double(:assignment_id => due_today.id,
                           :without_graded_submission? => false)}
    let(:submissions) { [ submission1, submission2 ] }
    let(:assignments) { [ due_yesterday, due_today ] }

    it "and_return assignments that don't have a matching submission in the "+
      "passed submissions collection" do
      allow(submission1).to receive_messages(:assignment_id => nil )
      expect(SortsAssignments.without_graded_submission(assignments,submissions)).
        to match_array [ due_yesterday ]
    end

    it "and_return assignments that have a matching submission in the collection "+
      "but the submission is without a graded submission." do
      expect(submission1).to receive(:without_graded_submission?).and_return true
      expect(SortsAssignments.without_graded_submission(assignments,submissions)).
        to match_array [ due_yesterday ]
    end

  end

  describe "user_allowed_to_submit" do
    let(:session) {double}
    let(:user) {double}

    before :each do
      assignments.each{|assignment|
        allow(assignment).to receive(:expects_submission?).and_return true
        allow(assignment).to receive(:grants_right?).and_return false
      }
    end

    it "includes assignments where assignment not expecting a submission and "+
      "don't grant rights to user" do
      expect(due_yesterday).to receive(:expects_submission?).and_return true
      expect(due_yesterday).to receive(:grants_right?).with(user,session,:submit).and_return true
      expect(SortsAssignments.user_allowed_to_submit(assignments,user,session)).
        to match_array [ due_yesterday ]
    end

  end

  describe "overdue" do
    let(:session) { double }
    let(:user) { double }
    let(:submissions) { double }

    it "and_return the set of assignments that user is allowed to submit and "+
      "without graded submissions" do
      allow(SortsAssignments).to receive(:past).and_return([ due_yesterday ])
      allow(SortsAssignments).to receive(:user_allowed_to_submit).and_return [ due_yesterday ]
      allow(SortsAssignments).to receive(:without_graded_submission).and_return [ due_yesterday ]
      expect(SortsAssignments.overdue(assignments,user,session,submissions)).to eq [due_yesterday]
    end

  end

  describe "unsubmitted_for_user_and_session" do
    let(:course) { double }
    let(:user) { double }
    let(:current_user) { double }
    let(:session) { double }
    let(:assignment1) { double }
    let(:assignment2) { double }
    let(:assignment3) { double }
    let(:assignments) { [ assignment1, assignment2, assignment3 ] }
    before :each do
      allow(course).to receive_messages(:grants_right? => true)
      assignments.each { |assignment|
        allow(assignment).to receive_messages(
          :expects_submission? => true,
          :submission_for_student => {id: nil}
        )
      }
    end

    it "only includes assignments that current user has permission to view" do
      expect(course).to receive(:grants_right?).with(current_user,session,:manage_grades).and_return false
      expect(SortsAssignments.unsubmitted_for_user_and_session(course,assignments,user,current_user,session)).
        to eq [ ]
    end

    it "only includes assignments that are expecting a submission" do
      allow(assignment2).to receive_messages({:expects_submission? => false})
      expect(SortsAssignments.unsubmitted_for_user_and_session(course,assignments,user,current_user,session)).
        to match_array [ assignment1, assignment3 ]
    end

    it "only includes assignments that do not have a saved submission for the user" do
      allow(assignment3).to receive_messages(:submission_for_student => {id: 1})
      expect(SortsAssignments.unsubmitted_for_user_and_session(course,assignments,user,current_user,session)).
        to match_array [ assignment1, assignment2 ]
    end
  end

end
