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

  context "associations" do
    it "should belong to a course" do
      association = GradingPeriod.reflect_on_association(:course)
      expect(association.macro).to eq :belongs_to
    end

    it "should belong to an account" do
      association = GradingPeriod.reflect_on_association(:account)
      expect(association.macro).to eq :belongs_to
    end
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
end
