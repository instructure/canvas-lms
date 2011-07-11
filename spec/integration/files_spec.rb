require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FilesController do
  context "should support Submission as a context" do
    before(:each) do
      course_with_teacher_logged_in(:active_all => true)
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

      get response['Location']
      response.should be_success
      response.content_type.should == 'image/png'
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
    course_with_teacher_logged_in(:active_all => true)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    HostUrl.stub!(:file_host).and_return('files-test.host')
    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/download", :inline => '1'
    response.should be_redirect
    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    uri.host.should == 'files-test.host'
    uri.path.should == "/courses/#{@course.id}/files/#{a1.id}/course%20files/test.png"
    @user.valid_access_verifier?(qs['ts'], qs['sf_verifier']).should be_true
    qs['verifier'].should be_nil

    get response['Location']
    response.should be_success
    response.content_type.should == 'image/png'
  end

  it "shouldn't use relative urls for safefiles in other contexts" do
    course_with_teacher_logged_in(:active_all => true)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
  end

  context "should support ContextMessage as a context" do
    before(:each) do
      course_with_teacher_logged_in(:active_all => true)
      @me = @user
      context_message_model(:course => @course, :recipient => @me)
      @attachment = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      @attachment.context = @context_message
      @attachment.save
    end

    it "directly from message" do
      HostUrl.stub!(:file_host).and_return('test.host')
      get "http://test.host/courses/#{@course.id}/messages/#{@context_message.id}/files/#{@attachment.id}"
      response.should be_redirect
      
      get response['Location']
      response.should be_success
      response.content_type.should == 'image/png'
    end
  end
end
