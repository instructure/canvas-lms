module CC::Exporter::Epub
  class Exporter

    include CC::Exporter::Epub::ModuleSorter

    RESOURCE_TITLES = {
      syllabus: "Syllabus",
      modules: "Modules",
      assignments: "Assignments",
      topics: "Discussion Topics",
      quizzes: "Quizzes",
      wikis: "Wiki Pages"
    }.freeze

    LINKED_RESOURCE_KEY = {
      "Assignment" => :assignments,
      "DiscussionTopic" => :topics,
      "Quizzes::Quiz" => :quizzes,
      "WikiPage" => :wikis
    }.freeze

    def initialize(cartridge, sort_by_content=false)
      @cartridge = cartridge
      @sort_by_content = sort_by_content || cartridge_json[:modules].empty?
    end
    attr_reader :cartridge, :sort_by_content

    def cartridge_json
      @_cartridge_json ||= Converters::CartridgeConverter.new({
        archive_file: cartridge
      }).export
    end

    def templates
      @_templates ||= {
        title: cartridge_json[:title],
        files: cartridge_json[:files]
      }.tap do |hash|
        resources = filter_syllabus_for_modules ? module_ids : LINKED_RESOURCE_KEY.values
        hash.merge!(:syllabus => create_syllabus)
        resources.each do |resource_type|
          hash.merge!(resource_type => create_template(resource_type))
        end
      end
    end

    def create_syllabus
      syllabus_content = cartridge_json[:syllabus]
      syllabus_template = Exporter.resource_template(:syllabus)
      Template.new({resources: syllabus_content, reference: :syllabus}, syllabus_template)
    end

    def create_template(resource)
      resource_items = sort_by_content ? cartridge_json[resource] : filter_content_to_module(resource)
      Template.new({resources: resource_items, reference: resource}, base_template)
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

  end
end
