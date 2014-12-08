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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GradingPeriod do
  before :once do
    @grading_period = GradingPeriod.create(course_id: 1, weight: 25.0, start_date: Time.zone.now, end_date: 1.day.from_now)
  end

  context "validation" do
    it "should be valid with appropriate input" do
      expect(@grading_period).to be_valid
    end

    it "should require a weight" do
      expect(GradingPeriod.create(course_id: 1, start_date: Time.zone.now, end_date: 1.day.from_now )).to_not be_valid
    end

    it "should require a start_date" do
      expect(GradingPeriod.create(course_id: 1, weight: 25.0, end_date: 1.day.from_now)).to_not be_valid
    end

    it "should require an end_date" do
      expect(GradingPeriod.create(course_id: 1, weight: 25.0, start_date: Time.zone.now)).to_not be_valid
    end

    context "when end_date is before the start_date" do
      it "should not be able to create a grading period with end_date before the start_date" do
        expect(GradingPeriod.create(course_id: 1, weight: 25.0, start_date: 2.days.from_now, end_date: Time.zone.now)).to_not be_valid
      end

      it "should not be able to update the end_date to be before the start_date" do
        grading_period = GradingPeriod.create(course_id: 1, weight: 25.0, start_date: Time.zone.now, end_date: 1.day.from_now)
        expect(grading_period).to be_valid
        grading_period.update_attributes(end_date: 1.day.ago)
        expect(grading_period).not_to be_valid
      end

      it "should not be able to update the start_date to be after the end_date" do
        grading_period = GradingPeriod.create(course_id: 1, weight: 25.0, start_date: Time.zone.now, end_date: 1.day.from_now)
        expect(grading_period).to be_valid
        grading_period.update_attributes(start_date: 2.days.from_now)
        expect(grading_period).not_to be_valid
      end
    end
  end

  describe '#destroy' do
    it 'soft deletes' do
      @grading_period.destroy
      expect(@grading_period).to be_deleted
      expect(@grading_period).to_not be_destroyed
    end
  end

  describe '#assignments' do
    before :once do
      Account.default.set_feature_flag! :multiple_grading_periods, 'on'
      course_with_teacher active_all: true
      gpg = @course.grading_period_groups.create!
      now = Time.zone.now
      @gp1, @gp2 = 2.times.map { |n|
        gpg.grading_periods.create! start_date: n.months.since(now),
          end_date: (n+1).months.since(now),
          weight: 1
      }
      @a1, @a2 = [@gp1, @gp2].map { |gp|
        @course.assignments.create! due_at: gp.start_date + 1
      }
      # no due date goes in final grading period
      @a3 = @course.assignments.create!
    end

    it 'filters assignments for grading period' do
      expect(@gp1.assignments(@course.assignments)).to eq [@a1]
      expect(@gp2.assignments(@course.assignments)).to eq [@a2, @a3]
    end
  end
end
