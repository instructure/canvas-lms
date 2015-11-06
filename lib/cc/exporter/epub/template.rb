module CC::Exporter::Epub
  class Template
    include CC::Exporter::Epub::Converters::MediaConverter
    include CC::Exporter::Epub::Converters::ObjectPathConverter
    include TextHelper

    def initialize(content, base_template, exporter)
      @content = content[:resources] || {}
      @reference = content[:reference]
      @base_template = base_template
      @exporter = exporter
      @title = Exporter::RESOURCE_TITLES[@reference] || @content[:title]
      css = File.expand_path("../templates/css_template.css", __FILE__)
      @style = File.read(css)
    end
    attr_reader :content, :base_template, :exporter, :title, :reference, :style
    delegate :get_item, :sort_by_content, :unsupported_files, to: :exporter

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
      Exporter.resource_template(resource_type(item))
    end

    def convert_placeholder_paths_from_string!(html_string)
      html_node = Nokogiri::HTML::DocumentFragment.parse(html_string)
      html_node.tap do |node|
        convert_media_from_node!(node)
        convert_object_paths!(node)
        remove_empty_ids!(node)
      end
      html_node.to_s
    end

    def remove_empty_ids!(node)
      node.search("a[id='']").each do |tag|
        tag.remove_attribute('id')
      end
      node
    end

    def friendly_date(date)
      return unless date
      datetime_string(Date.parse(date))
    end

    def resource_type(item)
      Exporter::LINKED_RESOURCE_KEY[item[:linked_resource_type]] || @reference
    end
  end
end
