require File.dirname(__FILE__) + '/cc_spec_helper'

describe CC::CCHelper do
  describe CC::CCHelper::HtmlContentExporter do
    before do
      @kaltura = mock('Kaltura::ClientV3')
      Kaltura::ClientV3.stubs(:new).returns(@kaltura)
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
      @exporter.media_object_infos[@obj.id].should_not be_nil
      @exporter.media_object_infos[@obj.id][:asset][:id].should == 'one'
    end

    it "should not touch media links on course copy" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy=>true)
      orig = <<-HTML
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      translated = @exporter.html_content(orig)
      translated.should == orig
    end

    it "should translate media links using an alternate flavor" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :media_object_flavor => 'flash video')
      translated = @exporter.html_content(<<-HTML)
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      @exporter.media_object_infos[@obj.id].should_not be_nil
      @exporter.media_object_infos[@obj.id][:asset][:id].should == 'two'
    end

    it "should ignore media links with no media comment id" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :media_object_flavor => 'flash video')
      html = %{<a class="youtubed instructure_inline_media_comment" href="http://www.youtube.com/watch?v=dCIP3x5mFmw">McDerp Enterprises</a>}
      translated = @exporter.html_content(html)
      translated.should == html
    end

    it "should export html with a utf-8 charset" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user)
      html = %{<div>My Title\302\240</div>}
      exported = @exporter.html_page(html, "my title page")
      doc = Nokogiri::HTML(exported)
      doc.encoding.should == 'utf-8'
      doc.at_css('html body div').to_s.should == "<div>My Title\302\240</div>"
    end

    it "should only translate course when trying to translate /cousers/x/users/y type links" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(@course, @user, :for_course_copy=>true)
      orig = <<-HTML
      <a href='/courses/#{@course.id}/users/#{@teacher.id}'>ME</a>
      HTML
      translated = @exporter.html_content(orig)
      translated.should =~ /users\/#{@teacher.id}/
    end
  end
end
