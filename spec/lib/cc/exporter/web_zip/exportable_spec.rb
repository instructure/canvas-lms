# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../../cc_spec_helper')

describe "Exportable" do
  class ExportableTest
    include CC::Exporter::WebZip::Exportable

    def attachment
      @_attachment ||= Attachment.create({
        context: Course.create,
        filename: 'exportable-test-file',
        uploaded_data: File.open(cartridge_path)
      })
    end

    def cartridge_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/migration/unicode-filename-test-export.imscc")
    end
  end

  context "#convert_to_epub" do

    before do
      @epub_export = ExportableTest.new.convert_to_offline_web_zip
    end

    let(:zip_path) do
      @epub_export
    end

    let(:zip) do
      File.open(zip_path)
    end

    it "should create a zip file" do
      expect(zip).not_to be_nil
    end

    it "creates a zip file whose name includes the cartridge's name" do
      expect(zip_path).to include('unicode-filename-test')
    end

    after do
      File.delete(zip_path) if File.exist?(zip_path)
    end
  end

end
