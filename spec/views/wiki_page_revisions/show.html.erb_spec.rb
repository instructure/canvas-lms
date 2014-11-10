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

describe "/wiki_page_revisions/show" do
  before do
    course_with_student
    view_context
    assigns[:wiki] = @course.wiki
    assigns[:page] = assigns[:wiki].front_page
    assigns[:page].save!
  end
  it "should say imported for no user edit" do
    assigns[:revision] = assigns[:page].versions.first
    render "wiki_page_revisions/show"
    expect(response.body).to match /Imported:/
  end
  it "should say username of editor" do
    assigns[:page].update_attributes(:body => "oi", :user_id => @user.id)
    assigns[:revision] = assigns[:page].versions[0]
    render "wiki_page_revisions/show"
    expect(response.body).to match /Saved: .* by #{@user.name}/
  end
end

