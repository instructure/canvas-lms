# frozen_string_literal: true

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

require_relative "../views_helper"

describe "eportfolios/show" do
  before do
    assign(:domain_root_account, Account.default)
    eportfolio_with_user
    view_portfolio
    category = assign(:category, @portfolio.eportfolio_categories.create!(name: "some category"))
    assign(:categories, [category])
    assign(:recent_submissions, @portfolio.user.submissions.in_workflow_state(["submitted", "graded"]))
    assign(:folders, [])
    assign(:files, [])
    assign(:page, @portfolio.eportfolio_entries.create!(name: "some entry", eportfolio_category: category))
  end

  it "renders" do
    render "eportfolios/show"
    expect(response).not_to be_nil
  end

  it "shows the share link explicitly" do
    assign(:owner_view, true)
    render "eportfolios/show"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css("#eportfolio_share_link").text).to match %r{https?://.*/eportfolios/#{@portfolio.id}\?verifier=.*}
  end

  it "does not show submissions unless submission is submitted" do
    course_with_student(user: @user, active_all: true)
    submission_model(course: @course, user: @user)
    assign(:owner_view, true)
    render "eportfolios/show"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css("#recent_submission_#{@submission.id} .view_submission_url")).to be_nil
  end

  it "does not show submissions that are pending review" do
    course_with_student(user: @user, active_all: true)
    submission_model(course: @course, user: @user)
    assign(:owner_view, true)
    @submission.update_column("workflow_state", "pending_review")
    render "eportfolios/show"
    doc = Nokogiri::HTML5(response.body)
    expect(doc.at_css("#recent_submission_#{@submission.id} .view_submission_url")).to be_nil
  end
end
