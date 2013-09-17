  def val_page_title_present
    driver.title.should_not be_nil
  end

  def val_page_title_not_empty
    driver.title.should_not == ''
  end

  def val_image_alt_tags_present
    images = find_all_elements('img')
    if images.length > 0
      val_all_elements_attribute_presence(images, 'alt')
    end
  end

  def val_image_alt_tags_not_empty
    images = find_all_elements('img')
    if images.length > 0
      val_all_elements_attribute_not_empty(images, 'alt')
    end
  end

  def val_image_alt_tags_max_length
    images = find_all_elements('img')
    if images.length > 0
      val_text_max_length(images, 56)
    end
  end

  def val_link_name_uniqueness
    links_text = []
    links = find_all_elements('a')
    if links.length > 0
      links.each do |link|
        links_text << link.attribute('href') if link.attribute('href') != ''
      end
      links_text.uniq.length.should == links_text.length
    end
  end

  def val_input_alt_tags_present
    inputs = find_all_elements('input')
    if inputs.length > 0
      val_all_elements_attribute_presence(inputs, 'alt')
    end
  end

  def val_input_alt_tags_not_empty
    inputs = find_all_elements('input')
    if inputs.length > 0
      val_all_elements_attribute_not_empty(inputs, 'alt')
    end
  end

  def val_html_lang_attribute_present
    inputs = find_all_elements('html')
    val_all_elements_attribute_presence(inputs, 'lang')
  end

  def val_html_lang_attribute_not_empty
    images = find_all_elements('html')
    val_all_elements_attribute_not_empty(images, 'lang')
  end

  def val_h1_populated
    headers = find_all_elements('h1')
    headers.should_not be_empty
    val_all_elements_attribute_not_empty(headers, 'text')
  end

  def find_all_elements(type)
    driver.find_elements(:tag_name, "#{type}")
  end

  def val_all_tables_have_heading
    tables = find_all_elements('table')
    if tables.length > 0
      tables.each { |t| t.find_elements(:tag_name, 'th').count.should > 0 }
    end
  end

  def val_all_elements_attribute_presence(elements, attrib)
    elements.each { |element| element.attribute("#{attrib}").should_not be_nil }
  end

  def val_all_elements_attribute_not_empty(elements, attrib)
    elements.each { |element| element.attribute("#{attrib}").should_not == '' }
  end

  def val_text_max_length(elements, max_length)
    elements.each { |element| element.text.length.should < max_length.to_i }
  end