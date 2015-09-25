module CC::Exporter::Epub
  class Book
    include CC::Exporter::Epub::Converters

    def initialize(content)
      @title = content.delete(:title)
      @files = content.delete(:files)
      @content = content
    end
    attr_reader :content, :files, :title

    def add_files
      files.each do |file_data|
        File.open(file_data[:full_path]) do |file|
          epub.add_item(file_data[:local_path], file, file_data[:migration_id], {
            'media-type' => file_data[:media_type]
          })
        end
      end
    end

    def build
      add_files
      content.each do |key, template|
        epub.add_ordered_item("#{key}.xhtml").
          add_content(StringIO.new(template.parse)).
          toc_text(template.title)
      end
    end

    def create
      build
      path = File.join(Dir.tmpdir, filename)
      epub.generate_epub(path)
      path
    end

    def epub
      @_epub ||= GEPUB::Book.new.tap do |b|
        b.set_primary_identifier(pub_id)
        b.language = I18n.locale
        b.add_title(title, nil, GEPUB::TITLE_TYPE::MAIN) do |title|
          title.file_as = "#{title} Epub"
          title.display_seq = 1
        end
        b.add_creator('Canvas by Instructure') do |creator|
          creator.display_seq = 1
        end
      end
    end

    def pub_id
      @_pub_id ||= SecureRandom.uuid
    end

    def filename
      "#{pub_id}.#{title}.epub"
    end
  end
end
