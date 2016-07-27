require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Authenticity Tokens" do
  include_context "in-process server selenium tests"

  it "should change the masked authenticity token on each request but not the unmasked token", priority: "1", test_id: 296921 do
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

  it "should change the unmasked token on logout", priority: "1", test_id: 296922 do
    user_logged_in
    get('/')
    token = driver.execute_script "return $.cookie('_csrf_token')"
    expect_new_page_load(:accept_alert) { expect_logout_link_present.click }
    token2 = driver.execute_script "return $.cookie('_csrf_token')"
    expect(token).not_to eq token2
    expect(CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token)).not_to eq(
        CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token2)
    )
  end
end
