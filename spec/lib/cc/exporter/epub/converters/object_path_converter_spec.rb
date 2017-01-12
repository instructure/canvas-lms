require File.expand_path(File.dirname(__FILE__) + '/../../../cc_spec_helper')

describe "OjbectPathConverter" do
  class ObjectPathConverterTest
    include CC::Exporter::Epub::Converters::ObjectPathConverter
  end

  describe "#convert_object_paths!" do
    let(:assignment_id) { "i5f4cd2e04f1089c1c5060e9761400516" }
    let(:wiki_id) { "page-1" }
    let(:doc) do
      Nokogiri::HTML::DocumentFragment.parse(<<-HTML)
        <div>
          <a href="#{ObjectPathConverterTest::OBJECT_TOKEN}/assignments/#{assignment_id}">
            Assignment Link
          </a>
          <a href="#{ObjectPathConverterTest::WIKI_TOKEN}/pages/#{wiki_id}">
            Wiki Link
          </a>
        </div>
      HTML
    end
    subject(:test_instance) { ObjectPathConverterTest.new }

    it "should update assignment link href" do
      expect(doc.search("a[href*='#{ObjectPathConverterTest::OBJECT_TOKEN}']").any?).to be_truthy,
        'precondition'

      test_instance.convert_object_paths!(doc)
      expect(doc.search("a[href*='#{ObjectPathConverterTest::OBJECT_TOKEN}']").any?).to be_falsy
      expect(doc.search("a[href='assignments.xhtml##{assignment_id}']").any?).to be_truthy
    end

    it "should update wiki link href" do
      expect(doc.search("a[href*='#{ObjectPathConverterTest::WIKI_TOKEN}']").any?).to be_truthy,
        'precondition'

      test_instance.convert_object_paths!(doc)
      expect(doc.search("a[href*='#{ObjectPathConverterTest::WIKI_TOKEN}']").any?).to be_falsy
      expect(doc.search("a[href='pages.xhtml##{wiki_id}']").any?).to be_truthy
    end
  end
end
