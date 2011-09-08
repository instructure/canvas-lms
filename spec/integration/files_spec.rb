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
