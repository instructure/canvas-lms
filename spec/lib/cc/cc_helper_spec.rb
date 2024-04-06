# frozen_string_literal: true

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

require_relative "cc_spec_helper"

require "nokogiri"

describe CC::CCHelper do
  context "map_linked_objects" do
    it "finds linked canvas items in exported html content" do
      content = <<~HTML
        <a href="$CANVAS_OBJECT_REFERENCE$/assignments/123456789">Link</a>
        <img src="$IMS-CC-FILEBASE$/media/folder%201/file.jpg" />
      HTML
      linked_objects = CC::CCHelper.map_linked_objects(content)
      expect(linked_objects[0]).to eq({ identifier: "123456789", type: "assignments" })
      expect(linked_objects[1]).to eq({ local_path: "/media/folder 1/file.jpg", type: "Attachment" })
    end

    it "finds linked canvas items in exported html content with old escapes" do
      content = <<~HTML
        <a href="%24CANVAS_OBJECT_REFERENCE%24/assignments/123456789">Link</a>
        '<img src="%24IMS-CC-FILEBASE%24/media/folder%201/file.jpg" />
      HTML
      linked_objects = CC::CCHelper.map_linked_objects(content)
      expect(linked_objects[0]).to eq({ identifier: "123456789", type: "assignments" })
      expect(linked_objects[1]).to eq({ local_path: "/media/folder 1/file.jpg", type: "Attachment" })
    end
  end

  describe CC::CCHelper::HtmlContentExporter do
    before :once do
      course_with_teacher
      @obj = @course.media_objects.create!(media_id: "abcde", title: "some_media.mp4")
    end

    before do
      @kaltura = double("CanvasKaltura::ClientV3")
      allow(CC::CCHelper).to receive(:kaltura_admin_session).and_return(@kaltura)
      allow(@kaltura).to receive(:flavorAssetGetByEntryId).with("abcde").and_return([
                                                                                      {
                                                                                        isOriginal: 1,
                                                                                        containerFormat: "mp4",
                                                                                        fileExt: "mp4",
                                                                                        id: "one",
                                                                                        size: 15,
                                                                                      },
                                                                                      {
                                                                                        containerFormat: "flash video",
                                                                                        fileExt: "flv",
                                                                                        id: "smaller",
                                                                                        size: 3,
                                                                                      },
                                                                                      {
                                                                                        containerFormat: "flash video",
                                                                                        fileExt: "flv",
                                                                                        id: "two",
                                                                                        size: 5,
                                                                                      },
                                                                                    ])
      allow(@kaltura).to receive(:flavorAssetGetOriginalAsset).and_return(@kaltura.flavorAssetGetByEntryId("abcde").first)
    end

    shared_examples "media_attachments_iframes examples" do
      it "are translated on export" do
        att = @course.attachments.first
        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)

        html = %(
          <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{att.id}?type=video&embedded=true" allow="fullscreen" data-media-id="#{att.media_entry_id}"></iframe>
          <iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_objects_iframe/#{att.media_entry_id}?type=video&embedded=true" allow="fullscreen" data-media-id="#{att.media_entry_id}"></iframe>
          <a id="media_comment_abcde" class="instructure_inline_media_comment video_comment" data-media_comment_type="video" data-alt=""></a>
        )
        sources = Nokogiri::HTML5(@exporter.html_content(html)).css("source").pluck("src")
        expect(sources.length).to eq 2
        expect(sources).to eq([
                                "$IMS-CC-FILEBASE$/Uploaded%20Media/some_media.mp4?canvas_=1&canvas_qs_embedded=true&canvas_qs_type=video&media_attachment=true",
                                "$IMS-CC-FILEBASE$/Uploaded Media/some_media.mp4"
                              ])
      end

      it "are not translated on export when pointing at user media" do
        att = attachment_model(display_name: "lolcats.mp4", context: @user, uploaded_data: stub_file_data("lolcats_.mp4", "...", "video/mp4"))
        att.save!
        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
        orig = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{att.id}?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="zzzz"></iframe>)
        translated = @exporter.html_content(orig)
        expect(translated).to include %(<source src="/media_attachments_iframe/#{att.id}?type=video" data-media-id="zzzz" data-media-type="video">)
        expect(@exporter.media_object_infos.count).to eq 0
      end

      it "are not translated on export when pointing at media in another course" do
        other_course = course_with_teacher
        att = attachment_model(display_name: "lolcats.mp4", context: other_course, uploaded_data: stub_file_data("lolcats_.mp4", "...", "video/mp4"))
        att.save!
        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
        orig = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="/media_attachments_iframe/#{att.id}?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="zzzz"></iframe>)
        translated = @exporter.html_content(orig)
        expect(translated).to include %(<source src="/media_attachments_iframe/#{att.id}?type=video" data-media-id="zzzz" data-media-type="video">)
        expect(@exporter.media_object_infos.count).to eq 0
      end
    end

    context "media_attachments_iframes" do
      context "with precise_link_replacements FF OFF" do
        before { Account.site_admin.disable_feature! :precise_link_replacements }

        include_examples "media_attachments_iframes examples"
      end

      context "with precise_link_replacements FF ON" do
        before { Account.site_admin.enable_feature! :precise_link_replacements }

        include_examples "media_attachments_iframes examples"
      end
    end

    it "translates media links using the original flavor" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      @exporter.html_content(<<~HTML)
        <p><a id="media_comment_abcde" class="instructure_inline_media_comment">this is a media comment</a></p>
      HTML
      expect(@exporter.media_object_infos[@obj.id]).not_to be_nil
      expect(@exporter.media_object_infos[@obj.id][:asset][:id]).to eq "one"
    end

    # TODO: tests for media_comment_ links can be removed after the datafix up for LF-1335 is complete
    it "does not touch links to deleted media objects" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      @obj.destroy
      orig = <<~HTML
        <p><a id="media_comment_abcde" class="instructure_inline_media_comment">this is a media comment</a></p>
      HTML
      translated = @exporter.html_content(orig)
      expect(translated).to eq orig
      expect(@exporter.media_object_infos[@obj.id]).to be_nil
    end

    it "translates media links using an alternate flavor" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, media_object_flavor: "flash video")
      @exporter.html_content(<<~HTML)
        <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      expect(@exporter.media_object_infos[@obj.id]).not_to be_nil
      expect(@exporter.media_object_infos[@obj.id][:asset][:id]).to eq "two"
    end

    it "ignores media links with no media comment id" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, media_object_flavor: "flash video")
      html = %(<a class="youtubed instructure_inline_media_comment" href="http://www.youtube.com/watch?v=dCIP3x5mFmw">McDerp Enterprises</a>)
      translated = @exporter.html_content(html)
      expect(translated).to eq html
    end

    it "translates RCE media iframes to relevant HTML tags" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="http://example.com/media_objects_iframe/abcde?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="abcde"></iframe>)
      translated = @exporter.html_content(html)
      expect(translated).to include %(<source src="$IMS-CC-FILEBASE$/Uploaded Media/some_media.mp4" data-media-id="abcde" data-media-type="video">)
      expect(@exporter.media_object_infos[@obj.id]).not_to be_nil
      expect(@exporter.media_object_infos[@obj.id][:asset][:id]).to eq "one"
    end

    it "links media to exported file if it exists" do
      folder = folder_model(name: "something", context: @course)
      att = attachment_model(display_name: "lolcats.mp4", context: @course, folder:, uploaded_data: stub_file_data("lolcats_.mp4", "...", "video/mp4"))
      @obj.attachment = att
      @obj.save!
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="http://example.com/media_objects_iframe/abcde?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="abcde"></iframe>)
      translated = @exporter.html_content(html)
      expect(translated).to include %(src="$IMS-CC-FILEBASE$/something/lolcats.mp4")
    end

    it "links media to proper file via related_attachment links" do
      disposable_course = Course.create!
      folder = folder_model(name: "something", context: disposable_course)
      att = attachment_model(display_name: "lolcats.mp4", context: disposable_course, folder:, uploaded_data: stub_file_data("lolcats_.mp4", "...", "video/mp4"))
      @obj.attachment = att
      @obj.save!
      attachment_model(root_attachment: att, display_name: "lolcats.mp4", context: @course, folder:, uploaded_data: stub_file_data("lolcats_.mp4", "...", "video/mp4"))
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="http://example.com/media_objects_iframe/abcde?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="abcde"></iframe>)
      translated = @exporter.html_content(html)
      expect(translated).to include %(src="$IMS-CC-FILEBASE$/unfiled/lolcats.mp4")
    end

    it "does not link media to file in another course" do
      temp = @course
      other_course = course_factory
      folder = folder_model(name: "something", context: other_course)
      att = attachment_model(display_name: "lolcats.mp4", context: other_course, folder:, uploaded_data: stub_file_data("lolcats_.mp4", "...", "video/mp4"))
      @obj.attachment = att
      @obj.save!
      @course = temp
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="http://example.com/media_objects_iframe/abcde?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="abcde"></iframe>)
      translated = @exporter.html_content(html)
      expect(translated).to include %(src="$IMS-CC-FILEBASE$/media_objects/abcde.mp4")
    end

    it "leaves sources unchanged for media iframes with unknown media id" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %(<iframe style="width: 400px; height: 225px; display: inline-block;" title="this is a media comment" data-media-type="video" src="http://example.com/media_objects_iframe/deadbeef?type=video" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="deadbeef"></iframe>)
      translated = @exporter.html_content(html)
      expect(translated).to include %(src="http://example.com/media_objects_iframe/deadbeef?type=video")
      expect(@exporter.media_object_infos).to be_empty
    end

    it "finds media objects outside the context (because course copy)" do
      other_course = course_factory
      @exporter = CC::CCHelper::HtmlContentExporter.new(other_course, @user)
      @exporter.html_content(<<~HTML)
        <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      expect(@exporter.used_media_objects.map(&:media_id)).to eql(["abcde"])
    end

    it "exports html with a utf-8 charset" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %(<div>My Title\u0278</div>)
      exported = @exporter.html_page(html, "my title page")
      doc = Nokogiri::HTML5(exported)
      expect(doc.encoding.upcase).to eq "UTF-8"
      expect(doc.at_css("html body div").to_s).to eq "<div>My Titleɸ</div>"
    end

    it "html-escapes the title" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      exported = @exporter.html_page("", "<style> upon style")
      doc = Nokogiri::HTML5(exported)
      expect(doc.title).to eq "<style> upon style"
      expect(doc.at_css("style")).to be_nil
    end

    it "html-escapes the meta fields" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      exported = @exporter.html_page("", "title", { name: '"/><script>alert("wat")</script><meta name="lol' })
      doc = Nokogiri::HTML5(exported)
      expect(doc.at_css('meta[name="name"]').attr("content")).to include "<script>"
      expect(doc.at_css("script")).to be_nil
    end

    it "only translates course when trying to translate /cousers/x/users/y type links" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: true)
      orig = <<~HTML
        <a href='/courses/#{@course.id}/users/#{@teacher.id}'>ME</a>
      HTML
      translated = @exporter.html_content(orig)
      expect(translated).to match(%r{users/#{@teacher.id}})
    end

    it "interprets links to the files page as normal course pages" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: true)
      html = %(<a href="/courses/#{@course.id}/files">File page index</a>)
      translated = @exporter.html_content(html)
      expect(translated).to match %r{\$CANVAS_COURSE_REFERENCE\$/files}
    end

    it "interprets links to the home page as normal course pages" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: true)
      html = %(<a href="/courses/#{@course.id}">Home page index</a>)
      translated = @exporter.html_content(html)
      expect(translated).to match %r{\$CANVAS_COURSE_REFERENCE\$/}
    end

    it "prepends the domain to links outside the course" do
      allow(HostUrl).to receive_messages(protocol: "http", context_host: "www.example.com:8080")
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: false)
      @othercourse = Course.create!
      html = <<~HTML
        <a href="/courses/#{@course.id}/wiki/front-page">This course's front page</a>
        <a href="/courses/#{@othercourse.id}/wiki/front-page">Other course's front page</a>
      HTML
      doc = Nokogiri::HTML5(@exporter.html_content(html))
      urls = doc.css("a").pluck(:href)
      expect(urls[0]).to eq "$WIKI_REFERENCE$/wiki/front-page"
      expect(urls[1]).to eq "http://www.example.com:8080/courses/#{@othercourse.id}/wiki/front-page"
    end

    context "assessment_question file links" do
      before do
        attachment_model(uploaded_data: stub_png_data)
        assessment_question_bank_model
        question_data = {
          "name" => "test question",
          "points_possible" => 10,
          "answers" => [{ "id" => 1 }, { "id" => 2 }],
        }
        @question = @bank.assessment_questions.create!(question_data:)
        @question.question_data = question_data.merge("question_text" => %(<p><img src="/courses/#{@course.id}/files/#{@attachment.id}/download"></p>))
        @question.save!
        quiz_model(course: @course)
        @quiz.add_assessment_questions([@question])
      end

      it "translates assessment_question links during export" do
        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: false)
        question_text = @quiz.quiz_questions[0].question_data["question_text"]
        matches = question_text.match %r{/assessment_questions/#{@question.id}/files/(?<file_id>\d+)}
        expect(matches[:file_id]).not_to be_nil

        translated = @exporter.html_content(question_text)
        expect(translated).to match %r{\$IMS-CC-FILEBASE\$/assessment_questions/test%20my%20file\?%20hai!&amp;.png}
      end

      it "removes verifier query parameters on links" do
        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: false)
        qb_attachment = @question.attachments.take
        question_text = %(<p><img src="/assessment_questions/#{@question.id}/files/#{qb_attachment.id}/download?verifier=#{qb_attachment.uuid}&amp;verifier=random_other_att_verifier" alt="5e9toe-2.jpeg" /></p>)
        @question.question_data = @question.question_data = question_data.merge("question_text" => question_text)
        @question.save!
        translated = @exporter.html_content(question_text)
        expect(translated).to match %r{\$IMS-CC-FILEBASE\$/assessment_questions/test%20my%20file\?%20hai!&amp;.png}
      end
    end

    it "copies the correct page when the url is an old slug" do
      Account.site_admin.enable_feature! :permanent_page_links
      allow(HostUrl).to receive_messages(protocol: "http", context_host: "www.example.com:8080")
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: false)
      page = @course.wiki_pages.create(title: "9000, the level is over")
      page.wiki_page_lookups.create!(slug: "old-url")
      html = %(<a href="/courses/#{@course.id}/pages/old-url">This course's wiki page</a>)
      doc = Nokogiri::HTML5(@exporter.html_content(html))
      urls = doc.css("a").pluck(:href)
      expect(urls[0]).to eq "$WIKI_REFERENCE$/pages/#{CC::CCHelper.create_key(page)}"
    end

    it "creates a page url with a migration id" do
      allow(HostUrl).to receive_messages(protocol: "http", context_host: "www.example.com:8080")
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      page = @course.wiki_pages.create(title: "beautiful title")
      html = %(<a href="/courses/#{@course.id}/pages/#{page.url}">This course's wiki page</a>)
      doc = Nokogiri::HTML5(@exporter.html_content(html))
      urls = doc.css("a").pluck(:href)
      expect(urls[0]).to eq "$WIKI_REFERENCE$/pages/#{CC::CCHelper.create_key(page)}"
    end

    it "uses the key_generator to translate links" do
      allow(HostUrl).to receive_messages(protocol: "http", context_host: "www.example.com:8080")
      @assignment = @course.assignments.create!(name: "Thing")
      html = <<~HTML
        <a href="/courses/#{@course.id}/assignments/#{@assignment.id}">Thing</a>
      HTML
      keygen = double
      expect(keygen).to receive(:create_key).and_return("silly-migration-id")
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: true, key_generator: keygen)
      doc = Nokogiri::HTML5(@exporter.html_content(html))
      expect(doc.at_css("a").attr("href")).to eq "$CANVAS_OBJECT_REFERENCE$/assignments/silly-migration-id"
    end

    it "preserves query parameters on links" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, for_course_copy: true)
      page = @course.wiki_pages.create!(title: "something")
      other_page = @course.wiki_pages.create!(title: "LinkByTitle")
      assignment = @course.assignments.create!(name: "Thing")
      mod = @course.context_modules.create!(name: "Stuff")
      tag = mod.content_tags.create! content: assignment, context: @course
      html = <<~HTML
        <a href="/courses/#{@course.id}/pages/something?embedded=true">Something</a>
        <a href="/courses/#{@course.id}/pages/LinkByTitle?embedded=true">Something</a>
        <a href="/courses/#{@course.id}/assignments/#{assignment.id}?bamboozled=true">Thing</a>
        <a href="/courses/#{@course.id}/modules/items/#{tag.id}?seriously=0">i-Tem</a>
      HTML
      translated = @exporter.html_content(html)
      expect(translated).to include "$WIKI_REFERENCE$/pages/#{CC::CCHelper.create_key(page)}?embedded=true"
      expect(translated).to include "$WIKI_REFERENCE$/pages/#{CC::CCHelper.create_key(other_page)}?embedded=true"
      expect(translated).to include "$CANVAS_OBJECT_REFERENCE$/assignments/#{CC::CCHelper.create_key(assignment)}?bamboozled=true"
      expect(translated).to include "$CANVAS_COURSE_REFERENCE$/modules/items/#{CC::CCHelper.create_key(tag)}?seriously=0"
    end

    it "deals with a missing media object on kaltura" do
      allow(@kaltura).to receive(:flavorAssetGetByEntryId).with("xyzzy").and_return(nil)
      @course.media_objects.create!(media_id: "xyzzy")
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, media_object_flavor: "flash video")
      expect do
        @exporter.html_content(<<~HTML)
          <p><a id='media_comment_xyzzy' class='instructure_inline_media_comment'>this is a media comment</a></p>
        HTML
      end.not_to raise_error
    end

    context "disable_content_rewriting is truthy" do
      let(:html) { "<p><a href=\"/courses/#{@course.id}/files\">Files tab</a></p>" }

      it "skips html rewrite" do
        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, disable_content_rewriting: true)
        expect(@exporter.html_content(html)).to eq(html)

        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, disable_content_rewriting: "false")
        expect(@exporter.html_content(html)).to eq(html)

        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, disable_content_rewriting: "true")
        expect(@exporter.html_content(html)).to eq(html)

        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, disable_content_rewriting: 5)
        expect(@exporter.html_content(html)).to eq(html)
      end
    end

    context "disable_content_rewriting is false or unset" do
      let(:html) { "<p><a href=\"/courses/#{@course.id}/files\">Files tab</a></p>" }

      it "does html rewrite" do
        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, disable_content_rewriting: false)
        expect(@exporter.html_content(html)).to not_eq(html)

        @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
        expect(@exporter.html_content(html)).to not_eq(html)
      end
    end
  end
end
