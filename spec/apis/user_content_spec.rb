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

describe UserContent, :type => :integration do
  it "should translate course file download links to directly-downloadable urls" do
    course_with_teacher(:active_all => true)
    attachment_model
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
    course_with_teacher(:active_all => true)
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
    course_with_teacher(:active_all => true)
    attachment_model
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

  it "should translate file preview links to directly-downloadable preview urls" do
    course_with_teacher(:active_all => true)
    attachment_model
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
    course_with_teacher(:active_all => true)
    attachment_model
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
    course_with_teacher(:active_all => true)
    attachment_model
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
    course_with_teacher(:active_all => true)
    attachment_model
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
    course_with_teacher(:active_all => true)
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
    course_with_teacher(:active_all => true)
    @wiki_page = @course.wiki.wiki_page
    @wiki_page.body = "<a href='mailto:djmankiewicz@homestarrunner,com'>e-nail</a>"
    @wiki_page.workflow_state = 'active'
    @wiki_page.save!
    api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}",
               { :controller => 'wiki_pages', :action => 'api_show',
                 :format => 'json', :course_id => @course.id.to_s, :url => @wiki_page.url })
  end

  context "data api endpoints" do
    context "course context" do
      it "should process links to each type of object" do
        course_with_teacher(:active_all => true)
        @wiki_page = @course.wiki.wiki_page
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
        </p>
        HTML
        @wiki_page.workflow_state = 'active'
        @wiki_page.save!

        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}",
                        { :controller => 'wiki_pages', :action => 'api_show',
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
          "http://www.example.com/api/v1/files/789"
        ]
        doc.css('a').collect { |att| att['data-api-returntype'] }.should ==
            %w([Assignment] Assignment [Page] Page [Discussion] Discussion Folder File File)
      end
    end

    context "group context" do
      it "should process links to each type of object" do
        group_with_user(:active_all => true)
        @wiki_page = @group.wiki.wiki_page
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
                        { :controller => 'wiki_pages', :action => 'api_show',
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
        course_with_teacher(:active_all => true)
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
end
