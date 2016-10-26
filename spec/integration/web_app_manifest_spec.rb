require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'site-wide', :type => :request do

  context "web app manifest" do

    before(:once) do
      student_in_course
      user_with_pseudonym(:user => @student, :username => 'student@example.com', :password => 'password')
    end

    it "doesn't add link tag if setting is explicitly unset" do
      user_session(@student, @pseudonym)
      get "/"
      expect(response.body).not_to include('link rel="manifest"')
    end

    it "adds the app manifest link tag so it prompts android users to install mobile app" do
      Setting.set('web_app_manifest_url', '/web-app-manifest/manifest.json')
      user_session(@student, @pseudonym)
      get "/"
      expect(response.body).to include('link rel="manifest" href="/web-app-manifest/manifest.json"')
    end

  end
end
