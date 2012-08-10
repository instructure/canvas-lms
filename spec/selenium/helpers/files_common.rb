shared_examples_for "files selenium shared" do
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
        "pseudonym_session[remember_me]" => "0"},
                                     {"Cookie" => @cookie})
    resp.code.should == "302"
    @cookie = resp.response['set-cookie']
    login_as username, password
  end

  def add_file(fixture, context, name)
    if context.is_a?(Course)
      path = "/courses/#{context.id}/files"
    elsif context.is_a?(User)
      path = "/dashboard/files"
    end
    context_code = context.asset_string.capitalize
    resp, body = SSLCommon.get "#{app_host}#{path}",
                               "Cookie" => @cookie
    resp.code.should == "200"
    body.should =~ /<div id="ajax_authenticity_token">([^<]*)<\/div>/
    authenticity_token = $1
    resp, body = SSLCommon.post_form("#{app_host}/files/pending", {
        "attachment[folder_id]" => context.folders.active.first.id,
        "attachment[filename]" => name,
        "attachment[context_code]" => context_code,
        "authenticity_token" => authenticity_token,
        "no_redirect" => true}, {"Cookie" => @cookie})
    resp.code.should == "200"
    data = json_parse(body)
    data["upload_url"] = data["proxied_upload_url"] || data["upload_url"]
    data["upload_url"] = "#{app_host}#{data["upload_url"]}" if data["upload_url"] =~ /^\//
    data["success_url"] = "#{app_host}#{data["success_url"]}" if data["success_url"] =~ /^\//
    data["upload_params"]["file"] = fixture
    resp, body = SSLCommon.post_multipart_form(data["upload_url"], data["upload_params"], {"Cookie" => @cookie}, ["bucket", "key", "acl"])
    resp.code.should =~ /^20/
    if body =~ /<PostResponse>/
      resp, body = SSLCommon.get data["success_url"]
      resp.code.should == "200"
    end
  end
end