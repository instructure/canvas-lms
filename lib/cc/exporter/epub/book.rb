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
          epub.add_item(file_data[:local_path], file)
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
        b.add_identifier('http:/example.jp/bookid_in_url', 'BookID', 'URL')
        b.add_title(title, nil, GEPUB::TITLE_TYPE::MAIN) do |title|
          title.file_as = "#{title} Epub"
          title.display_seq = 1
        end
        b.add_creator('Canvas by Instructure') do |creator|
          creator.display_seq = 1
        end
      end
    end

    def filename
      "#{SecureRandom.uuid}.#{title}.epub"
    end
  end
end
