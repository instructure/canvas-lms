require File.expand_path(File.dirname(__FILE__) + '/../common')

  def io
    fixture_file_upload('scribd_docs/txt.txt', 'text/plain', true)
  end


  def create_modules(number_to_create, published=false)
    modules = []
    number_to_create.times do |i|
      m = @course.context_modules.create!(:name => "module #{i}")
      m.unpublish! unless published
      modules << m
    end
    modules
  end

  def publish_module
    fj('#context_modules .publish-icon-publish').click
    wait_for_ajaximations
  end

  def unpublish_module
    fj('#context_modules .publish-icon-published').click
    wait_for_ajaximations
  end

  def test_relock
    wait_for_ajaximations
    expect(f('#relock_modules_dialog')).to be_displayed
    ContextModule.any_instance.expects(:relock_progressions).once
    fj(".ui-dialog:visible .ui-button:first-child").click
    wait_for_ajaximations
  end

  def create_context_module(module_name)
    context_module = @course.context_modules.create!(:name => module_name, :require_sequential_progress => true)
    context_module
  end

  def go_to_modules
    get "/courses/#{@course.id}/modules"
  end

  def validate_context_module_status_text(module_num, text_to_validate)
    context_modules_status = ff('.context_module .progression_container')
    expect(context_modules_status[module_num]).to include_text(text_to_validate)
  end

  def navigate_to_module_item(module_num, link_text)
    context_modules = ff('.context_module')
    expect_new_page_load { context_modules[module_num].find_element(:link, link_text).click }
    go_to_modules
  end

  def assert_page_loads
    get "/courses/#{@course.id}/modules"
    expect(f('.name').text).to eq "some module"
  end

  def add_existing_module_item(item_select_selector, module_name, item_name)
    add_module(module_name + 'Module')
    f('.ig-header-admin .al-trigger').click
    wait_for_ajaximations
    f('.add_module_item_link').click
    wait_for_ajaximations
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', item_name)
    fj('.add_item_button.ui-button').click
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
    add_form = f('#add_context_module_form')
    keep_trying_until do
      driver.execute_script("$('.add_module_link').trigger('click')")
      wait_for_ajaximations
      expect(add_form).to be_displayed
    end

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
    f('.ig-header-admin .al-trigger').click
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
    fj('.add_item_button.ui-button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(item_title_text)
  end

  def add_new_external_item(module_name, url_text, page_name_text)
    add_module(module_name + 'Module')
    f('.ig-header-admin .al-trigger').click
    wait_for_ajaximations
    f('.add_module_item_link').click
    wait_for_ajaximations
    select_module_item('#add_module_item_select', module_name)
    wait_for_ajaximations
    url_input = fj('input[name="url"]:visible')
    title_input = fj('input[name="title"]:visible')
    replace_content(url_input, url_text)

    replace_content(title_input, page_name_text)

    fj('.add_item_button.ui-button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(page_name_text)
    tag
  end

  def course_module
    @module = @course.context_modules.create!(:name => "some module")
  end

  def edit_module_item(module_item)
    module_item.find_element(:css, '.al-trigger').click
    wait_for_ajaximations
    module_item.find_element(:css, '.edit_item_link').click
    edit_form = f('#edit_item_form')
    yield edit_form
    submit_form(edit_form)
    wait_for_ajaximations
  end

  def verify_persistence(title)
    refresh_page
    expect(f('#context_modules')).to include_text(title)
  end

  def wait_for_modules_ui
    # context_modules.js has some setTimeout(..., 1000) calls
    # before it adds click handlers and drag/drop
    sleep 2
  end
