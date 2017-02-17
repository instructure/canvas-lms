# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../../cc_spec_helper')

describe "Exporter" do
  include CC::Exporter::WebZip

  before(:once) do
    def cartridge_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/exporter/cc-with-modules-export.imscc")
    end

    @attachment = Attachment.create({
      context: course_factory,
      filename: 'exportable-test-file',
      uploaded_data: File.open(cartridge_path)
    })

  end

  context "create web zip package default settings" do
    let(:exporter) do
      CC::Exporter::WebZip::Exporter.new(@attachment.open, false, :web_zip)
    end

    it "should sort content by module" do
      expect(exporter.base_template).to eq "../templates/module_sorting_template.html.erb"
    end

    it "should not URL escape file names" do
      expect(exporter.unsupported_files[1][:file_name]).to eq '!@#$%^&*().txt'
    end
  end
end
