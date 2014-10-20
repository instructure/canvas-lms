require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FilesController do
  context "should support Submission as a context" do
    before(:each) do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      host!("test.host")
      login_as
      @me = @user
      submission_model
      @submission.attachment = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      @submission.save!
    end

    it "with safefiles" do
      HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
      get "http://test.host/files/#{@submission.attachment.id}/download", :inline => '1', :verifier => @submission.attachment.uuid
      response.should be_redirect
      uri = URI.parse response['Location']
      qs = Rack::Utils.parse_nested_query(uri.query)
      uri.host.should == 'files-test.host'
      uri.path.should == "/files/#{@submission.attachment.id}/download"
      @me.valid_access_verifier?(qs['ts'], qs['sf_verifier']).should be_true
      qs['verifier'].should == @submission.attachment.uuid
      location = response['Location']
      reset!

      get location
      response.should be_success
      response.content_type.should == 'image/png'
      # ensure that the user wasn't logged in by the normal means
      controller.instance_variable_get(:@current_user).should be_nil
    end

    it "without safefiles" do
      HostUrl.stubs(:file_host_with_shard).returns(['test.host', Shard.default])
      get "http://test.host/files/#{@submission.attachment.id}/download", :inline => '1', :verifier => @submission.attachment.uuid
      response.should be_success
      response.content_type.should == 'image/png'
      response['Pragma'].should be_nil
      response['Cache-Control'].should_not match(/no-cache/)
    end
  end

  context "should support User as a context" do
    before(:each) do
      user_with_pseudonym
      host!("test.host")
      login_as
      @me = @user
      @att = @me.attachments.create(:uploaded_data => stub_png_data('my-pic.png'))
    end

    it "with safefiles" do
      HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
      get "http://test.host/users/#{@me.id}/files/#{@att.id}/download"
      response.should be_redirect
      uri = URI.parse response['Location']
      qs = Rack::Utils.parse_nested_query(uri.query)
      uri.host.should == 'files-test.host'
      # redirects to a relative url, since relative files are available in user context
      uri.path.should == "/users/#{@me.id}/files/#{@att.id}/my%20files/unfiled/my-pic.png"
      @me.valid_access_verifier?(qs['ts'], qs['sf_verifier']).should be_true
      location = response['Location']
      reset!

      get location
      response.should be_success
      response.content_type.should == 'image/png'
      # ensure that the user wasn't logged in by the normal means
      controller.instance_variable_get(:@current_user).should be_nil
    end

    it "without safefiles" do
      HostUrl.stubs(:file_host).returns('test.host')
      get "http://test.host/users/#{@me.id}/files/#{@att.id}/download"
      response.should be_success
      response.content_type.should == 'image/png'
      response['Pragma'].should be_nil
      response['Cache-Control'].should_not match(/no-cache/)
    end

    context "with inlineable html files" do
      before do
        @att = @me.attachments.create(:uploaded_data => stub_file_data("ohai.html", "<html><body>ohai</body></html>", "text/html"))
      end

      it "with safefiles" do
        HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
        get "http://test.host/users/#{@me.id}/files/#{@att.id}/download", :wrap => '1'
        response.should be_redirect
        uri = URI.parse response['Location']
        qs = Rack::Utils.parse_nested_query(uri.query)
        uri.host.should == 'test.host'
        uri.path.should == "/users/#{@me.id}/files/#{@att.id}"
        location = response['Location']

        get location
        # the response will be on the main domain, with an iframe pointing to the files domain and the actual uploaded html file
        response.should be_success
        response.content_type.should == 'text/html'
        doc = Nokogiri::HTML::DocumentFragment.parse(response.body)
        doc.at_css('iframe#file_content')['src'].should =~ %r{^http://files-test.host/users/#{@me.id}/files/#{@att.id}/my%20files/unfiled/ohai.html}
      end

      it "without safefiles" do
        HostUrl.stubs(:file_host_with_shard).returns(['test.host', Shard.default])
        get "http://test.host/users/#{@me.id}/files/#{@att.id}/download", :wrap => '1'
        response.should be_redirect
        location = response['Location']
        URI.parse(location).path.should == "/users/#{@me.id}/files/#{@att.id}"
        get location
        response.content_type.should == 'text/html'
        doc = Nokogiri::HTML::DocumentFragment.parse(response.body)
        doc.at_css('iframe#file_content')['src'].should =~ %r{^http://test.host/users/#{@me.id}/files/#{@att.id}/my%20files/unfiled/ohai.html}
      end

      it "should not inline the file if passed download_frd param" do
        HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
        get "http://test.host/users/#{@me.id}/files/#{@att.id}/download?download_frd=1&verifier=#{@att.uuid}"
        response.should be_redirect
        get response['Location']
        response.headers['Content-Disposition'].should match /attachment/
      end

    end
  end

  it "should use relative urls for safefiles in course context" do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    host!("test.host")
    login_as
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/download", :inline => '1'
    response.should be_redirect
    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    uri.host.should == 'files-test.host'
    uri.path.should == "/courses/#{@course.id}/files/#{a1.id}/course%20files/test%20my%20file%3F%20hai!%26.png"
    @user.valid_access_verifier?(qs['ts'], qs['sf_verifier']).should be_true
    qs['verifier'].should be_nil
    location = response['Location']
    reset!

    get location
    response.should be_success
    response.content_type.should == 'image/png'
    # ensure that the user wasn't logged in by the normal means
    controller.instance_variable_get(:@current_user).should be_nil
  end
  
  it "should be able to use verifier in course context" do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/download?verifier=#{a1.uuid}"
    response.should be_redirect

    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    uri.host.should == 'files-test.host'
    uri.path.should == "/courses/#{@course.id}/files/#{a1.id}/course%20files/test%20my%20file%3F%20hai!%26.png"
    qs['verifier'].should == a1.uuid
    location = response['Location']
    reset!

    get location
    response.should be_success
    response.content_type.should == 'image/png'
    # ensure that the user wasn't logged in by the normal means
    controller.instance_variable_get(:@current_user).should be_nil
  end

  it "should be able to directly download in course context preview links with verifier" do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/preview?verifier=#{a1.uuid}"
    response.should be_redirect

    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    uri.host.should == 'files-test.host'
    uri.path.should == "/courses/#{@course.id}/files/#{a1.id}/course%20files/test%20my%20file%3F%20hai!%26.png"
    qs['verifier'].should == a1.uuid
    location = response['Location']
    reset!

    get location
    response.should be_success
    response.content_type.should == 'image/png'
    # ensure that the user wasn't logged in by the normal means
    controller.instance_variable_get(:@current_user).should be_nil
  end

  it "should update module progressions for html safefiles iframe" do
    HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
    course_with_student(:active_all => true, :user => user_with_pseudonym)
    host!("test.host")
    login_as
    @att = @course.attachments.create(:uploaded_data => stub_file_data("ohai.html", "<html><body>ohai</body></html>", "text/html"))
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'attachment', :id => @att.id})
    @module.reload
    hash = {}
    hash[@tag.id.to_s] = {:type => 'must_view'}
    @module.completion_requirements = hash
    @module.save!
    @module.evaluate_for(@user).state.should eql(:unlocked)

    # the response will be on the main domain, with an iframe pointing to the files domain and the actual uploaded html file
    get "http://test.host/courses/#{@course.id}/files/#{@att.id}"
    response.should be_success
    response.content_type.should == 'text/html'
    doc = Nokogiri::HTML::DocumentFragment.parse(response.body)
    location = doc.at_css('iframe#file_content')['src']

    # now reset the user session (simulating accessing via a separate domain), grab the document,
    # and verify the module progress was recorded
    reset!
    get location
    response.should be_success
    @module.evaluate_for(@user).state.should eql(:completed)
  end

  context "should support AssessmentQuestion as a context" do
    before do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      host!("test.host")
      login_as
      bank = @course.assessment_question_banks.create!
      @aq = assessment_question_model(:bank => bank)
      @att = @aq.attachments.create!(:uploaded_data => stub_png_data)
    end

    def do_with_safefiles_test(url)
      HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
      get url
      response.should be_redirect
      uri = URI.parse response['Location']
      qs = Rack::Utils.parse_nested_query(uri.query)
      uri.host.should == 'files-test.host'
      uri.path.should == "/files/#{@att.id}/download"
      @user.valid_access_verifier?(qs['ts'], qs['sf_verifier']).should be_true
      qs['verifier'].should == @att.uuid
      location = response['Location']
      reset!

      get location
      response.should be_success
      response.content_type.should == 'image/png'
      # ensure that the user wasn't logged in by the normal means
      controller.instance_variable_get(:@current_user).should be_nil
    end

    context "with safefiles" do
      it "with new url style" do
        do_with_safefiles_test("http://test.host/assessment_questions/#{@aq.id}/files/#{@att.id}/#{@att.uuid}")
      end
      
      it "with old url style" do
        do_with_safefiles_test("http://test.host/assessment_questions/#{@aq.id}/files/#{@att.id}/download?verifier=#{@att.uuid}")
      end
    end

    def do_without_safefiles_test(url)
      HostUrl.stubs(:file_host).returns('test.host')
      get url
      response.should be_success
      response.content_type.should == 'image/png'
      response['Pragma'].should be_nil
      response['Cache-Control'].should_not match(/no-cache/)
    end

    context "without safefiles" do
      it "with new url style" do
        do_without_safefiles_test("http://test.host/assessment_questions/#{@aq.id}/files/#{@att.id}/#{@att.uuid}")
      end
      
      it "with old url style" do
        do_without_safefiles_test("http://test.host/assessment_questions/#{@aq.id}/files/#{@att.id}/download?verifier=#{@att.uuid}")
      end
    end
  end

  it "should allow access to non-logged-in user agent if it has the right :verifier (lets google docs preview submissions in speedGrader)" do
    submission_model
    @submission.attachment = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
    @submission.save!
    HostUrl.stubs(:file_host_with_shard).returns(['files-test.host', Shard.default])
    get "http://test.host/users/#{@submission.user.id}/files/#{@submission.attachment.id}/download", :verifier => @submission.attachment.uuid
    
    response.should be_redirect
    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    uri.host.should == 'files-test.host'
    uri.path.should == "/files/#{@submission.attachment.id}/download"
    qs['verifier'].should == @submission.attachment.uuid
    location = response['Location']
    reset!

    get location
    response.should be_success
    response.content_type.should == 'image/png'
    controller.instance_variable_get(:@current_user).should be_nil
    controller.instance_variable_get(:@context).should be_nil
  end

  it "shouldn't use relative urls for safefiles in other contexts" do
    course_with_teacher_logged_in(:active_all => true)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
  end

  it "should return the dynamically generated thumbnail of the size given" do
    attachment_model(:uploaded_data => stub_png_data)
    sz = "640x>"
    @attachment.any_instantiation.expects(:create_or_update_thumbnail).with(anything, sz, sz).returns { @attachment.thumbnails.create!(:thumbnail => "640x>", :uploaded_data => stub_png_data) }
    get "/images/thumbnails/#{@attachment.id}/#{@attachment.uuid}?size=640x#{URI.encode '>'}"
    thumb = @attachment.thumbnails.find_by_thumbnail("640x>")
    response.should redirect_to(thumb.authenticated_s3_url)
  end
  
  it "should reorder files" do
    course_with_teacher_logged_in(:active_all => true, :user => user_with_pseudonym)
    att1 = attachment_model(:uploaded_data => stub_png_data, :context => @course)
    att2 = attachment_model(:uploaded_data => stub_png_data("file2.png"), :context => @course)
    
    post "/courses/#{@course.id}/files/reorder", {:order => "#{att2.id}, #{att1.id}", :folder_id => @folder.id}
    response.should be_success
    
    @folder.file_attachments.by_position_then_display_name.should == [att2, att1]
  end
end
