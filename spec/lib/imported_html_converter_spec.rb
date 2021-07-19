# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ImportedHtmlConverter do
  # tests link_parser and link_resolver

  context ".convert" do
    before :once do
      course_factory
      @path = "/courses/#{@course.id}/"
      @migration = @course.content_migrations.create!
      @converter = @migration.html_converter
    end

    def convert_and_replace(test_string)
      html = @migration.convert_html(test_string, 'sometype', 'somemigid', 'somefield')
      link_map = @converter.link_parser.unresolved_link_map

      @converter.link_resolver.resolve_links!(link_map)
      if link_map.present?
        @converter.link_replacer.sub_placeholders!(html, link_map.values.map(&:values).flatten)
      end
      html
    end

    it "should convert a wiki reference" do
      test_string = %{<a href="%24WIKI_REFERENCE%24/wiki/test-wiki-page?query=blah">Test Wiki Page</a>}
      @course.wiki_pages.create!(:title => "Test Wiki Page", :body => "stuff")

      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}pages/test-wiki-page?query=blah">Test Wiki Page</a>}
    end

    it "should convert a wiki reference without $ escaped" do
      test_string = %{<a href="$WIKI_REFERENCE$/wiki/test-wiki-page?query=blah">Test Wiki Page</a>}
      @course.wiki_pages.create!(:title => "Test Wiki Page", :body => "stuff")

      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}pages/test-wiki-page?query=blah">Test Wiki Page</a>}
    end

    it "should convert a wiki reference by migration id" do
      test_string = %{<a href="wiki_page_migration_id=123456677788">Test Wiki Page</a>}
      wiki = @course.wiki_pages.create(:title => "Test Wiki Page", :body => "stuff")
      wiki.migration_id = "123456677788"
      wiki.save!

      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}pages/test-wiki-page">Test Wiki Page</a>}
    end

    it "should convert a discussion reference by migration id" do
      test_string = %{<a href="discussion_topic_migration_id=123456677788">Test topic</a>}
      topic = @course.discussion_topics.create(:title => "Test discussion")
      topic.migration_id = "123456677788"
      topic.save!

      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}discussion_topics/#{topic.id}">Test topic</a>}
    end

    def make_test_att
      att = Attachment.create(:filename => 'test.png', :display_name => "test.png", :uploaded_data => StringIO.new('psych!'), :folder => Folder.unfiled_folder(@course), :context => @course)
      att.migration_id = "1768525836051"
      att.save!
      att
    end

    it "should find an attachment by migration id" do
      att = make_test_att()

      test_string = %{<p>This is an image: <br /><img src="%24CANVAS_OBJECT_REFERENCE%24/attachments/1768525836051" alt=":(" /></p>}
      expect(convert_and_replace(test_string)).to eq %{<p>This is an image: <br><img src="#{@path}files/#{att.id}/preview" alt=":("></p>}
    end

    it "should find an attachment by path" do
      att = make_test_att()

      test_string = %{<p>This is an image: <br /><img src="%24IMS_CC_FILEBASE%24/test.png" alt=":(" /></p>}

      # if there isn't a path->migration id map it'll be a relative course file path
      expect(convert_and_replace(test_string)).to eq %{<p>This is an image: <br><img src="#{@path}file_contents/course%20files/test.png" alt=":("></p>}

      @migration.attachment_path_id_lookup = {"test.png" => att.migration_id}
      expect(convert_and_replace(test_string)).to eq %{<p>This is an image: <br><img src="#{@path}files/#{att.id}/preview" alt=":("></p>}
    end

    it "should find an attachment by a path with a space" do
      att = make_test_att()
      @migration.attachment_path_id_lookup = {"subfolder/with a space/test.png" => att.migration_id}

      test_string = %{<img src="subfolder/with%20a%20space/test.png" alt="nope" />}
      expect(convert_and_replace(test_string)).to eq %{<img src="#{@path}files/#{att.id}/preview" alt="nope">}

      test_string = %{<img src="subfolder/with+a+space/test.png" alt="nope" />}
      expect(convert_and_replace(test_string)).to eq %{<img src="#{@path}files/#{att.id}/preview" alt="nope">}
    end

    it "should find an attachment even if the link has an extraneous folder" do
      att = make_test_att()
      @migration.attachment_path_id_lookup = {"subfolder/test.png" => att.migration_id}

      test_string = %{<img src="anotherfolder/subfolder/test.png" alt="nope" />}
      expect(convert_and_replace(test_string)).to eq %{<img src="#{@path}files/#{att.id}/preview" alt="nope">}
    end

    it "should find an attachment by path if capitalization is different" do
      att = make_test_att()
      @migration.attachment_path_id_lookup = {"subfolder/withCapital/test.png" => "wrong!"}
      @migration.attachment_path_id_lookup_lower = {"subfolder/withcapital/test.png" => att.migration_id}

      test_string = %{<img src="subfolder/WithCapital/TEST.png" alt="nope" />}
      expect(convert_and_replace(test_string)).to eq %{<img src="#{@path}files/#{att.id}/preview" alt="nope">}
    end

    it "should find an attachment with query params" do
      att = make_test_att()
      @migration.attachment_path_id_lookup = {"test.png" => att.migration_id}

      test_string = %{<img src="%24IMS_CC_FILEBASE%24/test.png?canvas_customaction=1&canvas_qs_customparam=1" alt="nope" />}
      expect(convert_and_replace(test_string)).to eq %{<img src="#{@path}files/#{att.id}/customaction?customparam=1" alt="nope">}

      test_string = %{<img src="%24IMS_CC_FILEBASE%24/test.png?canvas_qs_customparam2=3" alt="nope" />}
      expect(convert_and_replace(test_string)).to eq %{<img src="#{@path}files/#{att.id}/preview?customparam2=3" alt="nope">}

      test_string = %{<img src="%24IMS_CC_FILEBASE%24/test.png?notarelevantparam" alt="nope" />}
      expect(convert_and_replace(test_string)).to eq %{<img src="#{@path}files/#{att.id}/preview" alt="nope">}
    end

    it "should convert course section urls" do
      test_string = %{<a href="%24CANVAS_COURSE_REFERENCE%24/discussion_topics">discussions</a>}
      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}discussion_topics">discussions</a>}
    end

    it "should leave invalid and absolute urls alone" do
      test_string = %{<a href="stupid &^%$ url">Linkage</a><br><a href="http://www.example.com/poop">Linkage</a>}
      expect(convert_and_replace(test_string)).to eq %{<a href="stupid &amp;^%$ url">Linkage</a><br><a href="http://www.example.com/poop">Linkage</a>}
    end

    it "should prepend course files for unrecognized relative urls" do
      test_string = %{<a href="/relative/path/to/file">Linkage</a>}
      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}file_contents/course%20files/relative/path/to/file">Linkage</a>}
      test_string = %{<a href="relative/path/to/file">Linkage</a>}
      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}file_contents/course%20files/relative/path/to/file">Linkage</a>}
      test_string = %{<a href="relative/path/to/file%20with%20space.html">Linkage</a>}
      expect(convert_and_replace(test_string)).to eq %{<a href="#{@path}file_contents/course%20files/relative/path/to/file%20with%20space.html">Linkage</a>}
    end

    it "should preserve media comment links" do
      test_string = <<-HTML.strip
      <p>
        with media object url: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
        with file content url: <a id="media_comment_0_bq09qam2" class="instructure_inline_media_comment video_comment" href="/courses/#{@course.id}/file_contents/course%20files/media_objects/0_bq09qam2">this is a media comment</a>
      </p>
      HTML

      expect(convert_and_replace(test_string)).to eq test_string
    end

    it "should handle and repair half broken media links" do
      test_string = %{<p><a href="/courses/#{@course.id}/file_contents/%24IMS_CC_FILEBASE%24/#" class="instructure_inline_media_comment video_comment" id="media_comment_0_l4l5n0wt">this is a media comment</a><br><br></p>}

      expect(convert_and_replace(test_string)).to eq %{<p><a href="/media_objects/0_l4l5n0wt" class="instructure_inline_media_comment video_comment" id="media_comment_0_l4l5n0wt">this is a media comment</a><br><br></p>}
    end

    it "should preserve new RCE media iframes" do
      test_string = %{<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_objects_iframe/0_l4l5n0wt?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>}
      expect(convert_and_replace(test_string)).to eq test_string
    end

    it "should handle and repair half broken new RCE media iframes" do
      test_string = %{<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="%24IMS_CC_FILEBASE%24/#" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-abcde"></iframe>}
      repaired_string = %{<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_objects_iframe/m-abcde?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-abcde"></iframe>}
      expect(convert_and_replace(test_string)).to eq repaired_string
    end

    it "should only convert url params" do
      test_string = <<-HTML
<object>
<param name="controls" value="CONSOLE" />
<param name="controller" value="true" />
<param name="autostart" value="false" />
<param name="loop" value="false" />
<param name="src" value="%24IMS_CC_FILEBASE%24/test.mp3" />
<EMBED name="tag"  src="%24IMS_CC_FILEBASE%24/test.mp3" loop="false" autostart="false" controller="true" controls="CONSOLE" >
</EMBED>
</object>
      HTML

      expect(convert_and_replace(test_string)).to match_ignoring_whitespace(<<-HTML.strip)
<object>
<param name="controls" value="CONSOLE">
<param name="controller" value="true">
<param name="autostart" value="false">
<param name="loop" value="false">
<param name="src" value="/courses/#{@course.id}/file_contents/course%20files/test.mp3">
<embed name="tag" src="/courses/#{@course.id}/file_contents/course%20files/test.mp3" loop="false" autostart="false" controller="true" controls="CONSOLE"></object>
    HTML
    end

    it "should leave an anchor tag alone" do
      test_string = '<p><a href="#anchor_ref">ref</a></p>'
      expect(convert_and_replace(test_string)).to eq test_string
    end

    it "should convert base64 images to file links" do
      base64 = "R0lGODlhCQAJAIAAAICAgP///yH5BAEAAAEALAAAAAAJAAkAAAIQTGCZgGrc\nFIxvSuhwpsuFAgA7\n"
      test_string = "<p><img src=\"data:image/gif;base64,#{base64}\"></p>"
      new_string = convert_and_replace(test_string)
      attachment = Attachment.last
      expect(attachment.content_type).to eq 'image/gif'
      expect(attachment.name).to eq "7d8c0162b3f46d1e0ca56d53913d1cef67d672c0989c20141381a5f30f0bc481.gif"
      expect(new_string).to eq "<p><img src=\"/courses/#{@course.id}/files/#{attachment.id}/preview\"></p>"
    end

  end

  context ".relative_url?" do
    it "should recognize an absolute url" do
      expect(ImportedHtmlConverter.relative_url?("http://example.com")).to eq false
    end

    it "should recognize relative urls" do
      expect(ImportedHtmlConverter.relative_url?("/relative/eh")).to eq true
      expect(ImportedHtmlConverter.relative_url?("also/relative")).to eq true
      expect(ImportedHtmlConverter.relative_url?("watup/nothing.html#anchoritbaby")).to eq true
      expect(ImportedHtmlConverter.relative_url?("watup/nothing?absolutely=1")).to eq true
    end

    it "should not error on invalid urls" do
      expect(ImportedHtmlConverter.relative_url?("stupid &^%$ url")).to be_falsey
      expect(ImportedHtmlConverter.relative_url?("mailto:jfarnsworth@instructure.com,")).to be_falsey
    end
  end

end
