module CC::Exporter::Epub::Converters
  module WikiEpubConverter
    include CC::Exporter
    include CC::CCHelper

    def convert_wikis
      wikis = []

      wiki_dir = File.join(@unzipped_file_path, 'wiki_content')
      Dir["#{wiki_dir}/**/**"].each do |path|
        doc = open_file(path)
        wikis << convert_wiki(doc, path)
      end

      wikis
    end

    def convert_wiki(doc, path)
      wiki = {}
      wiki_name = File.basename(path, '.html')
      title, body, meta = get_html_title_and_body_and_meta_fields(doc)
      wiki[:title] = title
      wiki[:front_page] = meta['front_page'] == 'true'
      wiki[:text] = body
      wiki[:url_name] = wiki_name
      wiki
    end

  end
end