# frozen_string_literal: true

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

require_relative "api_spec_helper"

require "nokogiri"

describe UserContent, type: :request do
  before :once do
    course_with_teacher(active_all: true)
    attachment_model
  end

  shared_examples "link translation examples" do
    subject do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
                      { controller: "assignments_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        id: @assignment.id.to_s })

      @doc = Nokogiri::HTML5.fragment(json["description"])
    end

    it "translates course file download links to directly-downloadable urls" do
      @assignment = @course.assignments.create!(title: "first assignment", description: "<img src=\"/courses/#{@course.id}/files/#{@attachment.id}/download\" alt=\"important\">")
      subject
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
    end

    it "translates group file download links to directly-downloadable urls" do
      @group = @course.groups.create!(name: "course group")
      attachment_model(context: @group)
      @group.add_user(@teacher)
      @group_topic = @group.discussion_topics.create!(title: "group topic", user: @teacher, message: "<img src=\"/groups/#{@group.id}/files/#{@attachment.id}/download\" alt=\"important\">")
      json = api_call(:get,
                      "/api/v1/groups/#{@group.id}/discussion_topics/#{@group_topic.id}",
                      { controller: "discussion_topics_api",
                        action: "show",
                        format: "json",
                        group_id: @group.id.to_s,
                        topic_id: @group_topic.id.to_s })

      @doc = Nokogiri::HTML5.fragment(json["message"])
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/groups/#{@group.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
    end

    it "translates file download links to directly-downloadable urls for deleted and replaced files" do
      @attachment.destroy
      attachment2 = Attachment.create!(folder: @attachment.folder, context: @attachment.context, filename: @attachment.filename, uploaded_data: StringIO.new("first"))
      expect(@context.attachments.find(@attachment.id).id).to eq attachment2.id

      @assignment = @course.assignments.create!(title: "first assignment", description: "<img src=\"/courses/#{@course.id}/files/#{@attachment.id}/download\" alt=\"important\">")
      subject
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{attachment2.id}/download?verifier=#{attachment2.uuid}"
    end

    it "does not corrupt absolute links" do
      attachment_model(context: @course)
      @assignment = @course.assignments.create!(title: "first assignment", description: "<img src=\"http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download\" alt=\"important\">")
      subject
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
    end

    it "does not remove wrap parameter on file download links" do
      attachment_model(context: @course)
      @assignment = @course.assignments.create!(title: "first assignment", description: "<img src=\"/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1\" alt=\"important\">")
      subject
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}&wrap=1"
    end

    it "translates file preview links to directly-downloadable preview urls" do
      @assignment = @course.assignments.create!(title: "first assignment", description: "<img src=\"/courses/#{@course.id}/files/#{@attachment.id}/preview\" alt=\"important\">")
      subject
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/preview?verifier=#{@attachment.uuid}"
    end

    it "translates media comments to embedded video tags" do
      @assignment = @course.assignments.create!(title: "first assignment", description: '<a href="/media_objects/qwerty" class="instructure_inline_media_comment video_comment" id="media_comment_qwerty">Watch</a>')
      subject
      video = @doc.at_css("video")
      expect(video).to be_present
      expect(video["class"]).to match(/\binstructure_inline_media_comment\b/)
      expect(video["data-media_comment_type"]).to eq "video"
      expect(video["data-media_comment_id"]).to eq "qwerty"
      expect(video["poster"]).to match(%r{http://www.example.com/media_objects/qwerty/thumbnail})
      expect(video["src"]).to match(%r{http://www.example.com/courses/#{@course.id}/media_download})
      expect(video["src"]).to match(/entryId=qwerty/)
      # we leave width/height out of it, since browsers tend to have good
      # defaults and it makes it easier to set via client css rules
      expect(video["width"]).to be_nil
      expect(video["height"]).to be_nil
    end

    it "translates media comments to audio tags" do
      @assignment = @course.assignments.create!(title: "first assignment", description: '<a href="/media_objects/abcde" class="instructure_inline_media_comment audio_comment" id="media_comment_abcde">Listen</a>')
      subject
      audio = @doc.at_css("audio")
      expect(audio).to be_present
      expect(audio["class"]).to match(/\binstructure_inline_media_comment\b/)
      expect(audio["data-media_comment_type"]).to eq "audio"
      expect(audio["data-media_comment_id"]).to eq "abcde"
      expect(audio["poster"]).to be_blank
      expect(audio["src"]).to match(%r{http://www.example.com/courses/#{@course.id}/media_download})
      expect(audio["src"]).to match(/entryId=abcde/)
    end

    it "does not translate links from content not viewable by user" do
      @assignment = @course.assignments.create!(title: "first assignment", description: "<img src=\"/courses/#{@course.id}/files/#{@attachment.id}/preview\" alt=\"important\">")
      student_in_course(course: @course, active_all: true)
      @attachment.locked = true
      @attachment.save
      subject
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{@attachment.id}/preview"
    end

    it "prepends the hostname to all absolute-path links" do
      @assignment = @course.assignments.create!(title: "first assignment", description: <<~HTML)
        <p>
          Hello, students.<br>
          <img src='/equation_images/1234'>
          <a href='/help'>click for teh help</a>
          <a href='//example.com/quiz'>a quiz</a>
          <a href='http://example.com/test1'>moar</a>
          <a href='invalid url'>broke</a>
        </p>
      HTML
      subject
      expect(@doc.at_css("img")["src"]).to eq "http://www.example.com/equation_images/1234"
      expect(@doc.css("a").pluck("href")).to eq %w[http://www.example.com/help //example.com/quiz http://example.com/test1 invalid%20url]
    end

    it "does not choke on funny email addresses" do
      @assignment = @course.assignments.create!(title: "first assignment", description: '<a href="mailto:djmankiewicz@homestarrunner,com">e-nail</a>')
      subject
      assert_status(200)
    end
  end

  describe "link translation" do
    context "with precise_link_replacements FF OFF" do
      before { Account.site_admin.disable_feature! :precise_link_replacements }

      include_examples "link translation examples"
    end

    context "with precise_link_replacements FF ON" do
      before { Account.site_admin.enable_feature! :precise_link_replacements }

      include_examples "link translation examples"
    end
  end

  context "data api endpoints" do
    context "course context" do
      it "processes links to each type of object" do
        @wiki_page = @course.wiki_pages.build(title: "title")
        @wiki_page.body = <<~HTML
          <p>
            <a href='/courses/#{@course.id}/assignments'>assignments index</a>
            <a href='/courses/#{@course.id}/assignments/9~123'>assignment</a>
            <a href='/courses/#{@course.id}/wiki'>wiki index</a>
            <a href='/courses/#{@course.id}/wiki/test-wiki-page'>wiki page</a>
            <a href='/courses/#{@course.id}/wiki/test-wiki-page-2?titleize=0'>wiki page</a>
            <a href='/courses/#{@course.id}/pages'>wiki index</a>
            <a href='/courses/#{@course.id}/pages/test-wiki-page'>wiki page</a>
            <a href='/courses/#{@course.id}/pages/test-wiki%20page-2?titleize=0'>wiki page</a>
            <a href='/courses/#{@course.id}/discussion_topics'>discussion index</a>
            <a href='/courses/#{@course.id}/discussion_topics/456'>discussion topic</a>
            <a href='/courses/#{@course.id}/files'>files index</a>
            <a href='/courses/#{@course.id}/files/789/download?verifier=lolcats'>files index</a>
            <a href='/files/789/download?verifier=lolcats'>file</a>
            <a href='/courses/#{@course.id}/quizzes'>quiz index</a>
            <a href='/courses/#{@course.id}/quizzes/999'>quiz</a>
            <a href='/courses/#{@course.id}/modules'>modules index</a>
            <a href='/courses/#{@course.id}/modules/1024'>module</a>
            <a href='/courses/#{@course.id}/external_tools/retrieve?url=http://lti-tool-provider.example.com/lti_tool'>LTI Launch</a>
          </p>
        HTML
        @wiki_page.workflow_state = "active"
        @wiki_page.save!

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}",
                        { controller: "wiki_pages_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          url_or_id: @wiki_page.url })
        doc = Nokogiri::HTML5.fragment(json["body"])
        expect(doc.css("a").pluck("data-api-endpoint")).to eq [
          "http://www.example.com/api/v1/courses/#{@course.id}/assignments",
          "http://www.example.com/api/v1/courses/#{@course.id}/assignments/9~123",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages/test-wiki-page",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages/test-wiki-page-2",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages/test-wiki-page",
          "http://www.example.com/api/v1/courses/#{@course.id}/pages/test-wiki%2520page-2",
          "http://www.example.com/api/v1/courses/#{@course.id}/discussion_topics",
          "http://www.example.com/api/v1/courses/#{@course.id}/discussion_topics/456",
          "http://www.example.com/api/v1/courses/#{@course.id}/folders/root",
          "http://www.example.com/api/v1/courses/#{@course.id}/files/789",
          "http://www.example.com/api/v1/files/789",
          "http://www.example.com/api/v1/courses/#{@course.id}/quizzes",
          "http://www.example.com/api/v1/courses/#{@course.id}/quizzes/999",
          "http://www.example.com/api/v1/courses/#{@course.id}/modules",
          "http://www.example.com/api/v1/courses/#{@course.id}/modules/1024",
          "http://www.example.com/api/v1/courses/#{@course.id}/external_tools/sessionless_launch?url=http%3A%2F%2Flti-tool-provider.example.com%2Flti_tool"
        ]
        expect(doc.css("a").pluck("data-api-returntype")).to eq(
          %w([Assignment] Assignment [Page] Page Page [Page] Page Page [Discussion] Discussion Folder File File [Quiz] Quiz [Module] Module SessionlessLaunchUrl)
        )
      end
    end

    context "group context" do
      it "processes links to each type of object" do
        group_with_user(active_all: true)
        @wiki_page = @group.wiki_pages.build(title: "title")
        @wiki_page.body = <<~HTML
          <p>
            <a href='/groups/#{@group.id}/wiki'>wiki index</a>
            <a href='/groups/#{@group.id}/wiki/some-page'>wiki page</a>
            <a href='/groups/#{@group.id}/pages'>wiki index</a>
            <a href='/groups/#{@group.id}/pages/some-page'>wiki page</a>
            <a href='/groups/#{@group.id}/discussion_topics'>discussion index</a>
            <a href='/groups/#{@group.id}/discussion_topics/1~123'>discussion topic</a>
            <a href='/groups/#{@group.id}/files'>files index</a>
            <a href='/groups/#{@group.id}/files/789/preview'>file</a>
          </p>
        HTML
        @wiki_page.workflow_state = "active"
        @wiki_page.save!

        json = api_call(:get,
                        "/api/v1/groups/#{@group.id}/pages/#{@wiki_page.url}",
                        { controller: "wiki_pages_api",
                          action: "show",
                          format: "json",
                          group_id: @group.id.to_s,
                          url_or_id: @wiki_page.url })
        doc = Nokogiri::HTML5.fragment(json["body"])
        expect(doc.css("a").pluck("data-api-endpoint")).to eq [
          "http://www.example.com/api/v1/groups/#{@group.id}/pages",
          "http://www.example.com/api/v1/groups/#{@group.id}/pages/some-page",
          "http://www.example.com/api/v1/groups/#{@group.id}/pages",
          "http://www.example.com/api/v1/groups/#{@group.id}/pages/some-page",
          "http://www.example.com/api/v1/groups/#{@group.id}/discussion_topics",
          "http://www.example.com/api/v1/groups/#{@group.id}/discussion_topics/1~123",
          "http://www.example.com/api/v1/groups/#{@group.id}/folders/root",
          "http://www.example.com/api/v1/groups/#{@group.id}/files/789"
        ]
        expect(doc.css("a").pluck("data-api-returntype")).to eq(
          %w([Page] Page [Page] Page [Discussion] Discussion Folder File)
        )
      end
    end

    context "user context" do
      it "processes links to each type of object" do
        @topic = @course.discussion_topics.create!(message: <<~HTML)
          <a href='/users/#{@teacher.id}/files'>file index</a>
          <a href='/users/#{@teacher.id}/files/789/preview'>file</a>
        HTML

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        controller: "discussion_topics_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        topic_id: @topic.id.to_s)
        doc = Nokogiri::HTML5.fragment(json["message"])
        expect(doc.css("a").pluck("data-api-endpoint")).to eq [
          "http://www.example.com/api/v1/users/#{@teacher.id}/folders/root",
          "http://www.example.com/api/v1/users/#{@teacher.id}/files/789"
        ]
        expect(doc.css("a").pluck("data-api-returntype")).to eq(
          %w[Folder File]
        )
      end
    end
  end

  context "process_incoming_html_content" do
    let(:tester) { Class.new { include Api }.new }

    it "adds the expected href to instructure_inline_media_comment anchors" do
      factory_with_protected_attributes(MediaObject, media_id: "test2", media_type: "audio")
      html = tester.process_incoming_html_content(<<~HTML)
        <a id='something-else' href='/blah'>no touchy</a>
        <a class='instructure_inline_media_comment audio_comment'>no id</a>
        <a id='media_comment_test1' class='instructure_inline_media_comment audio_comment'>with id</a>
        <a id='media_comment_test2' class='instructure_inline_media_comment'>id, no type</a>
        <a id='media_comment_test3' class='instructure_inline_media_comment'>id, no type, missing object</a>
      HTML

      doc = Nokogiri::HTML5.fragment(html)
      anchors = doc.css("a")
      expect(anchors[0]["id"]).to eq "something-else"
      expect(anchors[0]["href"]).to eq "/blah"
      expect(anchors[1]["href"]).to be_nil
      expect(anchors[2]["href"]).to eq "/media_objects/test1"
      expect(anchors[2]["class"]).to eq "instructure_inline_media_comment audio_comment"
      expect(anchors[3]["class"]).to eq "instructure_inline_media_comment audio_comment" # media_type added by code
      expect(anchors[3]["href"]).to eq "/media_objects/test2"
      expect(anchors[4]["class"]).to eq "instructure_inline_media_comment" # media object not found, no type added
      expect(anchors[4]["href"]).to eq "/media_objects/test3"
    end

    it "translates video and audio instructure_inline_media_comment tags" do
      html = tester.process_incoming_html_content(<<~HTML)
        <video src='/other'></video>
        <video class='instructure_inline_media_comment' src='/some/redirect/url'>no media id</video>
        <video class='instructure_inline_media_comment' src='/some/redirect/url' data-media_comment_id='test1'>with media id</video>
        <audio class='instructure_inline_media_comment' src='/some/redirect/url' data-media_comment_id='test2'>with media id</video>
      HTML

      doc = Nokogiri::HTML5.fragment(html)
      tags = doc.css("audio,video,a")
      expect(tags[0].name).to eq "video"
      expect(tags[0]["src"]).to eq "/other"
      expect(tags[0]["class"]).to be_nil
      expect(tags[1].name).to eq "video"
      expect(tags[2].name).to eq "a"
      expect(tags[2]["class"]).to eq "instructure_inline_media_comment video_comment"
      expect(tags[2]["href"]).to eq "/media_objects/test1"
      expect(tags[2]["id"]).to eq "media_comment_test1"
      expect(tags[3].name).to eq "a"
      expect(tags[3]["class"]).to eq "instructure_inline_media_comment audio_comment"
      expect(tags[3]["href"]).to eq "/media_objects/test2"
      expect(tags[3]["id"]).to eq "media_comment_test2"
    end

    context "with verified user-context file links" do
      before do
        user_factory
        attachment_model context: @user
      end

      def confirm_url_stability(url)
        link = %(<a href="#{url}">what</a>)
        html = tester.process_incoming_html_content(link)
        doc = Nokogiri::HTML5.fragment(html)
        expect(doc.at_css("a")["href"]).to eq url
      end

      it "ignores them when scoped to the file" do
        url = "/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
        confirm_url_stability(url)
      end

      it "ignores them when scoped to the user" do
        url = "/users/#{@user.id}/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
        confirm_url_stability(url)
      end

      it "ignores them when they include the host" do
        url = "http://somedomain.instructure.com/files/#{@attachment.id}/download?verifier=#{@attachment.uuid}"
        confirm_url_stability(url)
      end
    end
  end

  describe ".api_bulk_load_user_content_attachments" do
    it "returns a hash of assignment_id => assignment" do
      a1, a2, a3 = attachment_model, attachment_model, attachment_model
      html1, html2 = <<~HTML1, <<~HTML2
        <a href="/courses/#{@course.id}/files/#{a1.id}/download">uh...</a>
        <img src="/courses/#{@course.id}/files/#{a2.id}/download">
      HTML1
        <a href="/courses/#{@course.id}/files/#{a3.id}/download">Hi</a>
      HTML2

      expect(Class.new { include Api }.new.api_bulk_load_user_content_attachments(
               [html1, html2],
               @course
             )).to eq({ a1.id => a1, a2.id => a2, a3.id => a3 })
    end
  end

  describe "latex_to_mathml" do
    it "returns mathml on success" do
      valid_latex = '\frac{a}{b}'
      expect(UserContent.latex_to_mathml(valid_latex)).to eql(%(<math xmlns="http://www.w3.org/1998/Math/MathML" display="inline"><mfrac><mrow><mi>a</mi></mrow><mrow><mi>b</mi></mrow></mfrac></math>))
    end

    it "returns empty string on parse error" do
      invalid_latex = '\frac{a}{'
      expect(UserContent.latex_to_mathml(invalid_latex)).to eql("")
    end
  end

  describe "escape" do
    describe "with equation images" do
      context "valid latex" do
        before do
          @latex = '\frac{a}{b}'
          @html = "<img class='equation_image' alt='#{@latex}' />"
        end

        it "retains the alt attribute" do
          escaped = UserContent.escape(@html)
          node = Nokogiri::HTML5.fragment(escaped).css("img").first
          expect(node["alt"]).to eql(@latex)
        end

        it "adds mathml in a span" do
          escaped = UserContent.escape(@html, nil, false)
          node = Nokogiri::HTML5.fragment(escaped).css("img").first.next_sibling
          expect(node.node_name).to eql("span")
          expect(node.inner_html).to eql(Ritex::Parser.new.parse(@latex))
        end
      end

      context "invalid latex" do
        before do
          @latex = '\frac{a}{' # incomplete
          @html = "<img class='equation_image' alt='#{@latex}' />"
        end

        it "handles error gracefully" do
          expect { UserContent.escape(@html) }.not_to raise_error
        end

        it "retains the alt attribute" do
          escaped = UserContent.escape(@html)
          node = Nokogiri::HTML5.fragment(escaped).css("img").first
          expect(node["alt"]).to eql(@latex)
        end

        it "doesn't add mathml span" do
          escaped = UserContent.escape(@html)
          node = Nokogiri::HTML5.fragment(escaped).css("span").first
          expect(node).to be_nil
        end
      end
    end
  end
end
