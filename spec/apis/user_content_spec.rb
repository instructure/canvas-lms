#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/api_spec_helper')

describe UserContent, type: :request do
  before :once do
    course_with_teacher(:active_all => true)
    attachment_model
  end

  it "should translate course file download links to directly-downloadable urls" do
    @assignment = @course.assignments.create!(:title => "first assignment", :description => <<-HTML)
    <p>
      Hello, students.<br>
      This will explain everything: <img src="/courses/#{@course.id}/files/#{@attachment.id}/download" alt="important">
    </p>
    HTML

    json = api_call(:get,
      "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
      { :controller => 'assignments_api', :action => 'show',
        :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['description'])
    doc.at_css('img')['src'].should == "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
  end

  it "should translate group file download links to directly-downloadable urls" do
    @group = @course.groups.create!(:name => "course group")
    attachment_model(:context => @group)
    @group.add_user(@teacher)
    @group_topic = @group.discussion_topics.create!(:title => "group topic", :user => @teacher, :message =>  <<-HTML)
    <p>
      Hello, students.<br>
      This will explain everything: <img src="/groups/#{@group.id}/files/#{@attachment.id}/download" alt="important">
    </p>
    HTML

    json = api_call(:get,
      "/api/v1/groups/#{@group.id}/discussion_topics/#{@group_topic.id}",
      { :controller => 'discussion_topics_api', :action => 'show',
        :format => 'json', :group_id => @group.id.to_s, :topic_id => @group_topic.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['message'])
    doc.at_css('img')['src'].should == "http://www.example.com/groups/#{@group.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
  end

  it "should translate file download links to directly-downloadable urls for deleted and replaced files" do
    @attachment.destroy
    attachment2 = Attachment.create!(:folder => @attachment.folder, :context => @attachment.context, :filename => @attachment.filename, :uploaded_data => StringIO.new("first"))
    @context.attachments.find(@attachment.id).id.should == attachment2.id

    @assignment = @course.assignments.create!(:title => "first assignment", :description => <<-HTML)
    <p>
      Hello, students.<br>
      This will explain everything: <img src="/courses/#{@course.id}/files/#{@attachment.id}/download" alt="important">
    </p>
    HTML

    json = api_call(:get,
      "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
      { :controller => 'assignments_api', :action => 'show',
        :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['description'])
    doc.at_css('img')['src'].should == "http://www.example.com/courses/#{@course.id}/files/#{attachment2.id}/download?verifier=#{attachment2.uuid}"
  end

  it "should not corrupt absolute links" do
    attachment_model(:context => @course)
    @topic = @course.discussion_topics.create!(:title => "course topic", :user => @teacher, :message => <<-HTML)
    <p>
      Hello, students.<br>
      This will explain everything: <img src="http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download" alt="important">
    </p>
    HTML
    json = api_call(:get,
      "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
      { :controller => 'discussion_topics_api', :action => 'show',
        :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
    doc = Nokogiri::HTML::DocumentFragment.parse(json['message'])
    doc.at_css('img')['src'].should == "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
  end

  it "should not remove wrap parameter on file download links" do
    attachment_model(:context => @course)
    @topic = @course.discussion_topics.create!(:title => "course topic", :user => @teacher, :message => <<-HTML)
    <p>
      Hello, students.<br>
      This will explain everything: <img src="/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1" alt="important">
    </p>
    HTML
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                    { :controller => 'discussion_topics_api', :action => 'show',
                      :format => 'json', :course_id => @course.id.to_s, :topic_id => @topic.id.to_s })
    doc = Nokogiri::HTML::DocumentFragment.parse(json['message'])
    doc.at_css('img')['src'].should == "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}&wrap=1"
  end

  it "should translate file preview links to directly-downloadable preview urls" do
    @assignment = @course.assignments.create!(:title => "first assignment", :description => <<-HTML)
    <p>
      Hello, students.<br>
      This will explain everything: <img src="/courses/#{@course.id}/files/#{@attachment.id}/preview" alt="important">
    </p>
    HTML

    json = api_call(:get,
      "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
      { :controller => 'assignments_api', :action => 'show',
        :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['description'])
    doc.at_css('img')['src'].should == "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/preview?verifier=#{@attachment.uuid}"
  end

  it "should translate media comment links to embedded video tags" do
    @assignment = @course.assignments.create!(:title => "first assignment", :description => <<-HTML)
    <p>
      Hello, students.<br>
      Watch this awesome video: <a href="/media_objects/qwerty" class="instructure_inline_media_comment video_comment" id="media_comment_qwerty"><img></a>
    </p>
    HTML

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
    { :controller => 'assignments_api', :action => 'show',
      :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['description'])
    video = doc.at_css('video')
    video.should be_present
    video['class'].should match(/\binstructure_inline_media_comment\b/)
    video['data-media_comment_type'].should == 'video'
    video['data-media_comment_id'].should == 'qwerty'
    video['poster'].should match(%r{http://www.example.com/media_objects/qwerty/thumbnail})
    video['src'].should match(%r{http://www.example.com/courses/#{@course.id}/media_download})
    video['src'].should match(%r{entryId=qwerty})
    # we leave width/height out of it, since browsers tend to have good
    # defaults and it makes it easier to set via client css rules
    video['width'].should be_nil
    video['height'].should be_nil
  end

  it "should translate media comment audio tags" do
    @assignment = @course.assignments.create!(:title => "first assignment", :description => <<-HTML)
    <p>
      Hello, students.<br>
      Listen up: <a href="/media_objects/abcde" class="instructure_inline_media_comment audio_comment" id="media_comment_abcde"><img></a>
    </p>
    HTML

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
    { :controller => 'assignments_api', :action => 'show',
      :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['description'])
    audio = doc.at_css('audio')
    audio.should be_present
    audio['class'].should match(/\binstructure_inline_media_comment\b/)
    audio['data-media_comment_type'].should == 'audio'
    audio['data-media_comment_id'].should == 'abcde'
    audio['poster'].should be_blank
    audio['src'].should match(%r{http://www.example.com/courses/#{@course.id}/media_download})
    audio['src'].should match(%r{entryId=abcde})
  end

  it "should not translate links in content not viewable by user" do
    @assignment = @course.assignments.create!(:title => "first assignment", :description => <<-HTML)
    <p>
      Hello, students.<br>
      This will explain everything: <img src="/courses/#{@course.id}/files/#{@attachment.id}/preview" alt="important">
    </p>
    HTML

    # put a student in the course. this will be the active user during the API
    # call (necessary since the teacher has manage content rights and will thus
    # ignore the lock). lock the attachment so the student can't view it.
    student_in_course(:course => @course, :active_all => true)
    @attachment.locked = true
    @attachment.save

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
    { :controller => 'assignments_api', :action => 'show',
      :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['description'])
    doc.at_css('img')['src'].should == "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/preview"
  end

  it "should prepend the hostname to all absolute-path links" do
    @assignment = @course.assignments.create!(:title => "first assignment", :description => <<-HTML)
    <p>
      Hello, students.<br>
      <img src='/equation_images/1234'>
      <a href='/help'>click for teh help</a>
      <a href='//example.com/quiz'>a quiz</a>
      <a href='http://example.com/test1'>moar</a>
      <a href='invalid url'>broke</a>
    </p>
    HTML

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
    { :controller => 'assignments_api', :action => 'show',
      :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s })

    doc = Nokogiri::HTML::DocumentFragment.parse(json['description'])
    doc.at_css('img')['src'].should == "http://www.example.com/equation_images/1234"
    doc.css('a').map { |e| e['href'] }.should == [
      "http://www.example.com/help",
      "//example.com/quiz",
      "http://example.com/test1",
      "invalid%20url",
    ]
  end

  it "should not choke on funny email addresses" do
    @wiki_page = @course.wiki.front_page
    @wiki_page.body = "<a href='mailto:djmankiewicz@homestarrunner,com'>e-nail</a>"
    @wiki_page.workflow_state = 'active'
    @wiki_page.save!
    api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}",
               { :controller => 'wiki_pages_api', :action => 'show',
                 :format => 'json', :course_id => @course.id.to_s, :url => @wiki_page.url })
  end

  context "data api endpoints" do
    context "course context" do
      it "should process links to each type of object" do
        @wiki_page = @course.wiki.front_page
        @wiki_page.body = <<-HTML
        <p>
          <a href='/courses/#{@course.id}/assignments'>assignments index</a>
          <a href='/courses/#{@course.id}/assignments/9~123'>assignment</a>
          <a href='/courses/#{@course.id}/wiki'>wiki index</a>
          <a href='/courses/#{@course.id}/wiki/test-wiki-page'>wiki page</a>
          <a href='/courses/#{@course.id}/discussion_topics'>discussion index</a>
          <a href='/courses/#{@course.id}/discussion_topics/456'>discussion topic</a>
          <a href='/courses/#{@course.id}/files'>files index</a>
          <a href='/courses/#{@course.id}/files/789/download?verifier=lolcats'>files index</a>
          <a href='/files/789/download?verifier=lolcats'>file</a>
          <a href='/courses/#{@course.id}/quizzes'>quiz index</a>
          <a href='/courses/#{@course.id}/quizzes/999'>quiz</a>
          <a href='/courses/#{@course.id}/external_tools/retrieve?url=http://lti-tool-provider.example.com/lti_tool'>LTI Launch</a>
        </p>
        HTML
        @wiki_page.workflow_state = 'active'
        @wiki_page.save!

        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}",
                        { :controller => 'wiki_pages_api', :action => 'show',
                          :format => 'json', :course_id => @course.id.to_s, :url => @wiki_page.url })
        doc = Nokogiri::HTML::DocumentFragment.parse(json['body'])
        doc.css('a').collect { |att| att['data-api-endpoint'] }.should == [
          "http://www.example.com/api/v1/courses/#{@course.id}/assignments",
          "http://www.example.com/api/v1/courses/#{@course.id}/assignments/9~123",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages/test-wiki-page",
          "http://www.example.com/api/v1/courses/#{@course.id}/discussion_topics",
          "http://www.example.com/api/v1/courses/#{@course.id}/discussion_topics/456",
          "http://www.example.com/api/v1/courses/#{@course.id}/folders/root",
          "http://www.example.com/api/v1/files/789",
          "http://www.example.com/api/v1/files/789",
          "http://www.example.com/api/v1/courses/#{@course.id}/quizzes",
          "http://www.example.com/api/v1/courses/#{@course.id}/quizzes/999",
          "http://www.example.com/api/v1/courses/#{@course.id}/external_tools/sessionless_launch?url=http%3A%2F%2Flti-tool-provider.example.com%2Flti_tool"
        ]
        doc.css('a').collect { |att| att['data-api-returntype'] }.should ==
            %w([Assignment] Assignment [Page] Page [Discussion] Discussion Folder File File [Quiz] Quiz SessionlessLaunchUrl)
      end
    end

    context "group context" do
      it "should process links to each type of object" do
        group_with_user(:active_all => true)
        @wiki_page = @group.wiki.front_page
        @wiki_page.body = <<-HTML
        <p>
          <a href='/groups/#{@group.id}/wiki'>wiki index</a>
          <a href='/groups/#{@group.id}/wiki/some-page'>wiki page</a>
          <a href='/groups/#{@group.id}/discussion_topics'>discussion index</a>
          <a href='/groups/#{@group.id}/discussion_topics/1~123'>discussion topic</a>
          <a href='/groups/#{@group.id}/files'>files index</a>
          <a href='/groups/#{@group.id}/files/789/preview'>file</a>
        </p>
        HTML
        @wiki_page.workflow_state = 'active'
        @wiki_page.save!

        json = api_call(:get, "/api/v1/groups/#{@group.id}/pages/#{@wiki_page.url}",
                        { :controller => 'wiki_pages_api', :action => 'show',
                          :format => 'json', :group_id => @group.id.to_s, :url => @wiki_page.url })
        doc = Nokogiri::HTML::DocumentFragment.parse(json['body'])
        doc.css('a').collect { |att| att['data-api-endpoint'] }.should == [
            "http://www.example.com/api/v1/groups/#{@group.id}/pages",
            "http://www.example.com/api/v1/groups/#{@group.id}/pages/some-page",
            "http://www.example.com/api/v1/groups/#{@group.id}/discussion_topics",
            "http://www.example.com/api/v1/groups/#{@group.id}/discussion_topics/1~123",
            "http://www.example.com/api/v1/groups/#{@group.id}/folders/root",
            "http://www.example.com/api/v1/files/789"
        ]
        doc.css('a').collect{ |att| att['data-api-returntype'] }.should ==
            %w([Page] Page [Discussion] Discussion Folder File)
      end
    end

    context "user context" do
      it "should process links to each type of object" do
        @topic = @course.discussion_topics.create!(:message => <<-HTML)
            <a href='/users/#{@teacher.id}/files'>file index</a>
            <a href='/users/#{@teacher.id}/files/789/preview'>file</a>
        HTML

        json = api_call(:get, "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        :controller => 'discussion_topics_api', :action => 'show', :format => 'json',
                        :course_id => @course.id.to_s, :topic_id => @topic.id.to_s)
        doc = Nokogiri::HTML::DocumentFragment.parse(json['message'])
        doc.css('a').collect { |att| att['data-api-endpoint'] }.should == [
          "http://www.example.com/api/v1/users/#{@teacher.id}/folders/root",
          "http://www.example.com/api/v1/files/789"
        ]
        doc.css('a').collect { |att| att['data-api-returntype'] }.should ==
            %w(Folder File)
      end
    end
  end

  context "process_incoming_html_content" do
    class Tester
      include Api
    end

    let(:tester) { Tester.new }

    it "should add the expected href to instructure_inline_media_comment anchors" do
      factory_with_protected_attributes(MediaObject, media_id: 'test2', media_type: 'audio')
      html = tester.process_incoming_html_content(<<-HTML)
      <a id='something-else' href='/blah'>no touchy</a>
      <a class='instructure_inline_media_comment audio_comment'>no id</a>
      <a id='media_comment_test1' class='instructure_inline_media_comment audio_comment'>with id</a>
      <a id='media_comment_test2' class='instructure_inline_media_comment'>id, no type</a>
      <a id='media_comment_test3' class='instructure_inline_media_comment'>id, no type, missing object</a>
      HTML

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      anchors = doc.css('a')
      anchors[0]['id'].should == 'something-else'
      anchors[0]['href'].should == '/blah'
      anchors[1]['href'].should be_nil
      anchors[2]['href'].should == '/media_objects/test1'
      anchors[2]['class'].should == 'instructure_inline_media_comment audio_comment'
      anchors[3]['class'].should == 'instructure_inline_media_comment audio_comment' # media_type added by code
      anchors[3]['href'].should == '/media_objects/test2'
      anchors[4]['class'].should == 'instructure_inline_media_comment' # media object not found, no type added
      anchors[4]['href'].should == '/media_objects/test3'
    end

    it "should translate video and audio instructure_inline_media_comment tags" do
      html = tester.process_incoming_html_content(<<-HTML)
      <video src='/other'></video>
      <video class='instructure_inline_media_comment' src='/some/redirect/url'>no media id</video>
      <video class='instructure_inline_media_comment' src='/some/redirect/url' data-media_comment_id='test1'>with media id</video>
      <audio class='instructure_inline_media_comment' src='/some/redirect/url' data-media_comment_id='test2'>with media id</video>
      HTML

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      tags = doc.css('audio,video,a')
      tags[0].name.should == 'video'
      tags[0]['src'].should == '/other'
      tags[0]['class'].should be_nil
      tags[1].name.should == 'video'
      tags[2].name.should == 'a'
      tags[2]['class'].should == 'instructure_inline_media_comment video_comment'
      tags[2]['href'].should == '/media_objects/test1'
      tags[2]['id'].should == 'media_comment_test1'
      tags[3].name.should == 'a'
      tags[3]['class'].should == 'instructure_inline_media_comment audio_comment'
      tags[3]['href'].should == '/media_objects/test2'
      tags[3]['id'].should == 'media_comment_test2'
    end

    it "should leave verified user-context file links alone" do
      user
      attachment_model :context => @user
      url = "/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
      link = %Q{<a href="#{url}">what</a>}
      html = tester.process_incoming_html_content(link)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.at_css('a')['href'].should == url
    end
  end

  describe ".api_bulk_load_user_content_attachments" do
    it "returns a hash of assignment_id => assignment" do
      a1, a2, a3 = attachment_model, attachment_model, attachment_model
      html1, html2 = <<-HTML1, <<-HTML2
        <a href="/courses/#{@course.id}/files/#{a1.id}/download">uh...</a>
        <img src="/courses/#{@course.id}/files/#{a2.id}/download">
      HTML1
        <a href="/courses/#{@course.id}/files/#{a3.id}/download">Hi</a>
      HTML2

      class ApiClass
        include Api
      end

      ApiClass.new.api_bulk_load_user_content_attachments(
        [html1, html2],
        @course,
        @teacher
      ).should == {a1.id => a1, a2.id => a2, a3.id => a3}
    end
  end
end
