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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/context_modules/url_show" do
  it "should render" do
    course
    view_context(@course, @user)
    @module = @course.context_modules.create!(:name => 'teh module')
    @tag = @module.add_item(:type => 'external_url',
                            :url => 'http://example.com/lolcats',
                            :title => 'pls view')
    assigns[:module] = @module
    assigns[:tag] = @tag
    render 'context_modules/url_show'
    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css('iframe')['src']).to eq 'http://example.com/lolcats'
    expect(doc.css('a').collect{ |a| [a['href'], a.inner_text] }).to be_include ['http://example.com/lolcats', 'pls view']
  end

  it "should check whether the content is locked" do
    course
    view_context(@course, @user)
    @module = @course.context_modules.create!(:name => 'locked module',
                                              :unlock_at => 1.week.from_now)
    @tag = @module.add_item(:type => 'external_url',
                            :url => 'http://example.com/lolcats',
                            :title => 'pls view')
    assigns[:module] = @module
    assigns[:tag] = @tag
    render 'context_modules/url_show'
    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css('h2').inner_text).to eq 'pls view'
    expect(doc.at_css('b').inner_text).to eq 'locked module'
    expect(doc.at_css('#module_prerequisites_lookup_link')['href']).to eq(
        "/courses/#{@course.id}/modules/#{@module.id}/prerequisites/content_tag_#{@tag.id}"
    )
    expect(doc.css('iframe')).to be_empty
  end
end
