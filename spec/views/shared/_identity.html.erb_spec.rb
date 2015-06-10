#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/shared/_identity" do
  it "should render" do
    Setting.set('show_feedback_link', 'true')
    course_with_student
    view_context
    render :partial => "shared/identity"
    expect(@controller.response).to be_success
  end

  it "should render without a current user" do
    Setting.set('show_feedback_link', 'true')
    course_with_student
    view_context
    assigns.delete(:current_user)
    render :partial => "shared/identity"
    expect(@controller.response).to be_success
  end
end

