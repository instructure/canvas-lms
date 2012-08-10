require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_examples_for "context module tests" do
  it_should_behave_like "in-process server selenium tests"

  def io
    require 'action_controller'
    require 'action_controller/test_process.rb'
    ActionController::TestUploadedFile.new(File.expand_path(File.dirname(__FILE__) + '/../fixtures/scribd_docs/txt.txt'), 'text/plain', true)
  end

  def add_existing_module_item(item_select_selector, module_name, item_name)
    add_module(module_name + 'Module')
    driver.find_element(:css, '.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', item_name)
    driver.find_element(:css, '.add_item_button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
    module_item.should include_text(item_name)
    module_item
  end

  def select_module_item(select_element_css, item_text)
    click_option(select_element_css, item_text)
  end

  def new_module_form
    keep_trying_until do
      driver.find_element(:css, '.add_module_link').click
      driver.find_element(:css, '.ui-dialog').should be_displayed
    end
    add_form = driver.find_element(:id, 'add_context_module_form')
    add_form
  end

  def add_module(module_name = 'Test Module')
    add_form = new_module_form
    replace_content(add_form.find_element(:id, 'context_module_name'), module_name)
    submit_form(add_form)
    wait_for_ajaximations
    add_form.should_not be_displayed
    driver.find_element(:id, 'context_modules').should include_text(module_name)
  end

  def add_new_module_item(item_select_selector, module_name, new_item_text, item_title_text)
    add_module(module_name + 'Module')
    driver.find_element(:css, '.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', new_item_text)
    item_title = keep_trying_until do
      item_title = find_with_jquery('.item_title:visible')
      item_title.should be_displayed
      item_title
    end
    replace_content(item_title, item_title_text)
    yield if block_given?
    driver.find_element(:css, '.add_item_button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
    module_item.should include_text(item_title_text)
  end

  def add_new_external_item(module_name, url_text, page_name_text)
    add_module(module_name + 'Module')
    driver.find_element(:css, '.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    wait_for_ajaximations
    url_input = find_with_jquery('input[name="url"]:visible')
    title_input = find_with_jquery('input[name="title"]:visible')
    replace_content(url_input, url_text)

    replace_content(title_input, page_name_text)

    driver.find_element(:css, '.add_item_button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
    module_item.should include_text(page_name_text)
  end

  def course_module
    @module = @course.context_modules.create!(:name => "some module")
  end

  def edit_module_item(module_item)
    driver.execute_script("$(arguments[0]).addClass('context_module_item_hover')", module_item)
    module_item.find_element(:css, '.edit_item_link').click
    edit_form = driver.find_element(:id, 'edit_item_form')
    yield edit_form
    submit_form(edit_form)
    wait_for_ajaximations
  end
end