module CC::Exporter::Epub
  class Exporter

    RESOURCE_TEMPLATES = {
      modules: "../templates/module_epub_template.html.erb",
      assignments: "../templates/assignment_epub_template.html.erb",
      topics: "../templates/topic_epub_template.html.erb",
      quizzes: "../templates/quiz_epub_template.html.erb",
      wikis: "../templates/wiki_epub_template.html.erb"
    }.freeze

    RESOURCE_TITLES = {
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
        resources = sort_by_content ? [:assignments, :topics, :quizzes, :wikis] : [:modules]
        resources.each do |type|
          hash.merge!(type => create_template(type))
        end
      end
    end

    def module_hash(cartridge_json)
      {
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
