require File.expand_path(File.dirname(__FILE__) + '/../common')

module EportfoliosCommon
  def create_eportfolio(is_public = false)
    get "/dashboard/eportfolios"
    f(".add_eportfolio_link").click
    wait_for_animations
    replace_content f("#eportfolio_name"), "student content"
    f("#eportfolio_public").click if is_public
    expect_new_page_load { f("#eportfolio_submit").click }
    eportfolio = Eportfolio.find_by_name("student content")
    expect(eportfolio).to be_valid
    expect(eportfolio.public).to be_truthy if is_public
    expect(f('#content h2')).to include_text(I18n.t('headers.welcome', "Welcome to Your ePortfolio"))
  end

  def entry_verifier(opts={})
    entry= @eportfolio.eportfolio_entries.first
    if opts[:section_type]
      expect(entry.content.first[:section_type]).to eq opts[:section_type]
    end

    if opts[:content]
      expect(entry.content.first[:content]).to include(opts[:content])
    end
  end

  def organize_sections
    f('#section_list_manage .manage_sections_link').click
    sections.each do |section|
      expect(section).to contain_jqcss('.section_settings_menu:visible')
    end
  end

  def add_eportfolio_section(name)
    organize_sections
    f('#section_list_manage .add_section_link').click
    f('#section_list input').send_keys(name, :return)
    wait_for_ajaximations
    f('#section_list_manage .done_editing_button').click
  end

  def sections
    ffj('#section_list li:visible')
  end

  def delete_eportfolio_section(page)
    organize_sections
    page.find_element(:css, '.section_settings_menu').click
    page.find_element(:css, '.remove_section_link').click
    driver.switch_to.alert.accept
    wait_for_animations
    f('#section_list_manage .done_editing_button').click
  end

  def move_section_to_bottom(section)
    section_name = section.find_element(:css, '.name').text
    section.find_element(:css, '.section_settings_menu').click
    section.find_element(:css, '.move_section_link').click
    move_to_modal = f("[aria-label=\"Modal dialog: Move Section #{section_name}\"]")
    click_option('#MoveToDialog__select', '-- At the bottom --', :text)
    move_to_modal.find_element(:css, '#MoveToDialog__move').click
  end

  def add_eportfolio_page(page_title)
    organize_pages
    f('.add_page_link').click
    f('#page_name').send_keys(page_title, :return)
    wait_for_ajaximations
    f('#section_pages .done_editing_button').click
  end

  def delete_eportfolio_page(page_title)
    organize_pages
    page_title.find_element(:css, '.page_settings_menu').click
    page_title.find_element(:css, '.remove_page_link').click
    driver.switch_to.alert.accept
    wait_for_animations
    f('#section_pages .done_editing_button').click
  end

  def move_page_to_bottom(page)
    page_name = page.find_element(:css, '.name').text
    page.find_element(:css, '.page_settings_menu').click
    page.find_element(:css, '.move_page_link').click
    move_to_modal = f("[aria-label=\"Modal dialog: Move Page #{page_name}\"]")
    click_option('#MoveToDialog__select', '-- At the bottom --', :text)
    move_to_modal.find_element(:css, '#MoveToDialog__move').click
  end

  def pages
    ffj('#page_list li:visible')
  end

  def organize_pages
    f('.manage_pages_link').click
    wait_for_animations
    pages.each do |page|
      expect(page).to contain_jqcss('.page_settings_menu:visible')
    end
    expect(f('.add_page_link')).to be_displayed
  end
end
