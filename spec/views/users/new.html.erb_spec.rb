#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "/users/new" do
  it "should render" do
    course_with_student
    view_context
    terms_of_service_content = TermsOfServiceContent.create!(content: "default content")
    terms_of_service = TermsOfService.create!(terms_type: "default",
                                               terms_of_service_content: terms_of_service_content,
                                               account: @course.account)
    assign(:user, User.new)
    assign(:pseudonym, Pseudonym.new)

    render "users/new"
    expect(response).not_to be_nil
  end
end

