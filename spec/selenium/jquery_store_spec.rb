require File.expand_path(File.dirname(__FILE__) + "/common")

describe "jQuery.store" do
  it_should_behave_like "in-process server selenium tests"

  it "should handle slashes in the key" do
    get "/"
    driver.execute_script("
      $.store.set('foo/bar/baz', true);
      return $.store.get('foo/bar/baz');").should be_true
  end

  it "should persist across page loads" do
    get "/"
    driver.execute_script("$.store.set('somethingIWantToStore', true)")
    get '/'
    driver.execute_script("return $.store.get('somethingIWantToStore');").should be_true
  end
end
