#
# Copyright (C) 2011-2012 Instructure, Inc.
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

describe "/collaborations/index" do
  before do
    course_with_student
    view_context(@course, @user)
    assigns[:collaborations] = [@course.collaborations.create!(user: @user, title: "my collab!")]
  end

  it "should render" do
    render 'collaborations/index'
    expect(response).not_to be_nil
  end

  it "should provide labels for accessibility devices i.e. screen readers" do
    render :partial => "collaborations/forms"
    expect(response).not_to be_nil
    expect(response).to have_tag("label[for=collaboration_title]", :text => "Document name:")
    expect(response).to have_tag("label[for=collaboration_description]", :text => "Description:")
    expect(response).to have_tag("label[for=collaboration_collaboration_type]", :text => "Collaborate using:")
  end
end

