# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/cc_spec_helper')

require 'nokogiri'

describe CC::CCHelper do
  describe CC::CCHelper::HtmlContentExporter do
    before do
      @kaltura = mock('CanvasKaltura::ClientV3')
      CanvasKaltura::ClientV3.stubs(:new).returns(@kaltura)
      @kaltura.stubs(:startSession)
      @kaltura.stubs(:flavorAssetGetByEntryId).with('abcde').returns([
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
      @kaltura.stubs(:flavorAssetGetOriginalAsset).returns(@kaltura.flavorAssetGetByEntryId('abcde').first)
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
      other_course = course
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
      HostUrl.stubs(:protocol).returns('http')
      HostUrl.stubs(:context_host).returns('www.example.com:8080')
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
      HostUrl.stubs(:protocol).returns('http')
      HostUrl.stubs(:context_host).returns('www.example.com:8080')
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => false)
      page = @course.wiki.wiki_pages.create(:title => '9000, the level is over')
      html = <<-HTML
        <a href="/courses/#{@course.id}/wiki/#{page.url}">This course's wiki page</a>
      HTML
      doc = Nokogiri::HTML.parse(@exporter.html_content(html))
      urls = doc.css('a').map{ |attr| attr[:href] }
      expect(urls[0]).to eq "%24WIKI_REFERENCE%24/wiki/#{page.url}"
    end

    it "should copy pages correctly when the title consists only of a number" do
      HostUrl.stubs(:protocol).returns('http')
      HostUrl.stubs(:context_host).returns('www.example.com:8080')
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy => false)
      page = @course.wiki.wiki_pages.create(:title => '9000')
      html = <<-HTML
        <a href="/courses/#{@course.id}/wiki/#{page.url}">This course's wiki page</a>
      HTML
      doc = Nokogiri::HTML.parse(@exporter.html_content(html))
      urls = doc.css('a').map{ |attr| attr[:href] }
      expect(urls[0]).to eq "%24WIKI_REFERENCE%24/wiki/#{page.url}"
    end
  end
end
