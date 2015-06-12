require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Authenticity Tokens" do
  include_examples "in-process server selenium tests"

  it "should change the masked authenticity token on each request but not the unmasked token" do
    user_logged_in
    get('/')
    token = driver.execute_script "return $.cookie('_csrf_token')"
    get('/')
    token2 = driver.execute_script "return $.cookie('_csrf_token')"
    expect(token).not_to eq token2
    expect(CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token)).to eq(
      CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token2)
    )
  end

  it "should change the unmasked token on logout" do
    user_logged_in
    get('/')
    token = driver.execute_script "return $.cookie('_csrf_token')"
    destroy_session(true)
    get('/')
    token2 = driver.execute_script "return $.cookie('_csrf_token')"
    expect(token).not_to eq token2
    expect(CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token)).not_to eq(
        CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token2)
    )
  end
end
