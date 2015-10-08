module CC::Exporter::Epub
  class Exporter

    include CC::Exporter::Epub::ModuleSorter

    RESOURCE_TITLES = {
      toc: I18n.t("Table Of Contents"),
      syllabus: I18n.t("Syllabus"),
      modules: I18n.t("Modules"),
      assignments: I18n.t("Assignments"),
      announcements: I18n.t("Announcements"),
      topics: I18n.t("Discussion Topics"),
      quizzes: I18n.t("Quizzes"),
      pages: I18n.t("Wiki Pages"),
      files: I18n.t("Files")
    }.freeze

    LINKED_RESOURCE_KEY = {
      "Assignment" => :assignments,
      "Attachment" => :files,
      "DiscussionTopic" => :topics,
      "Quizzes::Quiz" => :quizzes,
      "WikiPage" => :pages
    }.freeze

    def initialize(cartridge, sort_by_content=false)
      @cartridge = cartridge
      @sort_by_content = sort_by_content || cartridge_json[:modules].empty?
    end
    attr_reader :cartridge, :sort_by_content
    delegate :unsupported_files, to: :cartridge_converter, allow_nil: true

    def cartridge_json
      @_cartridge_json ||= cartridge_converter.export
    end

    def templates
      @_templates ||= {
        title: cartridge_json[:title],
        files: cartridge_json[:files],
      }.tap do |hash|
        resources = filter_syllabus_for_modules ? module_ids : LINKED_RESOURCE_KEY.except("Attachment").values
        @_toc = create_universal_template(:toc)
        hash.merge!(
          :toc => @_toc,
          :syllabus => create_universal_template(:syllabus),
          :announcements => create_universal_template(:announcements)
        )
        resources.each do |resource_type|
          hash.reverse_merge!(resource_type => create_content_template(resource_type))
        end
      end
    end

    def get_item(resource_type, identifier)
      return {} unless cartridge_json[resource_type].present?
      cartridge_json[resource_type].find(-> { return {} }) do |resource|
        resource[:identifier] == identifier
      end
    end

    def update_item(resource_type, identifier, updated_item)
      get_item(resource_type, identifier).merge!(updated_item)
    end

    def create_universal_template(resource)
      template_content = cartridge_json[resource] || []
      template = Exporter.resource_template(resource)
      Template.new({resources: template_content, reference: resource}, template, self)
    end

    def create_content_template(resource)
      resource_content = sort_by_content ? cartridge_json[resource] : filter_content_to_module(resource)
      update_table_of_contents(resource, resource_content)
      Template.new({resources: resource_content, reference: resource}, base_template, self)
    end

    def update_table_of_contents(resource, resource_content)
      @_toc.content << {
        reference: resource,
        title: RESOURCE_TITLES[resource] || resource_content[:title],
        resource_content: sort_by_content ? resource_content : resource_content[:items]
      }
    end

    def base_template
      if sort_by_content
        "../templates/content_sorting_template.html.erb"
      else
        "../templates/module_sorting_template.html.erb"
      end
    end

    def self.resource_template(resource)
      "../templates/#{resource}_template.html.erb"
    end

    private
    def cartridge_converter
      @_cartridge_converter ||= Converters::CartridgeConverter.new({
        archive_file: cartridge
      })
    end
  end
end
