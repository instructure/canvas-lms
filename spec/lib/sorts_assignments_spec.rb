require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SortsAssignments do

  before do
    @time_now = Time.parse("October 31 2012")
    Time.stubs(:now).returns @time_now
  end

  let(:due_yesterday) { stub({:id => 1, :due_at => 1.days.ago }) }
  let(:due_today) { stub({ :id => 2, :due_at => @time_now }) }
  let(:due_tomorrow) { stub({ :id => 3, :due_at =>  1.days.from_now }) }
  let(:no_due_date) { stub({:id => 4, :due_at => nil }) }
  let(:due_in_one_week) { stub({ :id => 5, :due_at => 1.week.from_now }) }
  let(:due_in_two_weeks) { stub({ :id => 6, :due_at => 2.weeks.from_now }) }
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

    it "returns an array of assignments that are due before now" do
      SortsAssignments.past(assignments).should =~ [ due_yesterday ]
    end

  end

  describe "undated" do

    it "returns an array of assignments without a due date" do
      SortsAssignments.undated(assignments).should =~ [ no_due_date ]
    end

  end

  describe "future" do

    it "returns an array of assignments due in the future (>= Time.now)" do
      SortsAssignments.future(assignments).should =~
      [
        no_due_date,
        due_today,
        due_tomorrow,
        due_in_one_week,
        due_in_two_weeks
      ]
    end

  end

  describe "upcoming" do

    it "returns an array of assignments due between right now and 1 week " +
      "from now" do
      SortsAssignments.upcoming(assignments).should =~
      [
        due_today,
        due_tomorrow,
        due_in_one_week
      ]
    end
  end

  describe "up_to" do

    it "gives all the assignments due before the given time" do
      SortsAssignments.up_to(assignments, 2.weeks.from_now).should =~
        [
          due_yesterday,
          due_today,
          due_tomorrow,
          due_in_one_week
        ]
    end

    it "does not include assignments due exactly at the given time" do
      SortsAssignments.up_to(assignments, 2.weeks.from_now).should_not(
        include( due_in_two_weeks )
      )
    end

  end

  describe "down_to" do

    it "returns all assignments after the given time" do
      SortsAssignments.down_to(assignments, 1.days.ago ).should =~
        [
          due_today,
          due_tomorrow,
          due_in_one_week,
          due_in_two_weeks
        ]
    end

    it "does not include assignments with a due_at equal to the given time" do
      SortsAssignments.down_to(assignments, 1.days.ago).should_not include(
        due_yesterday
      )
    end

  end

  describe "ungraded_for_user_and_session" do
    let(:user) { stub }
    let(:session) { stub }
    let(:assignment1) { stub }
    let(:assignment2) { stub }
    let(:assignment3) { stub }
    let(:assignments) { [ assignment1, assignment2, assignment3 ] }
    let(:one_count_query){ stub(count: 1)}
    let(:zero_count_query){ stub(count: 0) }
    let(:bad_count_query){ stub(count: -1) }

    before :each do
      assignments.each { |assignment|
        assignment.stubs(
          :grants_right? => true,
          :expects_submission? => true
        )
      }

      Assignments::NeedsGradingCountQuery.stubs(new: one_count_query)
    end

    it "only includes assignments that current user has permission to view" do
      assignment3.expects(:grants_right?).with(user,session,:grade).
        returns false
      SortsAssignments.ungraded_for_user_and_session(assignments,user,session).
        should =~[ assignment1, assignment2 ]
    end

    it "only includes assignments that are expecting a submission" do
      assignment3.expects(:expects_submission?).returns false
      SortsAssignments.ungraded_for_user_and_session(assignments,user,session).
        should =~[ assignment1, assignment2 ]
    end

    it "only includes assignments that have a grading_count_for_user > 0" do
      Assignments::NeedsGradingCountQuery.stubs(:new).with(assignment2, user).returns(bad_count_query)
      Assignments::NeedsGradingCountQuery.stubs(:new).with(assignment3, user).returns(zero_count_query)
      SortsAssignments.ungraded_for_user_and_session(assignments,user,session).
        should =~ [ assignment1 ]
    end

  end

  describe "by_due_date" do
    let(:user) { stub }
    let(:session) { stub }
    let( :submissions ) { [] }
    let(:sorted_assignments) {
      SortsAssignments.by_due_date({
        :assignments => assignments,
        :user => user,
        :session => session,
        :upcoming_limit => 1.week.from_now,
        :submissions => []
      })
    }

    it "raises an IndexError if a required field is not passed" do
      lambda { SortsAssignments.by_due_date({}) }.
        should raise_error IndexError
    end

    describe "the Struct returned" do

      before :each do
        ungraded_assignments = []
        SortsAssignments.stubs(:vdd_map).returns(assignments)
        SortsAssignments.stubs(:ungraded_for_user_and_session).
          returns(ungraded_assignments)
        SortsAssignments.stubs(:overdue).with(assignments,user,session,submissions).
          returns []
      end

      it "stores the past assignments" do
        sorted_assignments.past.should == SortsAssignments.past(assignments)
      end

      it "stores the undated assignments" do
        sorted_assignments.undated.should ==
          SortsAssignments.undated(assignments)
      end

      it "stores the ungraded assignments" do
        sorted_assignments.ungraded.should ==
          SortsAssignments.ungraded_for_user_and_session(
            assignments,user,session
        )
      end

      it "stores the upcoming assignments" do
        sorted_assignments.upcoming.should ==
          SortsAssignments.upcoming(assignments,1.week.from_now)
      end

      it "stores the future events" do
        sorted_assignments.future.should == SortsAssignments.future(assignments)
      end

      it "returns the overdue assignments" do
        sorted_assignments.overdue.should == SortsAssignments.overdue(assignments, user, session, submissions)
      end

    end

  end

  describe "without_graded_submission" do
    let(:submission1) {stub(:assignment_id => due_yesterday.id,
                           :without_graded_submission? => false)}
    let(:submission2) {stub(:assignment_id => due_today.id,
                           :without_graded_submission? => false)}
    let(:submissions) { [ submission1, submission2 ] }
    let(:assignments) { [ due_yesterday, due_today ] }

    it "returns assignments that don't have a matching submission in the "+
      "passed submissions collection" do
      submission1.stubs(:assignment_id => nil )
      SortsAssignments.without_graded_submission(assignments,submissions).
        should =~ [ due_yesterday ]
    end

    it "returns assignments that have a matching submission in the collection "+
      "but the submission is without a graded submission." do
      submission1.expects(:without_graded_submission?).returns true
      SortsAssignments.without_graded_submission(assignments,submissions).
        should =~ [ due_yesterday ]
    end

  end

  describe "user_allowed_to_submit" do
    let(:session) {stub}
    let(:user) {stub}

    before :each do
      assignments.each{|assignment|
        assignment.stubs(:expects_submission?).returns true
        assignment.stubs(:grants_right?).returns false
      }
    end

    it "includes assignments where assignment not expecting a submission and "+
      "don't grant rights to user" do
      due_yesterday.expects(:expects_submission?).returns true
      due_yesterday.expects(:grants_right?).with(user,session,:submit).returns true
      SortsAssignments.user_allowed_to_submit(assignments,user,session).
        should =~ [ due_yesterday ]
    end

  end

  describe "overdue" do
    let(:session) { stub }
    let(:user) { stub }
    let(:submissions) { stub }

    it "returns the set of assignments that user is allowed to submit and "+
      "without graded submissions" do
      SortsAssignments.stubs(:past).returns [ due_yesterday ]
      SortsAssignments.stubs(:user_allowed_to_submit).returns [ due_yesterday ]
      SortsAssignments.stubs(:without_graded_submission).returns [ due_yesterday ]
      SortsAssignments.overdue(assignments,user,session,submissions).should == [due_yesterday]
    end

  end

end
