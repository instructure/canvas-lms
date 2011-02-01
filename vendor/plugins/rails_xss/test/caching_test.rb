require 'test_helper'

CACHE_DIR = 'test_cache'
# Don't change '/../temp/' cavalierly or you might hose something you don't want hosed
FILE_STORE_PATH = File.join(File.dirname(__FILE__), '/../temp/', CACHE_DIR)
ActionController::Base.page_cache_directory = FILE_STORE_PATH
ActionController::Base.cache_store = :file_store, FILE_STORE_PATH

class FragmentCachingTestController < ActionController::Base
  def some_action; end;
end

class FragmentCachingTest < ActionController::TestCase
  def setup
    ActionController::Base.perform_caching = true
    @store = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.cache_store = @store
    @controller = FragmentCachingTestController.new
    @params = {:controller => 'posts', :action => 'index'}
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @controller.params = @params
    @controller.request = @request
    @controller.response = @response
    @controller.send(:initialize_current_url)
    @controller.send(:initialize_template_class, @response)
    @controller.send(:assign_shortcuts, @request, @response)
  end

  def test_fragment_for
    @store.write('views/expensive', 'fragment content')
    fragment_computed = false

    buffer = 'generated till now -> '.html_safe
    @controller.fragment_for(buffer, 'expensive') { fragment_computed = true }

    assert !fragment_computed
    assert_equal 'generated till now -> fragment content', buffer
  end

  def test_html_safety
    assert_nil @store.read('views/name')
    content = 'value'.html_safe
    assert_equal content, @controller.write_fragment('name', content)

    cached = @store.read('views/name')
    assert_equal content, cached
    assert_equal String, cached.class

    html_safe = @controller.read_fragment('name')
    assert_equal content, html_safe
    assert html_safe.html_safe?
  end
end
