require File.expand_path(File.dirname(__FILE__) + '/../../../cc_spec_helper')

describe "MediaConverter" do
  class MediaConverterTest
    include CC::Exporter::Epub::Converters::MediaConverter
  end

  describe "#convert_media_paths!" do
    let(:doc) do
      Nokogiri::HTML::DocumentFragment.parse(<<-HTML)
        <div>
          <a href="#{CGI.escape(MediaConverterTest::WEB_CONTENT_TOKEN)}/path/to/img.jpg">
            Image Link
          </a>
          <img src="#{CGI.escape(MediaConverterTest::WEB_CONTENT_TOKEN)}/path/to/img.jpg" />
        </div>
      HTML
    end
    subject(:test_instance) { MediaConverterTest.new }

    it "should update link hrefs containing WEB_CONTENT_TOKEN" do
      expect(doc.search('a').all? do |element|
        element['href'].match(CGI.escape(MediaConverterTest::WEB_CONTENT_TOKEN))
      end).to be_truthy, 'precondition'

      test_instance.convert_media_paths!(doc)

      expect(doc.search('a').all? do |element|
        element['href'].match(CC::Exporter::Epub::FILE_PATH)
      end).to be_truthy

      expect(doc.search('a').all? do |element|
        element['href'].match(CGI.escape(MediaConverterTest::WEB_CONTENT_TOKEN))
      end).to be_falsey
    end

    it "should update img srcs containing WEB_CONTENT_TOKEN" do
      expect(doc.search('img').all? do |element|
        element['src'].match(CGI.escape(MediaConverterTest::WEB_CONTENT_TOKEN))
      end).to be_truthy, 'precondition'

      test_instance.convert_media_paths!(doc)

      expect(doc.search('img').all? do |element|
        element['src'].match(CC::Exporter::Epub::FILE_PATH)
      end).to be_truthy

      expect(doc.search('img').all? do |element|
        element['src'].match(CGI.escape(MediaConverterTest::WEB_CONTENT_TOKEN))
      end).to be_falsey
    end
  end

  describe "#convert_audio_tags!" do
    context "for links with class instructure_audio_link" do
      let(:doc) do
        Nokogiri::HTML::DocumentFragment.parse(<<-HTML)
          <a href="#{CC::Exporter::Epub::FILE_PATH}/path/to/audio.mp3"
            class="instructure_audio_link">
            Audio Link
          </a>
        HTML
      end
      subject(:test_instance) { MediaConverterTest.new }

      it "should change a tags to audio tags" do
        expect(doc.search('a').any?).to be_truthy, 'precondition'
        expect(doc.search('audio').empty?).to be_truthy, 'precondition'

        test_instance.convert_audio_tags!(doc)

        expect(doc.search('a').empty?).to be_truthy
        expect(doc.search('audio').any?).to be_truthy
      end
    end

    context "for links with class audio_comment" do
      let(:doc) do
        Nokogiri::HTML::DocumentFragment.parse(<<-HTML)
          <a href="#{CC::Exporter::Epub::FILE_PATH}/path/to/audio.mp3"
            class="audio_comment">
            Audio Link
          </a>
        HTML
      end
      subject(:test_instance) { MediaConverterTest.new }

      it "should change a tags to audio tags" do
        expect(doc.search('a').any?).to be_truthy, 'precondition'
        expect(doc.search('audio').empty?).to be_truthy, 'precondition'

        test_instance.convert_audio_tags!(doc)

        expect(doc.search('a').empty?).to be_truthy
        expect(doc.search('audio').any?).to be_truthy
      end
    end
  end

  describe "#convert_video_tags!" do
    context "for links with class instructure_video_link" do
      let(:doc) do
        Nokogiri::HTML::DocumentFragment.parse(<<-HTML)
          <a href="#{CC::Exporter::Epub::FILE_PATH}/path/to/audio.mp3"
            class="instructure_video_link">
            Video Link
          </a>
        HTML
      end
      subject(:test_instance) { MediaConverterTest.new }

      it "should change a tags to audio tags" do
        expect(doc.search('a').any?).to be_truthy, 'precondition'
        expect(doc.search('video').empty?).to be_truthy, 'precondition'

        test_instance.convert_video_tags!(doc)

        expect(doc.search('a').empty?).to be_truthy
        expect(doc.search('video').any?).to be_truthy
      end
    end

    context "for links with class video_comment" do
      let(:doc) do
        Nokogiri::HTML::DocumentFragment.parse(<<-HTML)
          <a href="#{CC::Exporter::Epub::FILE_PATH}/path/to/audio.mp3"
            class="video_comment">
            Video Link
          </a>
        HTML
      end
      subject(:test_instance) { MediaConverterTest.new }

      it "should change a tags to audio tags" do
        expect(doc.search('a').any?).to be_truthy, 'precondition'
        expect(doc.search('video').empty?).to be_truthy, 'precondition'

        test_instance.convert_video_tags!(doc)

        expect(doc.search('a').empty?).to be_truthy
        expect(doc.search('video').any?).to be_truthy
      end
    end
  end
end
