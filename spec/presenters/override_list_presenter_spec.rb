require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OverrideListPresenter do
  include TextHelper
  before do
    AssignmentOverrideApplicator.stubs(:assignment_overridden_for).
      with(assignment,user).returns overridden_assignment
    AssignmentOverrideApplicator.stubs(:assignment_overridden_for).
      with(assignment,nil).returns assignment
    assignment.stubs(:has_active_overrides?).returns true
  end

  around do |example|
    Timecop.freeze(Time.zone.local(2013,3,13,0,0), &example)
  end

  let(:assignment) { Assignment.new :title => "Testing" }
  let(:user) { User.new :name => "Testing" }
  let(:overridden_assignment) { assignment }
  let(:presenter) { OverrideListPresenter.new assignment,user }


  describe "#initialize" do

    it "keeps a reference to the user" do
      presenter = OverrideListPresenter.new nil,user
      expect(presenter.user).to eq user
    end

    context "assignment present? and user present?" do

      it "stores a reference to the overridden assignment for that user" do
        presenter = OverrideListPresenter.new assignment,user
        expect(presenter.assignment).to eq overridden_assignment
      end
    end

    context "assignment or user not present?" do

      it "stores the assignment as nil if assignment not present?" do
        presenter = OverrideListPresenter.new nil,user
        expect(presenter.assignment).to eq nil
        expect(presenter.user).to eq user
      end
    end

  end

  describe "#formatted_date_string" do

    context "due_at" do
      it "returns - if due_at isn't present" do
        due_date_hash = {:due_at => nil }
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq '-'
        due_date_hash[:due_at] = ""
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq '-'
      end

      it "returns a shortened version with just the date if time is 11:59" do
        fancy_midnight = CanvasTime.fancy_midnight Time.zone.now
        due_date_hash = {:due_at => fancy_midnight }
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq(
          date_string(fancy_midnight, :no_words)
        )
      end

      it "returns returns datetime_string if not all day but date present" do
        due_date_hash = {:due_at => Time.now }
        expect(presenter.formatted_date_string(:due_at, due_date_hash)).to eq(
          datetime_string(Time.now)
        )
      end
    end

    context "lock_at and unlock_at" do
      it "returns returns datetime_string of not all day but date present" do
        due_date_hash = {:lock_at => Time.now, :unlock_at => Time.now - 1.day }
        expect(presenter.formatted_date_string(:lock_at, due_date_hash)).to eq(
          datetime_string(Time.now)
        )
        expect(presenter.formatted_date_string(:unlock_at, due_date_hash)).to eq(
          datetime_string(Time.now - 1.day)
        )
      end

      it "returns - if due_at isn't present" do
        due_date_hash = {:lock_at => nil }
        expect(presenter.formatted_date_string(:lock_at , due_date_hash)).to eq '-'
        due_date_hash[:lock_at] = ""
        expect(presenter.formatted_date_string(:lock_at, due_date_hash)).to eq '-'
        due_date_hash = {:unlock_at => nil }
        expect(presenter.formatted_date_string(:unlock_at , due_date_hash)).to eq '-'
        due_date_hash[:unlock_at] = ""
        expect(presenter.formatted_date_string(:unlock_at, due_date_hash)).to eq '-'
      end

      it "never takes all_day into effect" do
        due_date_hash = {:lock_at => Time.now, :all_day => true }
        expect(presenter.formatted_date_string(:lock_at, due_date_hash)).to eq(
          datetime_string(Time.now)
        )
        due_date_hash = {:unlock_at => Time.now, :all_day => true }
        expect(presenter.formatted_date_string(:unlock_at, due_date_hash)).to eq(
          datetime_string(Time.now)
        )
      end
    end
  end

  describe "#multiple_due_dates?" do
    it "returns the result of assignment.multiple_due_dates_apply_to?(user)" do
      assignment.expects(:has_active_overrides?).returns true
      expect(presenter.multiple_due_dates?).to eq true
      assignment.expects(:has_active_overrides?).returns false
      expect(presenter.multiple_due_dates?).to eq false
    end

    it "returns false if its assignment is nil" do
      presenter = OverrideListPresenter.new nil,user
      expect(presenter.multiple_due_dates?).to eq false
    end
  end

  describe "#due_for" do
    it "returns the due date's title if it is present?" do
      due_date = {:title => "default"}
      expect(presenter.due_for(due_date)).to eq 'default'
    end

    it "returns 'Everyone else' if multiple due dates for assignment" do
      assignment.expects(:has_active_overrides?).once.returns true
      due_date = {}
      expect(presenter.due_for(due_date)).to eq(
        I18n.t('overrides.everyone_else','Everyone else')
      )
    end

    it "returns 'Everyone' translated if not multiple due dates" do
      assignment.expects(:has_active_overrides?).once.returns false
      due_date = {}
      expect(presenter.due_for(due_date)).to eq(
        I18n.t('overrides.everyone', 'Everyone')
      )
    end
  end

  describe "#visible_due_dates" do
      def visible_due_dates; @visible_due_dates; end
      let(:sections) do
        # the count is the important part, the actual course sections are
        # not used
        [ stub, stub, stub ]
      end

      def dates_visible_to_user
        [
          {:due_at => "", :lock_at => nil, :unlock_at => nil, :set_type => 'CourseSection'},
          {:due_at => Time.now + 1.day, :lock_at => nil, :unlock_at => nil, :set_type => 'CourseSection'},
          {:due_at => Time.now + 2.days, :lock_at => nil, :unlock_at => nil, :set_type => 'CourseSection'},
          {:due_at => Time.now - 2.days, :lock_at => nil, :unlock_at => nil, :base => true}
        ]
      end

    it "returns empty array if assignment is not present" do
      presenter = OverrideListPresenter.new nil,user
      expect(presenter.visible_due_dates).to eq []
    end

    context "when all sections have overrides" do

      before do
        assignment.stubs(:context).
          returns stub(:active_section_count => sections.count)
        assignment.stubs(:all_dates_visible_to).with(user).
          returns dates_visible_to_user
        @visible_due_dates = presenter.visible_due_dates
      end

      it "doesn't include the default due date" do
        expect(visible_due_dates.length).to eq 3
        visible_due_dates.each do |override|
          expect(override[:base]).not_to be_truthy
        end
      end

      it "sorts due dates by due_at, placing not present?/nil after dates" do
        expect(visible_due_dates.first[:due_at]).to eq(
          presenter.formatted_date_string(:due_at, dates_visible_to_user.second)
        )
        expect(visible_due_dates.second[:due_at]).to eq(
          presenter.formatted_date_string(:due_at,dates_visible_to_user.third)
        )
        expect(visible_due_dates.third[:due_at]).to eq(
          presenter.formatted_date_string(:due_at,dates_visible_to_user.first)
        )
      end

      it "includes the actual Time for presentation transforms in templates" do
        expect(visible_due_dates.second[:raw][:due_at]).to be_a(Time)
      end

    end

    context "only some sections have overrides" do
      let(:dates_visible) { dates_visible_to_user[1..-1] }

      before do
        assignment.stubs(:context).
          returns stub(:active_section_count => sections.count)
        assignment.stubs(:all_dates_visible_to).with(user).
          returns dates_visible
        @visible_due_dates = presenter.visible_due_dates
      end

      it "includes the default due date" do
        expect(visible_due_dates.detect { |due_date| due_date[:base] == true }).
          not_to be_nil
      end
    end

  end

end
