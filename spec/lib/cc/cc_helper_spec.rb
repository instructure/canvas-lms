require File.dirname(__FILE__) + '/cc_spec_helper'

describe CC::CCHelper do
  describe CC::CCHelper::HtmlContentExporter do
    before do
      @kaltura = mock(Kaltura::ClientV3)
      Kaltura::ClientV3.stub(:new).and_return(@kaltura)
      @kaltura.stub(:startSession)
      @kaltura.stub(:flavorAssetGetByEntryId).with('abcde').and_return([
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
      @kaltura.stub(:flavorAssetGetOriginalAsset).and_return(@kaltura.flavorAssetGetByEntryId('abcde').first)
      course_with_teacher
      @obj = @course.media_objects.create!(:media_id => 'abcde')
    end

    it "should translate media links using the original flavor" do
      @exporter = CC::CCHelper::HtmlContentExporter.new
      translated = @exporter.html_content(<<-HTML, @course, @user)
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      @exporter.media_object_infos[@obj.id].should_not be_nil
      @exporter.media_object_infos[@obj.id][:asset][:id].should == 'one'
    end

    it "should translate media links using an alternate flavor" do
      @exporter = CC::CCHelper::HtmlContentExporter.new(:media_object_flavor => 'flash video')
      translated = @exporter.html_content(<<-HTML, @course, @user)
      <p><a id='media_comment_abcde' class='instructure_inline_media_comment'>this is a media comment</a></p>
      HTML
      @exporter.media_object_infos[@obj.id].should_not be_nil
      @exporter.media_object_infos[@obj.id][:asset][:id].should == 'two'
    end
  end
end
