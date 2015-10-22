module CC::Exporter::Epub
  class Template
    include TextHelper

    def initialize(content, base_template)
      @content = content[:resources] || {}
      @reference = content[:reference]
      @base_template = base_template
      @title = Exporter::RESOURCE_TITLES[@reference] || @content[:title]
    end
    attr_reader :content, :base_template, :title, :reference

    def build(item=nil)
      return if item.try(:empty?)
      template_path = template(item) || base_template
      template = File.expand_path(template_path, __FILE__)
      erb = ERB.new(File.read(template))
      erb.result(binding)
    end

    def parse
      Nokogiri::HTML(build, &:noblanks).to_xhtml.strip
    end

    def template(item)
      return unless item
      Exporter.resource_template(item[:resource_type])
    end

    def friendly_date(date)
      datetime_string(Date.parse(date))
    end
  end
end
