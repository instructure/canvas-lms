#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../../spec_helper'
require_relative '../views_helper'

describe "shared/_flash_notices" do
  def local_options(overrides={})
    {
      with_login_text: 'Login with Facebook',
      auth_type: 'facebook',
      sr_message: nil
    }.merge(overrides)
  end

  it "puts login text with the button if flagged" do
    render partial: "shared/auth_type_icon", locals: local_options
    expect(rendered).to match("Login with Facebook")
  end

  it "just uses the icon if flagged to not use login text" do
    render partial: "shared/auth_type_icon", locals: local_options(with_login_text: nil)
    expect(rendered).to_not match("Login with Facebook")
  end

  it "renders a screenreader message if provided" do
    render partial: "shared/auth_type_icon", locals: local_options(sr_message: "SR_ONLY")
    expect(rendered).to match("<span class=\"screenreader-only\">SR_ONLY")
  end

  it "omits screenreader span if no message provided" do
    render partial: "shared/auth_type_icon", locals: local_options(sr_message: nil)
    expect(rendered).to_not match("<span class=\"screenreader-only\">")
  end

  it "uses the button icon based on auth type" do
    render partial: "shared/auth_type_icon", locals: local_options(auth_type: 'twitter')
    doc = Nokogiri::HTML(response.body)
    expect(doc.css('svg.ic-icon-svg--twitter')).to be_present
  end

end
