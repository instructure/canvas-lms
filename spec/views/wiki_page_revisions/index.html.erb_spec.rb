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

describe "/wiki_page_revisions/index" do
  it "should show user editing link and content import name" do
    course_with_student
    view_context
    assigns[:wiki] = WikiNamespace.default_for_context(@course).wiki
    assigns[:page] = assigns[:wiki].wiki_page
    assigns[:page].save!
    assigns[:page].update_attributes(:body => "oi", :user_id => @user.id)
    render "wiki_page_revisions/index"
    response.body.should =~ /Content Importer/
    response.body.should =~ %r{/users/#{@user.id}}
  end
end

