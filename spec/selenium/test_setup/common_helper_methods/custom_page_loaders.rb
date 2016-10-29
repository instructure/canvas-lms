module CustomPageLoaders
  # you can pass an array to use the rails polymorphic_path helper, example:
  # get [@course, @announcement] => "http://10.0.101.75:65137/courses/1/announcements/1"
  def get(link)
    is_first_request_of_spec = !driver.ready_for_interaction
    driver.ready_for_interaction = true
    link = polymorphic_path(link) if link.is_a? Array

    # If the new link is identical to the old link except for the hash, we don't
    # want to actually expect a new page load, cuz it won't happen.
    current_uri = URI.parse(driver.execute_script("return window.location.toString()"))
    new_uri = URI.parse(link)

    if current_uri.path == new_uri.path && (current_uri.query || '') == (new_uri.query || '') && (new_uri.fragment || current_uri.fragment)
      driver.get(app_host + link)
      # if we're just changing the hash of the url of the previous spec,
      # force a reload, cuz the `get` above won't
      driver.navigate.refresh if is_first_request_of_spec
      close_modal_if_present
      wait_for_ajaximations
    else
      expect_new_page_load(true) do
        driver.get(app_host + link)
      end
    end
  end

  def refresh_page
    expect_new_page_load { driver.navigate.refresh }
  end
end
