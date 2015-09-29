module CC::Exporter::Epub::Converters
  module TopicEpubConverter
    include CC::Exporter

    def convert_topics
      topics = []

      @manifest.css('resource[type=imsdt_xmlv1p1]').each do |res|
        cc_path = File.join @unzipped_file_path, res.at_css('file')['href']

        canvas_id = get_node_att(res, 'dependency', 'identifierref')
        if canvas_id && meta_res = @manifest.at_css(%{resource[identifier="#{canvas_id}"]})
          canvas_path = File.join @unzipped_file_path, meta_res.at_css('file')['href']
          meta_node = open_file_xml(canvas_path)
        else
          meta_node = nil
        end
        cc_doc = open_file_xml(cc_path)

        topics << convert_topic(cc_doc, meta_node)
      end

      topics
    end

    def convert_topic(cc_doc, meta_doc)
      topic = {}
      topic['description'] = get_node_val(cc_doc, 'text')
      topic['title'] = get_node_val(cc_doc, 'title')
      if meta_doc
        topic['title'] = get_node_val(meta_doc, 'title')
        topic['type'] = get_node_val(meta_doc, 'type')
        topic['discussion_type'] = get_node_val(meta_doc, 'discussion_type')
        topic['pinned'] = get_bool_val(meta_doc, 'pinned')
        topic['posted_at'] = get_time_val(meta_doc, 'posted_at')
        topic['lock_at'] = get_time_val(meta_doc, 'lock_at')
        topic['position'] = get_int_val(meta_doc, 'position')

        if asmnt_node = meta_doc.at_css('assignment')
          topic['assignment'] = assignment_data(asmnt_node)
        end
      end

      topic
    end
  end
end