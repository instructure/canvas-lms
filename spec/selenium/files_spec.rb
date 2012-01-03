require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "files selenium tests" do
  it_should_behave_like "forked server selenium tests"

  def fixture_file_path(file)
    path = ActionController::TestCase.respond_to?(:fixture_path) ? ActionController::TestCase.send(:fixture_path) : nil
    return "#{path}#{file}"
  end

  def fixture_file_upload(file, mimetype)
    ActionController::TestUploadedFile.new(fixture_file_path(file), mimetype)
  end

  def login(username, password)
    resp, body = SSLCommon.get "#{app_host}/login"
    resp.code.should == "200"
    @cookie = resp.response['set-cookie']
    resp, body = SSLCommon.post_form("#{app_host}/login", {
        "pseudonym_session[unique_id]" => username,
        "pseudonym_session[password]" => password,
        "redirect_to_ssl" => "0",
        "pseudonym_session[remember_me]" => "0" },
        { "Cookie" => @cookie })
    resp.code.should == "302"
    @cookie = resp.response['set-cookie']
    login_as username, password
  end

  def add_file(fixture, course, name)
    resp, body = SSLCommon.get "#{app_host}/courses/#{course.id}/files",
        "Cookie" => @cookie
    resp.code.should == "200"
    body.should =~ /<div id="ajax_authenticity_token">([^<]*)<\/div>/
    authenticity_token = $1
    resp, body = SSLCommon.post_form("#{app_host}/files/pending", {
        "attachment[folder_id]" => course.folders.active.first.id,
        "attachment[filename]" => name,
        "attachment[context_code]" => "Course_#{course.id}",
        "authenticity_token" => authenticity_token,
        "no_redirect" => true}, { "Cookie" => @cookie })
    resp.code.should == "200"
    data = json_parse(body)
    data["upload_url"] = data["proxied_upload_url"] || data["upload_url"]
    data["upload_url"] = "#{app_host}#{data["upload_url"]}" if data["upload_url"] =~ /^\//
    data["success_url"] = "#{app_host}#{data["success_url"]}" if data["success_url"] =~ /^\//
    data["upload_params"]["file"] = fixture
    resp, body = SSLCommon.post_multipart_form(data["upload_url"], data["upload_params"], { "Cookie" => @cookie }, ["bucket", "key", "acl"])
    resp.code.should =~ /^20/
    if body =~ /<PostResponse>/
      resp, body = SSLCommon.get data["success_url"]
      resp.code.should == "200"
    end
  end

  it "should show students link to download zip of folder" do
    user_with_pseudonym :username => "nobody3@example.com",
                        :password => "asdfasdf3"
    course_with_student_logged_in :user => @user
    login_as "nobody3@example.com", "asdfasdf3"
    get "/courses/#{@course.id}/files"
    
    #link = keep_trying_until { driver.find_element(:css, "div.links a.download_zip_link") }
    link = keep_trying_until {
      link = driver.find_element(:css, "div.links a.download_zip_link")
      wait_for_ajaximations
      link.should be_displayed
      link
    }
    link.attribute('href').should match(%r"/courses/#{@course.id}/folders/\d+/download")
  end

  it "should make folders in the menu droppable" do
    course_with_teacher_logged_in
    get "/dashboard/files"
    wait_for_ajaximations

    keep_trying_until {
      driver.find_element(:css, ".add_folder_link").click
      wait_for_animations
      driver.find_element(:css, "#files_content .add_folder_form #folder_name").should be_displayed
    }
    driver.find_element(:css, "#files_content .add_folder_form #folder_name").send_keys("my folder\n")
    wait_for_ajax_requests
    driver.find_element(:css, ".node.folder span").should have_class('ui-droppable')
  end

end

describe "files without s3 and forked tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should allow renaming folders" do
    course_with_teacher_logged_in
    get "/dashboard/files"
    wait_for_ajaximations

    keep_trying_until {
      driver.find_element(:css, ".add_folder_link").click
      wait_for_animations
      driver.find_element(:css, "#files_content .add_folder_form #folder_name").should be_displayed
    }
    driver.find_element(:css, "#files_content .add_folder_form #folder_name").send_keys("my folder\n")
    wait_for_ajax_requests
    Folder.last.name.should == "my folder"
    entry_field = keep_trying_until do
      driver.find_element(:css, "#files_content .folder_item .rename_item_link").click
      entry_field = driver.find_element(:css, "#files_content #rename_entry_field")
      entry_field.should be_displayed
      entry_field
    end
    entry_field.send_keys("my folder 2\n")
    wait_for_ajax_requests
    Folder.last.name.should == "my folder 2"
  end
end

describe "files Windows-Firefox-Local-Tests" do
  it_should_behave_like "files selenium tests"
  prepend_before(:each) {
    Setting.set("file_storage_test_override", "local")
  }
  prepend_before(:all) {
    Setting.set("file_storage_test_override", "local")
  }

  it "should allow you to edit html files" do
    user_with_pseudonym :username => "nobody2@example.com",
                        :password => "asdfasdf2"
    course_with_teacher_logged_in :user => @user
    login "nobody2@example.com", "asdfasdf2"
    add_file(fixture_file_upload('files/html-editing-test.html', 'text/html'),
        @course, "html-editing-test.html")
    get "/courses/#{@course.id}/files"
    link = keep_trying_until { driver.find_element(:css, "li.editable_folder_item div.header a.download_url") }
    link.should be_displayed
    link.text.should == "html-editing-test.html"
    current_content = File.read(fixture_file_path("files/html-editing-test.html"))
    4.times do
      get "/courses/#{@course.id}/files"
      new_content = "<html>#{ActiveSupport::SecureRandom.hex(10)}</html>"
      link = keep_trying_until { driver.find_element(:css, "li.editable_folder_item div.header a.edit_item_content_link") }
      link.should be_displayed
      link.text.should == "edit content"
      link.click
      keep_trying_until { driver.find_element(:css, "#edit_content_dialog").displayed?}
      keep_trying_until(120) { driver.execute_script("return $('#edit_content_textarea')[0].value;") == current_content }
      driver.execute_script("$('#edit_content_textarea')[0].value = '#{new_content}';")
      current_content = new_content
      driver.find_element(:css, "#edit_content_dialog button.save_button").click
      keep_trying_until { !driver.find_element(:css, "#edit_content_dialog").displayed?}
    end
  end
end

describe "files Windows-Firefox-S3-Tests" do
  it_should_behave_like "files selenium tests"
  prepend_before(:each) {
    Setting.set("file_storage_test_override", "s3")
  }
  prepend_before(:all) {
    Setting.set("file_storage_test_override", "s3")
  }
end

describe "collaborations folder in files menu" do
  it_should_behave_like "in-process server selenium tests"
  
  before (:each) do
    course_with_teacher_logged_in
    group_category = @course.group_categories.create(:name => "groupage")
    @group = Group.create!(:name=>"group1", :group_category => group_category, :context => @course)
  end
  
  def load_collab_folder
    get "/groups/#{@group.id}/files"
    message_node = keep_trying_until {
      driver.find_element(:css, "li.collaborations span.name").click
      driver.find_element(:css, "ul.files_content li.message")
    }
    message_node.text
  end
  
  it "should not show 'add collaboration' paragraph to teacher not participating in group" do
    message = load_collab_folder
    message.should_not =~ /click "New collaboration"/
  end
  
  it "should show 'add collaboration' paragraph to participating user" do
    @group.participating_users << @user
    message = load_collab_folder
    message.should =~ /click "New collaboration"/
  end
  
end

