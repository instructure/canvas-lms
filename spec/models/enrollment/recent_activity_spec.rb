# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class Enrollment
  describe RecentActivity do
    describe "initialization" do
      let(:context) { double("enrollment context") }
      let(:enrollment) { double(context:) }

      it "defaults to the enrollments context" do
        expect(RecentActivity.new(enrollment).context).to eq(context)
      end

      it "can be passed a context" do
        override = double("other context")
        expect(RecentActivity.new(enrollment, override).context).to eq(override)
      end
    end

    describe "recording updates" do
      before(:once) { course_with_student(active_all: 1) }

      let(:recent_activity) { Enrollment::RecentActivity.new(@enrollment) }
      let(:now) { Time.zone.now }

      describe "#record!" do
        it "records on the first call (last_activity_at is nil)" do
          recent_activity.record!
          expect(@enrollment.last_activity_at).not_to be_nil
        end

        it "does not record anything within the time threshold" do
          recent_activity.record!(now)
          recent_activity.record!(now + 1.minute)
          expect(@enrollment.last_activity_at.to_s).to eq now.to_s
        end

        it "records again after the threshold is done" do
          recent_activity.record!(now)
          recent_activity.record!(now + 11.minutes)
          expect(@enrollment.last_activity_at.to_s).to eq (now + 11.minutes).to_s
        end

        it "updates total_activity_time within the time threshold" do
          expect(@enrollment.total_activity_time).to eq 0
          recent_activity.record!(now)
          recent_activity.record!(now + 1.minute)
          expect(@enrollment.total_activity_time).to eq 0
          recent_activity.record!(now + 3.minutes)
          expect(@enrollment.total_activity_time).to eq 3.minutes.to_i
          recent_activity.record!(now + 30.minutes)
          expect(@enrollment.total_activity_time).to eq 3.minutes.to_i
        end

        it "updates total_activity_time based on the maximum" do
          section2 = @course.course_sections.create!
          enrollment2 = @course.enroll_student(@student, allow_multiple_enrollments: true, section: section2)
          Enrollment.where(id: enrollment2).update_all(total_activity_time: 39.minutes.to_i)

          expect(@enrollment.total_activity_time).to eq 0
          recent_activity.record!(now)
          recent_activity.record!(now + 3.minutes)
          expect(@enrollment.total_activity_time).to eq 42.minutes.to_i
        end
      end

      describe "#record_for_access" do
        it "records activity for a positive response" do
          response = double(response_code: 200)
          recent_activity.record_for_access(response)
          expect(@enrollment.last_activity_at).not_to be_nil
        end

        it "skips recording for 4xx or 5xx errors" do
          recent_activity.record_for_access(double(response_code: 401))
          expect(@enrollment.last_activity_at).to be_nil
          recent_activity.record_for_access(double(response_code: 500))
          expect(@enrollment.last_activity_at).to be_nil
          recent_activity.record_for_access(double(response_code: 567))
          expect(@enrollment.last_activity_at).to be_nil
          recent_activity.record_for_access(double(response_code: 234))
          expect(@enrollment.last_activity_at).not_to be_nil
        end

        it "skips recording for non-course contexts" do
          local_activity = Enrollment::RecentActivity.new(@enrollment, Account.new)
          local_activity.record_for_access(double(response_code: 200))
          expect(@enrollment.last_activity_at).to be_nil
        end
      end
    end
  end
end
