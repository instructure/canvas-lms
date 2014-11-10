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

describe "/wiki_pages/show" do
  before do
    course_with_student
    view_context
    assigns[:wiki] = @course.wiki
    assigns[:page] = assigns[:wiki].front_page
    assigns[:page].body = "my awesome content"
    assigns[:page].save!
    assigns[:context] = @course
  end

  it "should render" do
    render "wiki_pages/show"
    doc = Nokogiri::HTML(response.body)
    expect(doc.css('#wiki_body').text.index(assigns[:page].body)).not_to be_nil
  end

  it "should not render user content when editing" do
    assigns[:editing] = true
    render "wiki_pages/show"

    doc = Nokogiri::HTML(response.body)
    expect(doc.css('#wiki_body').text.index(assigns[:page].body)).to be_nil
    expect(doc.css('#wiki_body').text.index('Editing Content')).not_to be_nil
  end
end

