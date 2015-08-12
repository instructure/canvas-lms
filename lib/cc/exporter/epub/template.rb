module CC::Exporter::Epub
  class Template
    def initialize(content, template_path, title)
      @content = content || []
      @template_path = template_path
      @title = title
    end
    attr_reader :content, :template_path, :title

    def build
      template = File.expand_path(template_path, __FILE__)
      erb = ERB.new(File.read(template))
      erb.result(binding)
    end

    def parse
      Nokogiri::XML(build, &:noblanks).to_xml({
        save_with: Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
      }).strip
    end
  end
end
