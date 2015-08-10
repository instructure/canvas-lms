require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/context/_roster_right_side" do
  it "should render with an account as context" do
    view_context(Account.default)
    render :partial => "context/roster_right_side"
    expect(response).not_to be_nil
  end
end
