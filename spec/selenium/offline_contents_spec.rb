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

require_relative 'common'
require_relative 'offline_contents_common'

describe "offline contents" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:epub_export)
    @course1 = course_model(name: 'First Course')
    @course1.offer!
    @course1.enable_feature!(:epub_export)
  end

  context "as a teacher" do
    before :each do
      @teacher1 = user_with_pseudonym(:username => 'teacher1@example.com', :active_all => 1)
      @course1.enroll_teacher(@teacher1).accept!
      user_session(@teacher1)
    end

    it_behaves_like 'show courses for ePub generation', :teacher
    it_behaves_like 'generate and download ePub', :teacher
  end

  context "as a student" do
    before :each do
      @student1 = user_with_pseudonym(:username => 'student1@example.com', :active_all => 1)
      @course1.enroll_student(@student1).accept!
      user_session(@student1)
    end

    it_behaves_like 'show courses for ePub generation', :student
    it_behaves_like 'generate and download ePub', :student
  end
end

