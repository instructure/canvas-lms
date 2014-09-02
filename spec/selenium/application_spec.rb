require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Authenticity Tokens" do
  include_examples "in-process server selenium tests"

  it "should change the masked authenticity token on each request but not the unmasked token" do
    user_logged_in
    get('/')
    token = driver.execute_script "return $.cookie('_csrf_token')"
    get('/')
    token2 = driver.execute_script "return $.cookie('_csrf_token')"
    token.should_not == token2
    CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token).should ==
      CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token2)
  end

  it "should change the unmasked token on logout" do
    user_logged_in
    get('/')
    token = driver.execute_script "return $.cookie('_csrf_token')"
    destroy_session(true)
    get('/')
    token2 = driver.execute_script "return $.cookie('_csrf_token')"
    token.should_not == token2
    CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token).should_not ==
        CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token2)
  end
end
