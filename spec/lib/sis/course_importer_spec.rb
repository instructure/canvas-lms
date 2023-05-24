# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module SIS
  describe CourseImporter do
    context "#add_course" do
      it "republishes course paces if appropriate" do
        @account = Account.default
        @account.enable_feature!(:course_paces)

        @course = Course.create!(account: @account, sis_source_id: "SIS_ID", short_name: "C001")
        @course.enable_course_paces = true
        @course.save!

        @course_pace = course_pace_model(course: @course)

        importer = SIS::CourseImporter::Work.new(@account.sis_batches.create!, @account, Rails.logger, nil, nil, [], nil, {})
        importer.add_course("SIS_ID",
                            EnrollmentTerm.first.id,
                            @account.sis_source_id,
                            "fallback_account_id",
                            "active",
                            "start_date",
                            "end_date",
                            "abstract_course_id",
                            "C001",
                            "long_name",
                            "integration_id",
                            "on_campus",
                            "blueprint_course_id",
                            "not_set",
                            "homeroom_course",
                            "friendly_name")

        expect(Progress.find_by(context: @course_pace)).to be_queued
      end
    end
  end
end
