#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'spec_helper'

require 'nokogiri'

describe FilesController do
  before :each do
    user_with_pseudonym(:active_all => true)
    local_storage!
  end

  context "should support Submission as a context" do
    before(:each) do
      course_with_teacher_logged_in(:active_all => true, :user => @user)
      host!("test.host")
      @me = @user
      submission_model
      @submission.attachment = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png')
      @submission.save!
    end

    it "with safefiles" do
      allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
      get "http://test.host/files/#{@submission.attachment.id}/download", params: {:inline => '1', :verifier => @submission.attachment.uuid}
      expect(response).to be_redirect
      uri = URI.parse response['Location']
      qs = Rack::Utils.parse_nested_query(uri.query).with_indifferent_access
      expect(uri.host).to eq 'files-test.host'
      expect(uri.path).to eq "/files/#{@submission.attachment.id}/download"
      expect{ Users::AccessVerifier.validate(qs) }.not_to raise_exception
      expect(Users::AccessVerifier.validate(qs)[:user]).to eql(@me)
      expect(qs['verifier']).to eq @submission.attachment.uuid
      location = response['Location']
      remove_user_session

      get location
      # could be success or redirect, depending on S3 config
      expect([200, 302]).to be_include(response.status)
      # ensure that the user wasn't logged in by the normal means
      expect(controller.instance_variable_get(:@current_user)).to be_nil
    end

    it "without safefiles" do
      allow(HostUrl).to receive(:file_host_with_shard).and_return(['test.host', Shard.default])
      get "http://test.host/files/#{@submission.attachment.id}/download", params: {:inline => '1', :verifier => @submission.attachment.uuid}
      # could be success or redirect, depending on S3 config
      expect([200, 302]).to be_include(response.status)
      expect(response['Pragma']).to be_nil
      expect(response['Cache-Control']).not_to match(/no-cache/)
    end
  end

  context "should support User as a context" do
    before(:each) do
      host!("test.host")
      user_session(@user)
      @me = @user
      @att = @me.attachments.create(:uploaded_data => stub_png_data('my-pic.png'))
    end

    it "with safefiles" do
      allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
      get "http://test.host/users/#{@me.id}/files/#{@att.id}/download"
      expect(response).to be_redirect
      uri = URI.parse response['Location']
      qs = Rack::Utils.parse_nested_query(uri.query).with_indifferent_access
      expect(uri.host).to eq 'files-test.host'
      # redirects to a relative url, since relative files are available in user context
      expect(uri.path).to eq "/users/#{@me.id}/files/#{@att.id}/my%20files/unfiled/my-pic.png"
      expect{ Users::AccessVerifier.validate(qs) }.not_to raise_exception
      expect(Users::AccessVerifier.validate(qs)[:user]).to eql(@me)
      location = response['Location']
      remove_user_session

      get location
      expect(response).to be_successful
      expect(response.content_type).to eq 'image/png'
      # ensure that the user wasn't logged in by the normal means
      expect(controller.instance_variable_get(:@current_user)).to be_nil
    end

    it "without safefiles" do
      allow(HostUrl).to receive(:file_host).and_return('test.host')
      get "http://test.host/users/#{@me.id}/files/#{@att.id}/download"
      expect(response).to be_successful
      expect(response.content_type).to eq 'image/png'
      expect(response['Pragma']).to be_nil
      expect(response['Cache-Control']).not_to match(/no-cache/)
    end

    context "with inlineable html files" do
      before do
        @att = @me.attachments.create(:uploaded_data => stub_file_data("ohai.html", "<html><body>ohai</body></html>", "text/html"))
      end

      it "with safefiles" do
        allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
        get "http://test.host/users/#{@me.id}/files/#{@att.id}/download", params: {:wrap => '1'}
        expect(response).to be_redirect
        uri = URI.parse response['Location']
        qs = Rack::Utils.parse_nested_query(uri.query)
        expect(uri.host).to eq 'test.host'
        expect(uri.path).to eq "/users/#{@me.id}/files/#{@att.id}"
        location = response['Location']

        get location
        # the response will be on the main domain, with an iframe pointing to the files domain and the actual uploaded html file
        expect(response).to be_successful
        expect(response.content_type).to eq 'text/html'
        doc = Nokogiri::HTML::DocumentFragment.parse(response.body)
        expect(doc.at_css('iframe#file_content')['src']).to match %r{^http://files-test.host/users/#{@me.id}/files/#{@att.id}/my%20files/unfiled/ohai.html}
      end

      it "without safefiles" do
        allow(HostUrl).to receive(:file_host_with_shard).and_return(['test.host', Shard.default])
        get "http://test.host/users/#{@me.id}/files/#{@att.id}/download", params: {:wrap => '1'}
        expect(response).to be_redirect
        location = response['Location']
        expect(URI.parse(location).path).to eq "/users/#{@me.id}/files/#{@att.id}"
        get location
        expect(response.content_type).to eq 'text/html'
        doc = Nokogiri::HTML::DocumentFragment.parse(response.body)
        expect(doc.at_css('iframe#file_content')['src']).to match %r{^http://test.host/users/#{@me.id}/files/#{@att.id}/my%20files/unfiled/ohai.html}
      end

      it "should not inline the file if passed download_frd param" do
        allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
        get "http://test.host/users/#{@me.id}/files/#{@att.id}/download?download_frd=1&verifier=#{@att.uuid}"
        expect(response).to be_redirect
        get response['Location']
        expect(response.headers['Content-Disposition']).to match /attachment/
      end

    end
  end

  it "should use relative urls for safefiles in course context" do
    course_with_teacher_logged_in(:active_all => true, :user => @user)
    host!("test.host")
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/download", params: {:inline => '1'}
    expect(response).to be_redirect
    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query).with_indifferent_access
    expect(uri.host).to eq 'files-test.host'
    expect(uri.path).to eq "/courses/#{@course.id}/files/#{a1.id}/course%20files/test%20my%20file%3F%20hai!%26.png"
    expect{ Users::AccessVerifier.validate(qs) }.not_to raise_exception
    expect(Users::AccessVerifier.validate(qs)[:user]).to eql(@user)
    expect(qs['verifier']).to be_nil
    location = response['Location']
    remove_user_session

    get location
    # could be success or redirect, depending on S3 config
    expect([200, 302]).to be_include(response.status)
    # ensure that the user wasn't logged in by the normal means
    expect(controller.instance_variable_get(:@current_user)).to be_nil
  end

  it "logs user access with safefiles" do
    course_with_teacher_logged_in(:active_all => true, :user => @user)
    host!("test.host")
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)

    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/download", params: {:inline => '1'}
    expect(response).to be_redirect
    location = response['Location']
    remove_user_session

    Setting.set('enable_page_views', 'db')
    get location
    # ensure that the user wasn't logged in by the normal means
    expect(controller.instance_variable_get(:@current_user)).to be_nil
    access = AssetUserAccess.for_user(@user).first
    expect(access).to_not be_nil
    expect(access.asset).to eq a1
  end

  it "should be able to use verifier in course context" do
    course_with_teacher(:active_all => true, :user => @user)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/download?verifier=#{a1.uuid}"
    expect(response).to be_redirect

    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    expect(uri.host).to eq 'files-test.host'
    expect(uri.path).to eq "/courses/#{@course.id}/files/#{a1.id}/course%20files/test%20my%20file%3F%20hai!%26.png"
    expect(qs['verifier']).to eq a1.uuid
    location = response['Location']
    remove_user_session

    get location
    expect(response).to be_successful
    expect(response.content_type).to eq 'image/png'
    # ensure that the user wasn't logged in by the normal means
    expect(controller.instance_variable_get(:@current_user)).to be_nil
  end

  it "should be able to directly download in course context preview links with verifier" do
    course_with_teacher(:active_all => true, :user => @user)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
    allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
    get "http://test.host/courses/#{@course.id}/files/#{a1.id}/preview?verifier=#{a1.uuid}"
    expect(response).to be_redirect

    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    expect(uri.host).to eq 'files-test.host'
    expect(uri.path).to eq "/courses/#{@course.id}/files/#{a1.id}/course%20files/test%20my%20file%3F%20hai!%26.png"
    expect(qs['verifier']).to eq a1.uuid
    location = response['Location']
    remove_user_session

    get location
    expect(response).to be_successful
    expect(response.content_type).to eq 'image/png'
    # ensure that the user wasn't logged in by the normal means
    expect(controller.instance_variable_get(:@current_user)).to be_nil
  end

  it "should update module progressions for html safefiles iframe" do
    allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
    course_with_student_logged_in(:active_all => true, :user => @user)
    host!("test.host")
    @att = @course.attachments.create(:uploaded_data => stub_file_data("ohai.html", "<html><body>ohai</body></html>", "text/html"))
    @module = @course.context_modules.create!(:name => "module")
    @tag = @module.add_item({:type => 'attachment', :id => @att.id})
    @module.reload
    hash = {}
    hash[@tag.id.to_s] = {:type => 'must_view'}
    @module.completion_requirements = hash
    @module.save!
    expect(@module.evaluate_for(@user).state).to eql(:unlocked)

    # the response will be on the main domain, with an iframe pointing to the files domain and the actual uploaded html file
    get "http://test.host/courses/#{@course.id}/files/#{@att.id}"
    expect(response).to be_successful
    expect(response.content_type).to eq 'text/html'
    doc = Nokogiri::HTML::DocumentFragment.parse(response.body)
    location = doc.at_css('iframe#file_content')['src']

    # now reset the user session (simulating accessing via a separate domain), grab the document,
    # and verify the module progress was recorded
    remove_user_session
    get location
    # could be success or redirect, depending on S3 config
    expect([200, 302]).to be_include(response.status)
    expect(@module.evaluate_for(@user).state).to eql(:completed)
  end

  context "should support AssessmentQuestion as a context" do
    before do
      course_with_teacher_logged_in(:active_all => true, :user => @user)
      host!("test.host")
      bank = @course.assessment_question_banks.create!
      @aq = assessment_question_model(:bank => bank)
      @att = @aq.attachments.create!(:uploaded_data => stub_png_data)
    end

    def do_with_safefiles_test(url)
      allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
      get url
      expect(response).to be_redirect
      uri = URI.parse response['Location']
      qs = Rack::Utils.parse_nested_query(uri.query).with_indifferent_access
      expect(uri.host).to eq 'files-test.host'
      expect(uri.path).to eq "/files/#{@att.id}/download"
      expect{ Users::AccessVerifier.validate(qs) }.not_to raise_exception
      expect(Users::AccessVerifier.validate(qs)[:user]).to eql(@user)
      expect(qs['verifier']).to eq @att.uuid
      location = response['Location']
      remove_user_session

      get location
      expect(response).to be_successful
      expect(response.content_type).to eq 'image/png'
      # ensure that the user wasn't logged in by the normal means
      expect(controller.instance_variable_get(:@current_user)).to be_nil
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
      allow(HostUrl).to receive(:file_host).and_return('test.host')
      get url
      expect(response).to be_successful
      expect(response.content_type).to eq 'image/png'
      expect(response['Pragma']).to be_nil
      expect(response['Cache-Control']).not_to match(/no-cache/)
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
    allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
    get "http://test.host/users/#{@submission.user.id}/files/#{@submission.attachment.id}/download", params: {:verifier => @submission.attachment.uuid}

    expect(response).to be_redirect
    uri = URI.parse response['Location']
    qs = Rack::Utils.parse_nested_query(uri.query)
    expect(uri.host).to eq 'files-test.host'
    expect(uri.path).to eq "/files/#{@submission.attachment.id}/download"
    expect(qs['verifier']).to eq @submission.attachment.uuid
    location = response['Location']
    remove_user_session

    get location
    expect(response).to be_successful
    expect(response.content_type).to eq 'image/png'
    expect(controller.instance_variable_get(:@current_user)).to be_nil
    expect(controller.instance_variable_get(:@context)).to be_nil
  end

  it "shouldn't use relative urls for safefiles in other contexts" do
    course_with_teacher_logged_in(:active_all => true)
    a1 = attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => @course)
  end

  it "should return the dynamically generated thumbnail of the size given" do
    attachment_model(:uploaded_data => stub_png_data)
    sz = "640x>"
    expect_any_instantiation_of(@attachment).to receive(:create_or_update_thumbnail).
      with(anything, sz, sz) { @attachment.thumbnails.create!(:thumbnail => "640x>", :uploaded_data => stub_png_data) }
    get "/images/thumbnails/#{@attachment.id}/#{@attachment.uuid}?size=640x#{URI.encode '>'}"
    thumb = @attachment.thumbnails.where(thumbnail: "640x>").first
    expect(response).to redirect_to(thumb.authenticated_s3_url)
  end

  it "should reorder files" do
    course_with_teacher_logged_in(:active_all => true, :user => @user)
    att1 = attachment_model(:uploaded_data => stub_png_data, :context => @course)
    att2 = attachment_model(:uploaded_data => stub_png_data("file2.png"), :context => @course)

    post "/courses/#{@course.id}/files/reorder", params: {:order => "#{att2.id}, #{att1.id}", :folder_id => @folder.id}
    expect(response).to be_successful

    expect(@folder.file_attachments.by_position_then_display_name).to eq [att2, att1]
  end

  it "should allow file previews for public-to-auth courses" do
    course_factory(active_all: true)
    @course.update_attribute(:is_public_to_auth_users, true)

    att = attachment_model(:uploaded_data => stub_png_data, :context => @course)

    user_factory(active_all: true)
    user_session(@user)

    user_verifier = Users::AccessVerifier.generate(user: @user)
    get "/files/#{att.id}", params: user_verifier # set the file access session tokens
    expect(session['file_access_user_id']).to be_present

    get "/courses/#{@course.id}/files/#{att.id}/file_preview"
    expect(response.body).to_not include("This file has not been unlocked yet")
    expect(response.body).to include("/courses/#{@course.id}/files/#{att.id}")
  end

  it "should allow downloads from assignments without context" do
    host!("test.host")
    allow(HostUrl).to receive(:file_host_with_shard).and_return(['files-test.host', Shard.default])
    course_with_teacher_logged_in(:active_all => true, :user => @user)
    assignment = assignment_model(:course => @course)
    attachment = attachment_model(:context => assignment, :uploaded_data => stub_png_data, :content_type => 'image/png')

    get "http://test.host/assignments/#{assignment.id}/files/#{attachment.id}/download"
    expect(response).to be_redirect
    expect(response['Location']).to include("files/#{attachment.id}")

    get response['Location']
    expect(response).to be_successful
  end
end
