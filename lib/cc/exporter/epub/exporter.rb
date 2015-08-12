module CC::Exporter::Epub
  class Exporter
    def initialize(cartridge)
      @cartridge = cartridge
    end
    attr_reader :cartridge

    def cartridge_json
      @_cartridge_json ||= Converters::CartridgeConverter.new({
        archive_file: cartridge
      }).export
    end

    def templates
      @_templates ||= {
        title: cartridge_json[:title],
        wikis: (Template.new(cartridge_json[:wikis], '../templates/wiki_epub_template.html.erb', 'Wiki Pages')),
        assignments: (
          Template.new(cartridge_json[:assignments], '../templates/assignment_epub_template.html.erb', 'Assignments')
        ),
        topics: (
          Template.new(cartridge_json[:topics], '../templates/topic_epub_template.html.erb', 'Discussion Topics')
        ),
        quizzes: (Template.new(cartridge_json[:wikis], '../templates/wiki_epub_template.html.erb', 'Quizzes'))
      }
    end
  end
end
