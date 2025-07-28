# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
describe "layouts/application" do
  before do
    @current_user = user_factory
    assign(:current_user, @current_user)
    assign(:domain_root_account, Account.default)
  end

  def doc
    Nokogiri::HTML5(response.body)
  end

  it "renders" do
    render "layouts/application"
    expect(doc.at_css(".ic-app.content-only")).to be_nil
  end

  context "with content_only=true" do
    before do
      allow(controller).to receive(:params).and_return({ content_only: "true" })
    end

    it "adds content-only class to application" do
      render "layouts/application"
      expect(doc.at_css(".ic-app.content-only")).to be_present
    end
  end

  context "with @show_footer" do
    it "shows footer when true" do
      assign(:show_footer, true)
      render "layouts/application"
      expect(doc.at_css("#footer.ic-app-footer")).to be_present
    end

    it "hides footer when false" do
      assign(:show_footer, false)
      render "layouts/application"
      expect(doc.at_css("#footer")).to be_nil
    end

    it "hides footer when content_only=true regardless of @show_footer" do
      assign(:show_footer, true)
      allow(controller).to receive(:params).and_return({ content_only: "true" })
      render "layouts/application"
      expect(doc.at_css("#footer")).to be_nil
    end
  end

  context "with @instui_topnav" do
    it "shows topnav when true" do
      assign(:instui_topnav, true)
      render "layouts/application"
      container = doc.at_css(".instui-topnav-container")
      expect(container).to be_present
      expect(container.at_css("#react-instui-topnav")).to be_present
    end

    it "hides topnav when false" do
      assign(:instui_topnav, false)
      render "layouts/application"
      expect(doc.at_css(".instui-topnav-container")).to be_nil
    end

    it "hides topnav when content_only=true regardless of @instui_topnav" do
      assign(:instui_topnav, true)
      allow(controller).to receive(:params).and_return({ content_only: "true" })
      render "layouts/application"
      expect(doc.at_css(".instui-topnav-container")).to be_nil
    end

    context "with crumbs" do
      before do
        assign(:instui_topnav, false)
        @context = course_factory
        assign(:context, @context)

        # Mock crumbs.length to show the navigation container
        crumbs_html = "<a href='/'>Home</a><a href='/courses'>Courses</a>"
        # rubocop:disable Rails/OutputSafety
        allow(view).to receive_messages(
          crumbs: [["Home", "/"], ["Courses", "/courses"]],
          render_crumbs: crumbs_html.html_safe
        )
        # rubocop:enable Rails/OutputSafety
      end

      it "shows crumbs when topnav is disabled" do
        render "layouts/application"
        nav = doc.at_css(".ic-app-nav-toggle-and-crumbs")
        expect(nav).to be_present

        crumbs_div = nav.at_css(".ic-app-crumbs")
        expect(crumbs_div).to be_present
      end

      it "hides crumbs when content_only=true" do
        allow(controller).to receive(:params).and_return({ content_only: "true" })
        render "layouts/application"
        expect(doc.at_css(".ic-app-nav-toggle-and-crumbs")).to be_nil
      end
    end
  end
end
