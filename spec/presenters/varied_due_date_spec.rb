require File.expand_path(File.dirname(__FILE__) +
                         "/../../spec/spec_helper.rb")

describe VariedDueDate do
  let(:vdd) { VariedDueDate.new(assignment, user) }
  let(:today) { Date.today }
  let(:tomorrow) { Date.today.next }
  let(:assignment) { Assignment.new }
  let(:user) { stub() }
  let(:student_due_date) { {:due_at => today} }
  let(:admin_due_dates) { [{:due_at => tomorrow}]}


  describe "initialize" do
    before do
      assignment.expects(:due_dates_for => [student_due_date, admin_due_dates])
    end

    specify { vdd.assignment.should == assignment }
    specify { vdd.user.should == user }
    specify { vdd.student_due_date.should == student_due_date }
    specify { vdd.admin_due_dates.should == admin_due_dates }
  end

  describe "multiple?" do

    it "returns false by default" do
      vdd.multiple?.should be_false
    end

    it "returns false if the admin list is nil" do
      vdd.admin_due_dates = nil
      vdd.multiple?.should be_false
    end

    it "returns false if the admin list is empty" do
      vdd.admin_due_dates = []
      vdd.multiple?.should be_false
    end

    it "returns false if the admin list contains one due date" do
      vdd.admin_due_dates = [{:due_at => today}]
      vdd.multiple?.should be_false
    end

    it "returns true if the admin list contains multiple due dates" do
      vdd.admin_due_dates = \
        [{:due_at => today}, {:due_at => tomorrow }]
      vdd.multiple?.should be_true
    end

    it "returns false if second list has a length of 1 and the due_date on " +
      "that object is the same as due_date on first value" do

      vdd.student_due_date = {:due_at => today }
      vdd.admin_due_dates = [
        { :due_at => Date.today }
      ]
      vdd.multiple?.should be_false
    end

    it "returns true if second list not null and has at least 1 due_at" +
      "different than the student's due_at" do
      vdd.student_due_date = {:due_at => today }
      vdd.admin_due_dates = [
        { :due_at => today },
        { :due_at => tomorrow }
      ]
      vdd.multiple?.should be_true
    end

    it "returns false if no student_due_date and second list has no unique " +
      "due dates" do
      vdd.student_due_date = nil
      vdd.admin_due_dates = [
        { :due_at => today },
        { :due_at => today }
      ]
      vdd.multiple?.should be_false
    end
  end

  describe "all_due_dates" do
    let(:student_due_date) { {:due_at => today} }
    let(:admin_due_dates) { [{:due_at => tomorrow}]}

    it "concatenates the lists of student and admin due dates" do
      vdd.student_due_date = student_due_date
      vdd.admin_due_dates = admin_due_dates
      vdd.all_due_dates.should == [student_due_date, admin_due_dates.first]
    end
  end

  describe "all_due_at" do
    before do
      vdd.stubs(:all_due_dates => [{:due_at => today}, {:due_at => tomorrow}])
    end

    specify { vdd.all_due_at.should == [today, tomorrow] }
  end

  describe "unique_due_at" do
    before do
      vdd.stubs(:all_due_at => [today, tomorrow, today, tomorrow])
    end

    specify { vdd.unique_due_at.should == [today, tomorrow] }
  end

  describe "#earliest_due_at" do
    subject { vdd.earliest_due_at }

    context "by default" do
      it { should be_nil }
    end

    context "with a couple of due dates" do
      before { vdd.stubs(:unique_due_at => [tomorrow, today]) }
      it { should == today }
    end

    context "with a nil due date in the list" do
      before { vdd.stubs(:unique_due_at => [nil, tomorrow]) }
      it { should == tomorrow }
    end
  end

  describe "due_at" do
    it "returns the latest due date" do
      vdd.stubs(:latest_due_at => today)
      vdd.due_at.should == today
    end
  end

  describe "all_due_at" do
    it "collects all the :due_at parameters" do
      vdd.stubs :all_due_dates =>
        [{:due_at => tomorrow}, {:due_at => today}, {:due_at => nil}]

      vdd.all_due_at.should == [tomorrow, today, nil]
    end
  end
end
