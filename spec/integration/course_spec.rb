#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "course" do

  # normally this would be a controller test, but there is a some code in the
  # views that i need to not explode
  it "should not require authorization for public courses" do
    course(:active_all => true)
    @course.update_attribute(:is_public, true)
    get "/courses/#{@course.id}"
    response.should be_success
  end

  it "should load syllabus on public course with no user logged in" do
    course(:active_all => true)
    @course.update_attribute(:is_public, true)
    get "/courses/#{@course.id}/assignments/syllabus"
    response.should be_success
  end
end
