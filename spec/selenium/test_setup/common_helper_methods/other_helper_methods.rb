module OtherHelperMethods
  # usage
  # require_exec 'compiled/util/foo', 'bar', <<-CS
  #   foo('something')
  #   # optionally I should be able to do
  #   bar 'something else', ->
  #     "stuff"
  #     callback('i made it')
  #
  # CS
  #
  # simple usage
  # require_exec 'i18n!messages', 'i18n.t("foobar")'
  def require_exec(*args)
    code = args.last
    things_to_require = {}
    args[0...-1].each do |file_path|
      things_to_require[file_path] = file_path.split('/').last.split('!').first
    end

    # make sure the code you pass is at least as intented as it should be
    code = code.gsub(/^/, '          ')
    coffee_source = <<-CS
      _callback = arguments[arguments.length - 1];
      cancelCallback = false
      callback = ->
        _callback.apply(this, arguments)
        cancelCallback = true
      require #{things_to_require.keys.to_json}, (#{things_to_require.values.join(', ')}) ->
        res = do ->
#{code}
        _callback(res) unless cancelCallback
    CS
    # make it `bare` because selenium already wraps it in a function and we need to get
    # the arguments for our callback
    js = CoffeeScript.compile(coffee_source, :bare => true)
    driver.execute_async_script(js)
  end

  def stub_kaltura
    # trick kaltura into being activated
    CanvasKaltura::ClientV3.stubs(:config).returns({
                                                       'domain' => 'www.instructuremedia.com',
                                                       'resource_domain' => 'www.instructuremedia.com',
                                                       'partner_id' => '100',
                                                       'subpartner_id' => '10000',
                                                       'secret_key' => 'fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321',
                                                       'user_secret_key' => '1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1',
                                                       'player_ui_conf' => '1',
                                                       'kcw_ui_conf' => '1',
                                                       'upload_ui_conf' => '1'
                                                   })
    kal = mock('CanvasKaltura::ClientV3')
    kal.stubs(:startSession).returns "new_session_id_here"
    CanvasKaltura::ClientV3.stubs(:new).returns(kal)
  end

  def page_view(opts={})
    course = opts[:course] || @course
    user = opts[:user] || @student
    controller = opts[:controller] || 'assignments'
    summarized = opts[:summarized] || nil
    url = opts[:url]
    user_agent = opts[:user_agent] || 'firefox'

    page_view = course.page_views.build(
        :user => user,
        :controller => controller,
        :url => url,
        :user_agent => user_agent)

    page_view.summarized = summarized
    page_view.request_id = SecureRandom.hex(10)
    page_view.created_at = opts[:created_at] || Time.now

    if opts[:participated]
      page_view.participated = true
      access = page_view.build_asset_user_access
      access.display_name = 'Some Asset'
    end

    page_view.store
    page_view
  end

  TEST_FILE_UUIDS = {
      "testfile1.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
      "testfile1copy.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
      "testfile2.txt" => "5d714eca-2cff-4737-8604-45ca098165cc",
      "testfile3.txt" => "72476b31-58ab-48f5-9548-a50afe2a2fe3",
      "testfile4.txt" => "38f6efa6-aff0-4832-940e-b6f88a655779",
      "testfile5.zip" => "3dc43133-840a-46c8-ea17-3e4bef74af37",
      "attachments.zip" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/attachments.zip')),
      "graded.png" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../../public/images/graded.png')),
      "cc_full_test.zip" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/migration/cc_full_test.zip')),
      "cc_ark_test.zip" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/migration/cc_ark_test.zip')),
      "canvas_cc_minimum.zip" => File.read(File.dirname(__FILE__) + '/../../../fixtures/migration/canvas_cc_minimum.zip'),
      "canvas_cc_only_questions.zip" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/migration/canvas_cc_only_questions.zip')),
      "qti.zip" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/migration/package_identifier/qti.zip')),
      "a_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/files/a_file.txt')),
      "b_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/files/b_file.txt')),
      "c_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/files/c_file.txt')),
      "amazing_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/files/amazing_file.txt')),
      "Dog_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/files/Dog_file.txt')),
      "cn-image.jpg" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/files/cn_image.jpg')),
      "empty_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + '/../../../fixtures/files/empty_file.txt')),
  }.freeze

  def get_file(filename, data = nil)
    data ||= TEST_FILE_UUIDS[filename]
    @file = Tempfile.new(filename.split(/(?=\.)/))
    @file.write data
    @file.close
    fullpath = @file.path
    filename = File.basename(@file.path)
    [filename, fullpath, data, @file]
  end

  module EncryptedCookieStoreTestSecret
    cattr_accessor :test_secret

    def self.prepended(klass)
      klass.cattr_accessor(:test_secret)
    end

    def call(env)
      if self.class.test_secret.present?
        @secret = self.class.test_secret
        @encryption_key = unhex(@secret[0...(@data_cipher.key_len * 2)]).freeze
      end
      super
    end
  end
  EncryptedCookieStore.prepend(EncryptedCookieStoreTestSecret)

  def clear_timers!
    # we don't want any AJAX requests getting kicked off after a test ends.
    # the unload event won't fire until sometime after the next test begins (and
    # the old session cookie becomes invalid). that means a late AJAX call can
    # screw up the next test, i.e. two requests send the old (now-invalid)
    # encrypted session cookie, each gets a new (different) session cookie in
    # the response, meaning the authenticity token on your new page might
    # already be invalid.
    driver.execute_script <<-JS
      var highest = setTimeout(function(){}, 1000);
      for (var i = 0; i < highest; i++) {
        clearTimeout(i);
      }
      highest = setInterval(function(){}, 1000);
      for (var i = 0; i < highest; i++) {
        clearInterval(i);
      }
    JS
  end

  def clear_local_storage
    driver.execute_script 'localStorage.clear();'
  end
end
