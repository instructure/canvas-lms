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

require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_context "public course as a logged out user" do
  def ensure_logged_out
    destroy_session
  end

  def validate_selector_displayed(selector)
    expect(f(selector)).to be_truthy
  end

  let!(:public_course) do
    course_factory(active_course: true)
    @course.is_public = true
    @course.save!
    @course
  end

  before :each do
    ensure_logged_out
  end
end
