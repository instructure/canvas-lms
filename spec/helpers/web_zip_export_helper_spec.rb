# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe WebZipExportHelper do
  include WebZipExportHelper

  before :once do
    course_with_student(active_all: true)
    @context = @course
  end

  describe "#course_allow_web_export_download?" do
    it "returns setting" do
      expect(course_allow_web_export_download?).to be false
      account = @context.account
      account.settings[:enable_offline_web_export] = true
      account.save!
      @context.reload
      expect(course_allow_web_export_download?).to be true
    end
  end

  describe "#allow_web_export_for_course_user?" do
    it "returns true for admins" do
      @current_user = account_admin_user
      expect(allow_web_export_for_course_user?).to be true
    end

    it "returns true for current course users" do
      @current_user = @student
      expect(allow_web_export_for_course_user?).to be true
    end

    it "returns false for anonymous users" do
      @current_user = nil
      expect(allow_web_export_for_course_user?).to be false
    end

    it "returns false for concluded users without access to the course" do
      @current_user = @student
      @context.start_at = 2.days.ago
      @context.conclude_at = 1.day.ago
      @context.restrict_student_past_view = true
      @context.restrict_enrollments_to_course_dates = true
      @context.save!
      expect(allow_web_export_for_course_user?).to be false
    end
  end

  describe "#allow_web_export_download?" do
    it "returns true if setting is enabled and user can export" do
      account = @context.account
      account.settings[:enable_offline_web_export] = true
      account.save!

      @current_user = @student
      expect(allow_web_export_download?).to be true
    end
  end
end
