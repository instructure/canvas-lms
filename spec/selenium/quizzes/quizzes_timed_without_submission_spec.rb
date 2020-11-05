# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'taking a timed quiz without auto-submit' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  context 'as a teacher' do
    before(:each) do
      Account.site_admin.allow_feature! :timer_without_autosubmission
      Account.default.enable_feature! :timer_without_autosubmission

      course_with_teacher_logged_in
      create_quiz_with_due_date
    end

    it "the checkbox is saved and enabled", priority: "3" do
      @quiz.time_limit = 3
      @quiz.disable_timer_autosubmission = true
      @quiz.save!
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      expect(f('#quiz_disable_timer_autosubmission')).to be
    end
  end
end
