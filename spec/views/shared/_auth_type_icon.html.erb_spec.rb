require_relative '../../spec_helper'
require_relative '../views_helper'

describe "/shared/_flash_notices" do
  def local_options(overrides={})
    {
      with_login_text: true,
      auth_type: 'facebook',
      sr_message: nil
    }.merge(overrides)
  end

  it "puts login text with the button if flagged" do
    render partial: "shared/auth_type_icon", locals: local_options(with_login_text: true)
    expect(rendered).to match("Login with <span class=\"ic-Login__sso-button__title")
  end

  it "just uses the icon if flagged to not use login text" do
    render partial: "shared/auth_type_icon", locals: local_options(with_login_text: false)
    expect(rendered).to_not match("Login with <span class=\"ic-Login__sso-button__title")
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
