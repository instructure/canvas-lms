#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

class Enrollment
  describe RecentActivity do
    describe "initialization" do
      let(:context) { stub('enrollment context') }
      let(:enrollment) { stub(context: context) }

      it "defaults to the enrollments context" do
        expect(RecentActivity.new(enrollment).context).to eq(context)
      end

      it "can be passed a context" do
        override = stub("other context")
        expect(RecentActivity.new(enrollment, override).context).to eq(override)
      end
    end

    describe "recording updates" do
      before(:once) { course_with_student(:active_all => 1) }
      let(:recent_activity) { Enrollment::RecentActivity.new(@enrollment) }
      let(:now){ Time.zone.now }
      before(:each){ @enrollment.last_activity_at.should be_nil }

      describe "#record!" do
        it "should record on the first call (last_activity_at is nil)" do
          recent_activity.record!
          @enrollment.last_activity_at.should_not be_nil
        end

        it "should not record anything within the time threshold" do
          recent_activity.record!(now)
          recent_activity.record!(now + 1.minutes)
          @enrollment.last_activity_at.to_s.should == now.to_s
        end

        it "should record again after the threshold is done" do
          recent_activity.record!(now)
          recent_activity.record!(now + 11.minutes)
          @enrollment.last_activity_at.should.to_s == (now + 11.minutes).to_s
        end

        it "should update total_activity_time within the time threshold" do
          @enrollment.total_activity_time.should == 0
          recent_activity.record!(now)
          recent_activity.record!(now + 1.minutes)
          @enrollment.total_activity_time.should == 0
          recent_activity.record!(now + 3.minutes)
          @enrollment.total_activity_time.should == 3.minutes.to_i
          recent_activity.record!(now + 30.minutes)
          @enrollment.total_activity_time.should == 3.minutes.to_i
        end
      end

      describe "#record_for_access" do
        it "records activity for a positive response" do
          response = stub(response_code: 200)
          recent_activity.record_for_access(response)
          @enrollment.last_activity_at.should_not be_nil
        end

        it "skips recording for 4xx or 5xx errors" do
          recent_activity.record_for_access(stub(response_code: 401))
          @enrollment.last_activity_at.should be_nil
          recent_activity.record_for_access(stub(response_code: 500))
          @enrollment.last_activity_at.should be_nil
          recent_activity.record_for_access(stub(response_code: 567))
          @enrollment.last_activity_at.should be_nil
          recent_activity.record_for_access(stub(response_code: 234))
          @enrollment.last_activity_at.should_not be_nil
        end

        it "skips recording for non-course contexts" do
          local_activity = Enrollment::RecentActivity.new(@enrollment, Account.new)
          local_activity.record_for_access(stub(response_code: 200))
          @enrollment.last_activity_at.should be_nil
        end
      end
    end
  end
end
