#
# Helper class used for Content Library (e.g. Course ID = 1) logic in the models.
#
module ContentLibraryHelper

  # Takes the HTML for a page and replaces all links to other pages and assignments in
  # the Content Library with a link to the equivalent item in the "local_course_id". 
  # Note: if no "local_course_id" is is provided, the links are replaced with a 
  # LOCAL_COURSE_ID_TOKEN placeholder so that Javascript can replace the placeholders at load time
  # and adds a "bz-ajax-replace" CSS class so the JS can be extra defensive when looking for where to replace.
  # This is necessary b/c sometimes when we're creating a new wiki page from the
  # Content Library there is no way to get the Course ID before it's been fully saved 
  # and has a ContentTag associated with it.
  def replace_content_library_links_with_local_links(html_body, local_course_id = "LOCAL_COURSE_ID_TOKEN")
    doc = Nokogiri::HTML(html_body)
    links = doc.css('a')
    links.each do |link|
      url = link.attribute('href').to_s
      next if url.match(/\/courses\/1\/files/) # Don't adjust links to download files. We expose them to all courses and can just exist in the Content Library
      next if url.match(/\/courses\/1\/rubrics/) # Don't adjust links to rubrics. We expose them to all courses and can just exist in the Content Library
      if (url.match(/\/courses\/1\//))
        Rails.logger.debug "### replace_content_library_links_with_local_links: found matching url = #{url}. Replacing Content Library link with local link for local_course_id = #{local_course_id}"
        replaceUrl = nil
        local_assignment_id = nil
        if (url.match(/\/courses\/1\/pages/))
          replaceUrl = url.gsub(/\/courses\/1/, "/courses/#{local_course_id}")
        elsif (url.match(/\/courses\/1\/assignments\/\d+/))
          master_assignment_id = url[/\/courses\/1\/assignments\/(\d+)/, 1]
          if (local_course_id == "LOCAL_COURSE_ID_TOKEN")
            Rails.logger.error("### replace_content_library_links_with_local_links: adding new wiki page and can't determine local assignment id for #{url}. Go to this page in the Content Library, make any change, and re-save it to fix this")
            local_assignment_id = "RESAVE_THIS_PAGE_IN_CONTENT_LIBRARY_TO_FIX"
          else
            local_assignment = Assignment.where(:clone_of_id => master_assignment_id, :context_id => local_course_id).first
            if local_assignment.nil?
              Rails.logger.warn("### replace_content_library_links_with_local_links: skipping link to #{url} b/c can't determine local assignment id. master_assignment_id = #{master_assignment_id}, local_course_id = #{local_course_id}")
              local_assignment_id = "LINK_THE_PAGE_OR_ASSIGNMENT_FROM_CONTENT_LIBRARY_TO_FIX"
            else
              local_assignment_id = local_assignment.id
            end
          end
          replaceUrl = url.gsub(/\/courses\/1\/assignments\/\d+/, "/courses/#{local_course_id}/assignments/#{local_assignment_id}")
        else
          Rails.logger.debug("### replace_content_library_links_with_local_links: skipping link to #{url} becuase it's not an assignment or wiki page")
          next
        end
        Rails.logger.debug("### replace_content_library_links_with_local_links: replacing Content Library Course ID in: replaceUrl = #{replaceUrl}")
        link['href'] = replaceUrl
        if (local_course_id == "LOCAL_COURSE_ID_TOKEN")
          link['class'] ||= "" # handles appending to existing CSS classes
          link['class'] = link['class'] << " bz-ajax-replace"
        end
        dataApiEndpoint = link.attribute('data-api-endpoint').to_s
        if (!dataApiEndpoint.blank?)
          dataApiEndpointReplace = nil
          if (url.match(/\/courses\/1\/pages/))
            dataApiEndpointReplace = dataApiEndpoint.gsub(/\/courses\/1/, "/courses/#{local_course_id}")
          elsif (url.match(/\/courses\/1\/assignments\/\d+/) && !local_assignment_id.nil?)
            dataApiEndpointReplace = url.gsub(/\/courses\/1\/assignments\/\d+/, "/courses/#{local_course_id}/assignments/#{local_assignment_id}")
          end
          if (!dataApiEndpointReplace.nil?)
            link['data-api-endpoint'] = dataApiEndpointReplace
            Rails.logger.debug("### replace_content_library_links_with_local_links: replacing Content Library Course ID in: dataApiEndpointReplace = #{dataApiEndpointReplace}")
          end
        end
      end
    end
    doc.to_html
  end

end
