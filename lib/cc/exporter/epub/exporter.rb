module CC::Exporter::Epub
  class Exporter

    RESOURCE_TEMPLATES = {
      syllabus: "../templates/syllabus_epub_template.html.erb",
      modules: "../templates/module_epub_template.html.erb",
      assignments: "../templates/assignment_epub_template.html.erb",
      topics: "../templates/topic_epub_template.html.erb",
      quizzes: "../templates/quiz_epub_template.html.erb",
      wikis: "../templates/wiki_epub_template.html.erb"
    }.freeze

    RESOURCE_TITLES = {
      syllabus: "Syllabus",
      modules: "Modules",
      assignments: "Assignments",
      topics: "Discussion Topics",
      quizzes: "Quizzes",
      wikis: "Wiki Pages"
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
        resources = filter_syllabus_for_modules ? [:modules] : [:assignments, :topics, :quizzes, :wikis]
        hash.merge!(:syllabus => create_syllabus)
        resources.each do |type|
          hash.merge!(type => create_template(type))
        end
      end
    end

    def module_hash(cartridge_json)
      {
        syllabus: cartridge_json[:syllabus],
        modules: cartridge_json[:modules],
        course_content: cartridge_json.except(:modules),
        linked_resource_key: {
          "Assignment" => :assignments,
          "DiscussionTopic" => :topics,
          "Quizzes::Quiz" => :quizzes,
          "WikiPage" => :wikis
        }
      }
    end

    def filter_syllabus_for_modules
      return false if sort_by_content
      filtered_ids = []
      cartridge_json[:modules].each do |mod|
        filtered_ids << mod[:items].map{|item| item["linked_resource_id"] if item["for_syllabus"]}.compact
      end
      cartridge_json[:syllabus].map! do |item|
        if filtered_ids.flatten.include?(item[:identifier])
          item[:href] = "modules.xhtml"
          item
        end
      end
      cartridge_json[:syllabus].compact!
      # need this because compact! returns nil
      true
    end

    def create_syllabus
      syllabus_content = cartridge_json[:syllabus]
      syllabus_template = RESOURCE_TEMPLATES[:syllabus]
      Template.new({resources: syllabus_content, type: :syllabus}, syllabus_template)
    end

    def create_template(resource_type)
      resources = if resource_type == :modules
                    module_hash(cartridge_json)
                  else
                    cartridge_json[resource_type]
                  end
      Template.new({resources: resources, type: resource_type}, base_template)
    end

    def base_template
      if sort_by_content
        "../templates/content_sorting_template.html.erb"
      else
        "../templates/module_sorting_template.html.erb"
      end
    end

  end
end
