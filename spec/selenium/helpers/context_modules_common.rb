require File.expand_path(File.dirname(__FILE__) + '/../common')

  def io
    fixture_file_upload('scribd_docs/txt.txt', 'text/plain', true)
  end

  def add_existing_module_item(item_select_selector, module_name, item_name)
    add_module(module_name + 'Module')
    f('.admin-links.al-trigger').click
    wait_for_ajaximations
    f('.add_module_item_link').click
    wait_for_ajaximations
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', item_name)
    fj('.add_item_button:visible').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(item_name)
    module_item
  end

  def select_module_item(select_element_css, item_text)
    click_option(select_element_css, item_text)
  end

  def new_module_form
    keep_trying_until do
      driver.execute_script("$('.context-modules-main-toolbar .btn-primary').trigger('click')")
      wait_for_ajaximations
      expect(f('.ui-dialog')).to be_displayed
    end

    add_form = f('#add_context_module_form')
    add_form
  end

  def add_module(module_name = 'Test Module')
    add_form = new_module_form
    replace_content(add_form.find_element(:id, 'context_module_name'), module_name)
    submit_form(add_form)
    wait_for_ajaximations
    expect(add_form).not_to be_displayed
    expect(f('#context_modules')).to include_text(module_name)
  end

  def add_new_module_item(item_select_selector, module_name, new_item_text, item_title_text)
    add_module(module_name + 'Module')
    f('.admin-links.al-trigger').click
    f('.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', new_item_text)
    item_title = keep_trying_until do
      item_title = fj('.item_title:visible')
      expect(item_title).to be_displayed
      item_title
    end
    replace_content(item_title, item_title_text)
    yield if block_given?
    fj('.add_item_button:visible').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(item_title_text)
  end

  def add_new_external_item(module_name, url_text, page_name_text)
    add_module(module_name + 'Module')
    f('.admin-links.al-trigger').click
    wait_for_ajaximations
    f('.add_module_item_link').click
    wait_for_ajaximations
    select_module_item('#add_module_item_select', module_name)
    wait_for_ajaximations
    url_input = fj('input[name="url"]:visible')
    title_input = fj('input[name="title"]:visible')
    replace_content(url_input, url_text)

    replace_content(title_input, page_name_text)

    fj('.add_item_button:visible').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(page_name_text)
  end

  def course_module
    @module = @course.context_modules.create!(:name => "some module")
  end

  def edit_module_item(module_item)
    driver.execute_script("$(arguments[0]).addClass('context_module_item_hover')", module_item)
    module_item.find_element(:css, '.edit_item_link').click
    edit_form = f('#edit_item_form')
    yield edit_form
    submit_form(edit_form)
    wait_for_ajaximations
  end
