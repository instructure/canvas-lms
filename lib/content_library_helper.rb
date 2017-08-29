#
# Helper class used for Content Library (e.g. Course ID = 1) logic in the models.
#
module ContentLibraryHelper

  # Takes the HTML for a page and inserts a LOCAL_COURSE_ID_TOKEN placeholder everywhere
  # that a link to another page or assignment in the Content Library is found so that
  # Javascript can replace the placeholders at load time.  Also, adds a "bz-ajax-replace" CSS class
  # so the JS can be extra defensive when looking for where to replace.
  # NOTE:  Can't just set the course IDs directly b/c sometimes we're creating a new wiki page from the
  # Content Library and there is no way to get the Course ID before it's been fully saved and has a ContentTag associated with it.
  def replace_content_library_links_with_local_link_placeholders(html_body)
    doc = Nokogiri::HTML(html_body)
    links = doc.css('a')
    links.each do |link|
      url = link.attribute('href').to_s
      next if url.match(/\/courses\/1\/files/) # Don't adjust links to download files. We expose them to all courses and can just exist in the Content Library
      next if url.match(/\/courses\/1\/rubrics/) # Don't adjust links to rubrics. We expose them to all courses and can just exist in the Content Library
      if (url.match(/\/courses\/1\//))
        replaceUrl = url.gsub(/\/courses\/1/, "/courses/LOCAL_COURSE_ID_TOKEN")
        Rails.logger.debug("### replace_content_library_links_with_local_links: replacing Content Library Course ID with LOCAL_COURSE_ID_TOKEN for: replaceUrl = #{replaceUrl}")
        link['href'] = replaceUrl
        link['class'] ||= "" # handles appending to existing CSS classes
        link['class'] = link['class'] << " bz-ajax-replace"
        dataApiEndpoint = link.attribute('data-api-endpoint').to_s
        if (!dataApiEndpoint.blank?)
          dataApiEndpointReplace = dataApiEndpoint.gsub(/\/courses\/1/, "/courses/LOCAL_COURSE_ID_TOKEN")
          link['data-api-endpoint'] = dataApiEndpointReplace
          Rails.logger.debug("### replace_content_library_links_with_local_links: replacing Content Library Course ID with LOCAL_COURSE_ID_TOKEN for: dataApiEndpointReplace = #{dataApiEndpointReplace}")
        end
      end
    end
    doc.to_html
  end

end
