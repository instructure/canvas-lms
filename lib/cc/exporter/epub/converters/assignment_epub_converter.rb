module CC::Exporter::Epub::Converters
  module AssignmentEpubConverter
    include CC::Exporter

    def convert_assignments
      assignments = []
      @manifest.css('resource[type$=learning-application-resource]').each do |res|
        meta_path = res.at_css('file[href$="assignment_settings.xml"]')
        next unless meta_path

        meta_path = File.join @unzipped_file_path, meta_path['href']
        html_path = File.join @unzipped_file_path, res.at_css('file[href$="html"]')['href']

        meta_node = open_file_xml(meta_path)
        html_node = open_file(html_path)

        next unless html_node

        assignments << assignment_data(meta_node, html_node)
      end
      assignments
    end

    def assignment_data(meta_doc, html_doc=nil)
      assignment = {}

      if html_doc
        _title, body = get_html_title_and_body(html_doc)
        assignment['description'] = body
      end
      ['title', "allowed_extensions", "grading_type", "submission_types"].each do |string_type|
        val = get_node_val(meta_doc, string_type)
        assignment[string_type] = val unless val.nil?
      end
      ['due_at', 'lock_at', 'unlock_at'].each do |date_type|
        val = get_node_val(meta_doc, date_type)
        assignment[date_type] = val unless val.nil?
      end
      ['points_possible'].each do |f_type|
        val = get_float_val(meta_doc, f_type)
        assignment[f_type] = val unless val.nil?
      end
      assignment
    end
  end
end
