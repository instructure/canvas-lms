require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Authenticity Tokens" do
  it_should_behave_like "in-process server selenium tests"

  it "should change the authenticity token on each request" do
    user_logged_in
    get('/')
    token = driver.execute_script "return ENV.AUTHENTICITY_TOKEN"
    get('/')
    token2 = driver.execute_script "return ENV.AUTHENTICITY_TOKEN"
    token.should_not == token2
  end

  it "should have token doubled in size" do
    user_logged_in
    get('/')
    token = driver.execute_script "return ENV.AUTHENTICITY_TOKEN"
    token.length.should == 88
  end
end
