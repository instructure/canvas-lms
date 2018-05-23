# encoding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/cc_spec_helper')

require 'nokogiri'

describe CC::CCHelper do
  context 'map_linked_objects' do
    it 'should find linked canvas items in exported html content' do
      content = '<a href="%24CANVAS_OBJECT_REFERENCE%24/assignments/123456789">Link</a>' \
                '<img src="%24IMS-CC-FILEBASE%24/media/folder%201/file.jpg" />'
      linked_objects = CC::CCHelper.map_linked_objects(content)
      expect(linked_objects[0]).to eq({identifier: '123456789', type: 'assignments'})
      expect(linked_objects[1]).to eq({local_path: '/media/folder 1/file.jpg', type: 'Attachment'})
    end
  end

  describe CC::CCHelper::HtmlContentExporter do
    before do
      @kaltura = double('CanvasKaltura::ClientV3')
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(@kaltura)
      allow(@kaltura).to receive(:startSession)
      allow(@kaltura).to receive(:flavorAssetGetByEntryId).with('abcde').and_return([
      {
        :isOriginal => 1,
        :containerFormat => 'mp4',
        :fileExt => 'mp4',
        :id => 'one',
        :size => 15,
      },
      {
        :containerFormat => 'flash video',
        :fileExt => 'flv',
        :id => 'smaller',
        :size => 3,
      },
      {
        :containerFormat => 'flash video',
        :fileExt => 'flv',
        :id => 'two',
        :size => 5,
      },
      ])
      allow(@kaltura).to receive(:flavorAssetGetOriginalAsset).and_return(@kaltura.flavorAssetGetByEntryId('abcde').first)
      course_with_teacher
      @obj = @course.media_objects.create!(:media_id => 'abcde')
    end

    it "should translate media links using the original flavor" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      translated = @exporter.html_content(<<-HTML)
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      expect(@exporter.media_object_infos[@obj.id]).not_to be_nil
      expect(@exporter.media_object_infos[@obj.id][:asset][:id]).to eq 'one'
    end

    it "should not touch media links on course copy" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy=>true)
      orig = <<-HTML
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      translated = @exporter.html_content(orig)
      expect(translated).to eq orig
    end

    it "should translate media links using an alternate flavor" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :media_object_flavor => 'flash video')
      translated = @exporter.html_content(<<-HTML)
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      expect(@exporter.media_object_infos[@obj.id]).not_to be_nil
      expect(@exporter.media_object_infos[@obj.id][:asset][:id]).to eq 'two'
    end

    it "should ignore media links with no media comment id" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :media_object_flavor => 'flash video')
      html = %{<a class="youtubed instructure_inline_media_comment" href="http://www.youtube.com/watch?v=dCIP3x5mFmw">McDerp Enterprises</a>}
      translated = @exporter.html_content(html)
      expect(translated).to eq html
    end

    it "should find media objects outside the context (because course copy)" do
      other_course = course_factory
      @exporter = CC::CCHelper::HtmlContentExporter.new(other_course, @user)
      @exporter.html_content(<<-HTML)
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      expect(@exporter.used_media_objects.map(&:media_id)).to eql(['abcde'])
    end

    it "should export html with a utf-8 charset" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %{<div>My Title\302\240</div>}
      exported = @exporter.html_page(html, "my title page")
      doc = Nokogiri::HTML(exported)
      expect(doc.encoding.upcase).to eq 'UTF-8'
      expect(doc.at_css('html body div').to_s).to eq "<div>My Title\302\240</div>"
    end

    it "html-escapes the title" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      exported = @exporter.html_page('', '<style> upon style')
      doc = Nokogiri::HTML.parse(exported)
      expect(doc.title).to eq '<style> upon style'
      expect(doc.at_css('style')).to be_nil
    end

    it "html-escapes the meta fields" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      exported = @exporter.html_page('', 'title', { name: '"/><script>alert("wat")</script><meta name="lol' })
      doc = Nokogiri::HTML.parse(exported)
      expect(doc.at_css('meta[name="name"]').attr('content')).to include '<script>'
      expect(doc.at_css('script')).to be_nil
    end

    it "should only translate course when trying to translate /cousers/x/users/y type links" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy=>true)
      orig = <<-HTML
      <a href='/courses/#{@course.id}/users/#{@teacher.id}'>ME</a>
      HTML
      translated = @exporter.html_content(orig)
      expect(translated).to match /users\/#{@teacher.id}/
    end

    it "should interpret links to the files page as normal course pages" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => true)
      html = %{<a href="/courses/#{@course.id}/files">File page index</a>}
      translated = @exporter.html_content(html)
      expect(translated).to match %r{\$CANVAS_COURSE_REFERENCE\$/files}
    end

    it "should prepend the domain to links outside the course" do
      allow(HostUrl).to receive(:protocol).and_return('http')
      allow(HostUrl).to receive(:context_host).and_return('www.example.com:8080')
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => false)
      @othercourse = Course.create!
      html = <<-HTML
        <a href="/courses/#{@course.id}/wiki/front-page">This course's front page</a>
        <a href="/courses/#{@othercourse.id}/wiki/front-page">Other course's front page</a>
      HTML
      doc = Nokogiri::HTML.parse(@exporter.html_content(html))
      urls = doc.css('a').map{ |attr| attr[:href] }
      expect(urls[0]).to eq "%24WIKI_REFERENCE%24/wiki/front-page"
      expect(urls[1]).to eq "http://www.example.com:8080/courses/#{@othercourse.id}/wiki/front-page"
    end

    it "should copy pages correctly when the title starts with a number" do
      allow(HostUrl).to receive(:protocol).and_return('http')
      allow(HostUrl).to receive(:context_host).and_return('www.example.com:8080')
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => false)
      page = @course.wiki_pages.create(:title => '9000, the level is over')
      html = <<-HTML
        <a href="/courses/#{@course.id}/wiki/#{page.url}">This course's wiki page</a>
      HTML
      doc = Nokogiri::HTML.parse(@exporter.html_content(html))
      urls = doc.css('a').map{ |attr| attr[:href] }
      expect(urls[0]).to eq "%24WIKI_REFERENCE%24/wiki/#{page.url}"
    end

    it "should copy pages correctly when the title consists only of a number" do
      allow(HostUrl).to receive(:protocol).and_return('http')
      allow(HostUrl).to receive(:context_host).and_return('www.example.com:8080')
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => false)
      page = @course.wiki_pages.create(:title => '9000')
      html = <<-HTML
        <a href="/courses/#{@course.id}/wiki/#{page.url}">This course's wiki page</a>
      HTML
      doc = Nokogiri::HTML.parse(@exporter.html_content(html))
      urls = doc.css('a').map{ |attr| attr[:href] }
      expect(urls[0]).to eq "%24WIKI_REFERENCE%24/wiki/#{page.url}"
    end

    it "uses the key_generator to translate links" do
      allow(HostUrl).to receive(:protocol).and_return('http')
      allow(HostUrl).to receive(:context_host).and_return('www.example.com:8080')
      @assignment = @course.assignments.create!(:name => "Thing")
      html = <<-HTML
        <a href="/courses/#{@course.id}/assignments/#{@assignment.id}">Thing</a>
      HTML
      keygen = double()
      expect(keygen).to receive(:create_key).and_return("silly-migration-id")
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => true, :key_generator => keygen)
      doc = Nokogiri::HTML.parse(@exporter.html_content(html))
      expect(doc.at_css("a").attr('href')).to eq "$CANVAS_OBJECT_REFERENCE$/assignments/silly-migration-id"
    end

    it "preserves query parameters on links" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => true)
      page = @course.wiki_pages.create!(:title => "something")
      other_page = @course.wiki_pages.create!(:title => "LinkByTitle")
      assignment = @course.assignments.create!(:name => "Thing")
      mod = @course.context_modules.create!(:name => "Stuff")
      tag = mod.content_tags.create! content: assignment, context: @course
      html = %Q{
        <a href="/courses/#{@course.id}/pages/something?embedded=true">Something</a>
        <a href="/courses/#{@course.id}/pages/LinkByTitle?embedded=true">Something</a>
        <a href="/courses/#{@course.id}/assignments/#{assignment.id}?bamboozled=true">Thing</a>
        <a href="/courses/#{@course.id}/modules/items/#{tag.id}?seriously=0">i-Tem</a>
      }
      translated = @exporter.html_content(html)
      expect(translated).to include "$WIKI_REFERENCE$/pages/something?embedded=true"
      expect(translated).to include "$WIKI_REFERENCE$/pages/#{other_page.url}?embedded=true"
      expect(translated).to include "$CANVAS_OBJECT_REFERENCE$/assignments/#{CC::CCHelper.create_key(assignment)}?bamboozled=true"
      expect(translated).to include "$CANVAS_COURSE_REFERENCE$/modules/items/#{CC::CCHelper.create_key(tag)}?seriously=0"
    end
  end
end
