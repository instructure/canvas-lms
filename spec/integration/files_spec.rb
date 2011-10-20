require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FilesController do
  context "should support Submission as a context" do
    before(:each) do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      login_as
      @me = @user
      submission_model
      @submission.attachment = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      @submission.save!
    end

    it "with safefiles" do
      HostUrl.stub!(:file_host).and_return('files-test.host')
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
      HostUrl.stub!(:file_host).and_return('test.host')
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
      login_as
      @me = @user
      @att = @me.attachments.create(:uploaded_data => stub_png_data('my-pic.png'))
    end

    it "with safefiles" do
      HostUrl.stub!(:file_host).and_return('files-test.host')
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
      HostUrl.stub!(:file_host).and_return('test.host')
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
        HostUrl.stub!(:file_host).and_return('files-test.host')
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
        HostUrl.stub!(:file_host).and_return('test.host')
        get "http://test.host/users/#{@me.id}/files/#{@att.id}/download", :wrap => '1'
        response.should be_redirect
        location = response['Location']
        URI.parse(location).path.should == "/users/#{@me.id}/files/#{@att.id}"
        get location
        response.content_type.should == 'text/html'
        doc = Nokogiri::HTML::DocumentFragment.parse(response.body)
        doc.at_css('iframe#file_content')['src'].should =~ %r{^http://test.host/users/#{@me.id}/files/#{@att.id}/my%20files/unfiled/ohai.html}
      end

    end
  end

  it "should use relative urls for safefiles in course context" do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
    login_as
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    HostUrl.stub!(:file_host).and_return('files-test.host')
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

  context "should support AssessmentQuestion as a context" do
    before do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      login_as
      @aq = assessment_question_model
      @att = @aq.attachments.create!(:uploaded_data => stub_png_data)
    end

    it "with safefiles" do
      HostUrl.stub!(:file_host).and_return('files-test.host')
      get "http://test.host/assessment_questions/#{@aq.id}/files/#{@att.id}/#{@att.uuid}"
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

    it "without safefiles" do
      HostUrl.stub!(:file_host).and_return('test.host')
      get "http://test.host/assessment_questions/#{@aq.id}/files/#{@att.id}/#{@att.uuid}"
      response.should be_success
      response.content_type.should == 'image/png'
      response['Pragma'].should be_nil
      response['Cache-Control'].should_not match(/no-cache/)
    end
  end

  it "should allow access to non-logged-in user agent if it has the right :verifier (lets google docs preview submissions in speedGrader)" do
    submission_model
    @submission.attachment = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
    @submission.save!
    HostUrl.stub!(:file_host).and_return('files-test.host')
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
end
