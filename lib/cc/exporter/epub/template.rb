module CC::Exporter::Epub
  class Template
    include TextHelper

    def initialize(content, base_template)
      @content = content[:resources] || []
      @base_template = base_template
      @title = Exporter::RESOURCE_TITLES[content[:type]]
      @content_type_sorting = base_template.match(/content_sorting/)
    end
    attr_reader :content, :base_template, :title, :content_type_sorting

    def build(item=nil)
      return if item.try(:empty?)
      template_path = template_for(item) || base_template
      template = File.expand_path(template_path, __FILE__)
      erb = ERB.new(File.read(template))
      erb.result(binding)
    end

    def parse
      Nokogiri::HTML(build, &:noblanks).to_xhtml.strip
    end

    def module_item(item)
      resource_type = item[:linked_resource_type]
      resource_id = item[:linked_resource_id]
      module_resource(resource_type, resource_id)
    end

    def template_for(item)
      return unless item
      Exporter::RESOURCE_TEMPLATES[item[:resource_type]]
    end

    def friendly_date(date)
      datetime_string(Date.parse(date))
    end

    def module_resource(type, identifier)
      # return an empty object if no matching reource is found to differentiate
      # from the nil value that should only occur when building base templates
      find_module_item(course_content[module_resource_key[type]], identifier) || {}
    end

    def course_content
      content[:course_content]
    end

    def module_resource_key
      content[:linked_resource_key]
    end

    def find_module_item(resources, identifier)
      return unless resources.present?
      resources.find{|resource| resource[:identifier] == identifier}
    end
  end
end
