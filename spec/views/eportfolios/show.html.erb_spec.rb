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

describe "/eportfolios/show" do
  before do
    eportfolio_with_user
    view_portfolio
    assigns[:category] = category = @portfolio.eportfolio_categories.create!(:name => "some category")
    assigns[:categories] = [category]
    assigns[:recent_submissions] = []
    assigns[:folders] = []
    assigns[:files] = []
    assigns[:page] = @portfolio.eportfolio_entries.create!(:name => "some entry", :eportfolio_category => category)
  end

  it "should render" do
    render "eportfolios/show"
    expect(response).not_to be_nil
  end

  it "should not link the user name if @owner_url is not set" do
    render "eportfolios/show"
    expect(view.content_for(:left_side)[/<a [^>]*id="section-tabs-header-subtitle"/]).to be_nil
    expect(view.content_for(:left_side)[/<span [^>]*id="section-tabs-header-subtitle"/]).not_to be_nil
  end

  it "should link the user name if @owner_url is set" do
    assigns[:owner_url] = owner_url = user_url(@portfolio.user)
    render "eportfolios/show"
    expect(view.content_for(:left_side)[owner_url]).not_to be_nil
    expect(view.content_for(:left_side)[/<a [^>]*id="section-tabs-header-subtitle"/]).not_to be_nil
    expect(view.content_for(:left_side)[/<span [^>]*id="section-tabs-header-subtitle"/]).to be_nil
  end

  it "should show the share link explicitly" do
    assigns[:owner_view] = true
    render "eportfolios/show"
    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css('#eportfolio_share_link').text).to match %r{https?://.*/eportfolios/#{@portfolio.id}\?verifier=.*}
  end

  it "shows the right submission preview link" do
    course_with_student(user: @user)
    submission_model(course: @course, user: @user)
    assigns[:owner_view] = true
    render "eportfolios/show"
    doc = Nokogiri::HTML.parse(response.body)
    expect(doc.at_css("#recent_submission_#{@submission.id} .view_submission_url").attributes['href'].value).to match(
      %r{/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}}
    )
  end
end
