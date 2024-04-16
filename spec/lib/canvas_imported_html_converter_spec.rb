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

describe CanvasImportedHtmlConverter do
  # tests link_parser and link_resolver
  before :once do
    course_factory
    @path = "/courses/#{@course.id}/"
    @migration = @course.content_migrations.create!
    @converter = @migration.html_converter
  end

  describe ".convert" do
    def convert_exported_html(*args)
      @converter.convert_exported_html(*args)[0]
    end

    it "converts a wiki reference" do
      test_string = %(<a href="%24WIKI_REFERENCE%24/wiki/test-wiki-page?query=blah">Test Wiki Page</a>)
      @course.wiki_pages.create!(title: "Test Wiki Page", body: "stuff")

      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}pages/test-wiki-page?query=blah">Test Wiki Page</a>)
    end

    context "when course attachments exist" do
      subject { convert_exported_html(test_string) }

      let_once(:attachment) { attachment_model(context: course, migration_id:) }
      let(:course) { @course }
      let(:migration_id) { "migration-id-123" }

      context "and a data-download-url attribute references an icon maker icon" do
        let(:test_string) do
          %(<img src="$CANVAS_COURSE_REFERENCE$/file_ref/#{migration_id}/download?download_frd=1" alt="" data-inst-icon-maker-icon="true" data-download-url="$CANVAS_COURSE_REFERENCE$/file_ref/#{migration_id}/download?download_frd=1&icon_maker_icon=1">)
        end

        it "converst data-download-url for files without appending a context" do
          expect(subject).to eq(
            "<img src=\"/courses/#{course.id}/files/#{attachment.id}/download?download_frd=1\" alt=\"\" data-inst-icon-maker-icon=\"true\" data-download-url=\"/files/#{attachment.id}/download?download_frd=1&icon_maker_icon=1\">"
          )
        end
      end
    end

    it "converts picture source srcsets" do
      test_string = %(<source srcset="$CANVAS_COURSE_REFERENCE$/img.src">)
      expect(convert_exported_html(test_string)).to eq %(<source srcset="/courses/#{@course.id}/img.src">)
    end

    it "converts a wiki reference without $ escaped" do
      test_string = %(<a href="$WIKI_REFERENCE$/wiki/test-wiki-page?query=blah">Test Wiki Page</a>)
      @course.wiki_pages.create!(title: "Test Wiki Page", body: "stuff")

      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}pages/test-wiki-page?query=blah">Test Wiki Page</a>)
    end

    it "converts a wiki reference by migration id" do
      test_string = %(<a href="wiki_page_migration_id=123456677788">Test Wiki Page</a>)
      wiki = @course.wiki_pages.create(title: "Test Wiki Page", body: "stuff")
      wiki.migration_id = "123456677788"
      wiki.save!

      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}pages/test-wiki-page">Test Wiki Page</a>)
    end

    it "converts a discussion reference by migration id" do
      test_string = %(<a href="discussion_topic_migration_id=123456677788">Test topic</a>)
      topic = @course.discussion_topics.create(title: "Test discussion")
      topic.migration_id = "123456677788"
      topic.save!

      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}discussion_topics/#{topic.id}">Test topic</a>)
    end

    def make_test_att
      att = Attachment.create(filename: "test.png", display_name: "test.png", uploaded_data: StringIO.new("psych!"), folder: Folder.unfiled_folder(@course), context: @course)
      att.migration_id = "1768525836051"
      att.save!
      att
    end

    it "finds an attachment by migration id" do
      att = make_test_att

      test_string = %{<p>This is an image: <br /><img src="%24CANVAS_OBJECT_REFERENCE%24/attachments/1768525836051" alt=":(" /></p>}
      expect(convert_exported_html(test_string)).to eq %{<p>This is an image: <br><img src="#{@path}files/#{att.id}/preview" alt=":("></p>}
    end

    it "finds an attachment by path" do
      att = make_test_att

      test_string = %{<p>This is an image: <br /><img src="%24IMS_CC_FILEBASE%24/test.png" alt=":(" /></p>}

      # if there isn't a path->migration id map it'll be a relative course file path
      expect(convert_exported_html(test_string)).to eq %{<p>This is an image: <br><img src="#{@path}file_contents/course%20files/test.png" alt=":("></p>}

      @migration.attachment_path_id_lookup = { "test.png" => att.migration_id }
      expect(convert_exported_html(test_string)).to eq %{<p>This is an image: <br><img src="#{@path}files/#{att.id}/preview" alt=":("></p>}
    end

    it "finds an attachment by a path with a space" do
      att = make_test_att
      @migration.attachment_path_id_lookup = { "subfolder/with a space/test.png" => att.migration_id }

      test_string = %(<img src="subfolder/with%20a%20space/test.png" alt="nope" />)
      expect(convert_exported_html(test_string)).to eq %(<img src="#{@path}files/#{att.id}/preview" alt="nope">)

      test_string = %(<img src="subfolder/with+a+space/test.png" alt="nope" />)
      expect(convert_exported_html(test_string)).to eq %(<img src="#{@path}files/#{att.id}/preview" alt="nope">)
    end

    it "finds an attachment even if the link has an extraneous folder" do
      att = make_test_att
      @migration.attachment_path_id_lookup = { "subfolder/test.png" => att.migration_id }

      test_string = %(<img src="anotherfolder/subfolder/test.png" alt="nope" />)
      expect(convert_exported_html(test_string)).to eq %(<img src="#{@path}files/#{att.id}/preview" alt="nope">)
    end

    it "finds an attachment by path if capitalization is different" do
      att = make_test_att
      @migration.attachment_path_id_lookup = { "subfolder/withCapital/test.png" => "wrong!" }
      @converter.link_resolver.instance_variable_set(:@attachment_path_id_lookup_lower, { "subfolder/withcapital/test.png" => att.migration_id })

      test_string = %(<img src="subfolder/WithCapital/TEST.png" alt="nope" />)
      expect(convert_exported_html(test_string)).to eq %(<img src="#{@path}files/#{att.id}/preview" alt="nope">)
    end

    it "finds an attachment with query params" do
      att = make_test_att
      @migration.attachment_path_id_lookup = { "test.png" => att.migration_id }

      test_string = %(<img src="%24IMS_CC_FILEBASE%24/test.png?canvas_customaction=1&canvas_qs_customparam=1" alt="nope" />)
      expect(convert_exported_html(test_string)).to eq %(<img src="#{@path}files/#{att.id}/customaction?customparam=1" alt="nope">)

      test_string = %(<img src="%24IMS_CC_FILEBASE%24/test.png?canvas_qs_customparam2=3" alt="nope" />)
      expect(convert_exported_html(test_string)).to eq %(<img src="#{@path}files/#{att.id}/preview?customparam2=3" alt="nope">)

      test_string = %(<img src="%24IMS_CC_FILEBASE%24/test.png?notarelevantparam" alt="nope" />)
      expect(convert_exported_html(test_string)).to eq %(<img src="#{@path}files/#{att.id}/preview" alt="nope">)
    end

    it "adds links with media_attachment query value as a media_attachment" do
      att = make_test_att
      att.update!(media_entry_id: "m-yodawg")
      @migration.attachment_path_id_lookup = { "Uploaded Media 2/yodawg.mp4" => att.migration_id }
      test_string = %(<video data-media-type="video" data-media-id="m-yodawg"><source src="$IMS-CC-FILEBASE$/Uploaded%20Media%202/yodawg.mp4?canvas_=1&amp;canvas_qs_amp=&amp;canvas_qs_embedded=true&amp;canvas_qs_type=video&amp;media_attachment=true" data-media-id="m-yodawg" data-media-type="video"></video>)
      expect(convert_exported_html(test_string)).to eq %(<iframe data-media-type="video" data-media-id="m-yodawg" src="/media_attachments_iframe/#{att.id}?embedded=true&amp;type=video"></iframe>)
    end

    it "converts course section urls" do
      test_string = %(<a href="%24CANVAS_COURSE_REFERENCE%24/discussion_topics">discussions</a>)
      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}discussion_topics">discussions</a>)
    end

    it "leaves invalid and absolute urls alone" do
      test_string = %(<a href="stupid &^%$ url">Linkage</a><br><a href="http://www.example.com/poop">Linkage</a>)
      expect(convert_exported_html(test_string)).to eq %(<a href="stupid &amp;^%$ url">Linkage</a><br><a href="http://www.example.com/poop">Linkage</a>)
    end

    it "leaves invalid mailto addresses alone" do
      test_string = %(<a href="mailto:.">Bad mailto</a><br><a href="mailto:test@example.com">Good mailto</a>)
      expect(convert_exported_html(test_string)).to eq(
        %(<a href="mailto:.">Bad mailto</a><br><a href="mailto:test@example.com">Good mailto</a>)
      )
    end

    it "recognizes and relative-ize absolute links outside the course but in one of the course's domains" do
      allow(HostUrl).to receive(:context_hosts).with(@course.root_account).and_return(["my-canvas.example.com", "vanity.my-canvas.edu"])
      test_string = %(<a href="https://my-canvas.example.com/courses/123">Mine</a><br><a href="https://vanity.my-canvas.edu/courses/456">Vain</a><br><a href="http://other-canvas.example.com/">Other Instance</a>)
      expect(convert_exported_html(test_string)).to eq %(<a href="/courses/123">Mine</a><br><a href="/courses/456">Vain</a><br><a href="http://other-canvas.example.com/">Other Instance</a>)
    end

    it "prepends course files for unrecognized relative urls" do
      test_string = %(<a href="/relative/path/to/file">Linkage</a>)
      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}file_contents/course%20files/relative/path/to/file">Linkage</a>)
      test_string = %(<a href="relative/path/to/file">Linkage</a>)
      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}file_contents/course%20files/relative/path/to/file">Linkage</a>)
      test_string = %(<a href="relative/path/to/file%20with%20space.html">Linkage</a>)
      expect(convert_exported_html(test_string)).to eq %(<a href="#{@path}file_contents/course%20files/relative/path/to/file%20with%20space.html">Linkage</a>)
    end

    it "changes media comment links to media_attachment_iframe link" do
      file1 = attachment_model(context: @course, media_entry_id: "0_l4l5n0wt", display_name: "test.mp4")
      media_object(media_id: "0_l4l5n0wt", attachment: file1)
      file2 = attachment_model(context: @course, media_entry_id: "0_bq09qam2", display_name: "test2.mp4")
      media_object(media_id: "0_bq09qam2", attachment: file2)
      test_string = <<~HTML.strip
        <p>
          with media object url: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
          with file content url: <a id="media_comment_0_bq09qam2" class="instructure_inline_media_comment video_comment" href="/courses/#{@course.id}/file_contents/course%20files/test2.mp4">this is a media comment</a>
        </p>
      HTML

      replacement_string = <<~HTML.strip
        <p>
          with media object url: <iframe id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file1.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>
          with file content url: <iframe id="media_comment_0_bq09qam2" class="instructure_inline_media_comment video_comment" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file2.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_bq09qam2"></iframe>
        </p>
      HTML

      expect(convert_exported_html(test_string)).to eq replacement_string
    end

    it "handles and repair half broken media links" do
      file = attachment_model(context: @course, media_entry_id: "0_l4l5n0wt", display_name: "test.mp4")
      media_object(media_id: "0_l4l5n0wt", attachment: file)

      test_string = %(<p><a href="/courses/#{@course.id}/file_contents/%24IMS_CC_FILEBASE%24/#" class="instructure_inline_media_comment video_comment" id="media_comment_0_l4l5n0wt">this is a media comment</a></p>)
      expect(convert_exported_html(test_string)).to eq %(<p><iframe class="instructure_inline_media_comment video_comment" id="media_comment_0_l4l5n0wt" style="width: 320px; height: 240px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe></p>)
    end

    it "converts old RCE media object iframes" do
      file = attachment_model(context: @course, media_entry_id: "0_l4l5n0wt", display_name: "test.mp4")
      media_object(media_id: "0_l4l5n0wt", attachment: file)

      test_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_objects_iframe/0_l4l5n0wt?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>)
      converted_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"></iframe>)
      expect(convert_exported_html(test_string)).to eq converted_string
    end

    it "handles and repair half broken new RCE media iframes" do
      file = attachment_model(context: @course, media_entry_id: "m-abcde", display_name: "test.mp4")
      media_object(media_id: "m-abcde", attachment: file)

      test_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="%24IMS_CC_FILEBASE%24/#" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-abcde"></iframe>)
      repaired_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{file.id}?embedded=true&amp;type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="m-abcde"></iframe>)
      expect(convert_exported_html(test_string)).to eq repaired_string
    end

    it "converts source tags to RCE media iframes" do
      file = attachment_model(context: @course, media_entry_id: "0_l4l5n0wt", display_name: "test.mp4")
      media_object(media_id: "0_l4l5n0wt", attachment: file)

      test_string = %(<video style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"><source src="/media_objects_iframe/0_l4l5n0wt?embedded=true&type=video" data-media-id="0_l4l5n0wt" data-media-type="video"></video>)
      converted_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{file.id}?embedded=true&amp;type=video"></iframe>)
      expect(convert_exported_html(test_string)).to eq converted_string

      test_string = %(<audio style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="audio" data-media-id="0_l4l5n0wt"><source src="/media_objects_iframe/0_l4l5n0wt?type=audio" data-media-id="0_l4l5n0wt" data-media-type="audio"></audio>)
      converted_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="audio" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{file.id}?embedded=true&amp;type=audio"></iframe>)
      expect(convert_exported_html(test_string)).to eq converted_string
    end

    it "converts source tags to RCE media attachment iframes" do
      att = make_test_att

      test_string = %(<video style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"><source src="$CANVAS_OBJECT_REFERENCE$/media_attachments_iframe/#{att.migration_id}?type=video" data-media-id="0_l4l5n0wt" data-media-type="video"></video>)
      converted_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{att.id}?type=video"></iframe>)
      expect(convert_exported_html(test_string)).to eq converted_string

      test_string = %(<audio  style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="audio" data-media-id="0_l4l5n0wt"><source src="$CANVAS_OBJECT_REFERENCE$/media_attachments_iframe/#{att.migration_id}?type=audio" data-media-id="0_l4l5n0wt" data-media-type="audio"></video>)
      converted_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="audio" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{att.id}?type=audio"></iframe>)
      expect(convert_exported_html(test_string)).to eq converted_string
    end

    it "converts source tags to RCE media attachment iframes when link is an unknown media attachment reference (link from a public file in another course)" do
      att = make_test_att

      test_string = %(<video style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt"><source src="/media_attachments_iframe/#{att.id}?type=video" data-media-id="0_l4l5n0wt" data-media-type="video"></video>)
      converted_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{att.id}?type=video"></iframe>)
      expect(convert_exported_html(test_string)).to eq converted_string

      test_string = %(<audio  style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="audio" data-media-id="0_l4l5n0wt"><source src="/media_attachments_iframe/#{att.id}?type=audio" data-media-id="0_l4l5n0wt" data-media-type="audio"></video>)
      converted_string = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="audio" data-media-id="0_l4l5n0wt" src="/media_attachments_iframe/#{att.id}?type=audio"></iframe>)
      expect(convert_exported_html(test_string)).to eq converted_string
    end

    it "leaves source tags without data-media-id alone" do
      test_string = %(<video style="width: 400px; height: 225px; display: inline-block;" title="this is a non-canvas video" allowfullscreen="allowfullscreen" allow="fullscreen"><source src="http://www.example.com/video.mov"></video>)
      expect(convert_exported_html(test_string)).to eq test_string
    end

    it "only converts url params" do
      test_string = <<~HTML
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

      expect(convert_exported_html(test_string)).to match_ignoring_whitespace(<<~HTML.strip)
        <object>
        <param name="controls" value="CONSOLE">
        <param name="controller" value="true">
        <param name="autostart" value="false">
        <param name="loop" value="false">
        <param name="src" value="/courses/#{@course.id}/file_contents/course%20files/test.mp3">
        <embed name="tag" src="/courses/#{@course.id}/file_contents/course%20files/test.mp3" loop="false" autostart="false" controller="true" controls="CONSOLE"></object>
      HTML
    end

    it "leaves an anchor tag alone" do
      test_string = '<p><a href="#anchor_ref">ref</a></p>'
      expect(convert_exported_html(test_string)).to eq test_string
    end

    it "converts base64 images to file links" do
      base64 = "R0lGODlhCQAJAIAAAICAgP///yH5BAEAAAEALAAAAAAJAAkAAAIQTGCZgGrc\nFIxvSuhwpsuFAgA7\n"
      test_string = "<p><img src=\"data:image/gif;base64,#{base64}\"></p>"
      new_string = convert_exported_html(test_string)
      attachment = Attachment.last
      expect(attachment.content_type).to eq "image/gif"
      expect(attachment.name).to eq "1d1fde3d669ed5c4fc68a49d643f140d.gif"
      expect(new_string).to eq "<p><img src=\"/courses/#{@course.id}/files/#{attachment.id}/preview\"></p>"
    end
  end

  describe "#rewrite_item_version!" do
    it "takes a fresh snapshot of the model" do
      p = @course.wiki_pages.create(title: "some page", body: "asdf")
      version = p.current_version
      expect(version.yaml).to include("asdf")
      WikiPage.where(id: p.id).update_all(body: "fdsa")
      @converter.rewrite_item_version!(p.reload)
      expect(version.reload.yaml).to_not include("asdf")
      expect(version.reload.yaml).to include("fdsa")
    end
  end
end
