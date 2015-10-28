module CC::Exporter::Epub::Converters
  module ObjectPathConverter
    include CC::CCHelper

    # Find `<a>` tags whose hrefs contain either the OBJECT_TOKEN or the
    # WIKI_TOKEN, and replace them with a link to the xhtml page based
    # on the path part between the placeholder and the identifer (in the
    # example below, this means `assignments`), and an anchor of the
    # identifier itself.
    #
    # Turns this:
    #
    # "$CANVAS_OBJECT_REFERENCE$/assignments/i5f4cd2e04f1089c1c5060e9761400516"
    #
    # into this:
    #
    # "assignments.xhtml#i5f4cd2e04f1089c1c5060e9761400516"
    def convert_object_paths!(html_node)
      html_node.tap do |node|
        node.search(object_path_selector).each do |tag|
          tag['href'] = href_for_tag(tag)
        end
      end
    end

    def href_for_tag(tag)
      match = tag['href'].match(/([a-z]+)\/(.+)/)

      if sort_by_content
        "#{match[1]}.xhtml##{match[2]}"
      else
        item = get_item(match[1], match[2])
        item[:href]
      end
    end

    def object_path_selector
      return [
        "a", [
          "[href*='#{OBJECT_TOKEN.gsub('$', '')}']",
          "[href*='#{WIKI_TOKEN.gsub('$', '')}']"
        ].join(',')
      ].join
    end

    def sort_by_content
      true
    end
  end
end
