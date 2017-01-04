require File.expand_path(File.dirname(__FILE__) + '/../common')

module ContextModulesCommon
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

  def validate_context_module_status_icon(module_id, icon_expected)
    if icon_expected == 'no-icon'
      expect(fj("#context_module_#{module_id}")).not_to contain_jqcss(".completion_status i:visible")
    else
      expect(fj("#context_module_#{module_id} .completion_status i:visible")).to be_present
      context_modules_status = f("#context_module_#{module_id} .completion_status")
      expect(context_modules_status.find_element(:css, '.' + icon_expected)).to be_displayed
    end
  end

  def validate_context_module_item_icon(module_item_id, icon_expected)
    if icon_expected == 'no-icon'
      expect(f("#context_module_item_#{module_item_id}")).not_to contain_jqcss(".module-item-status-icon i:visible")
    else
      expect(fj("#context_module_item_#{module_item_id} .module-item-status-icon i:visible")).to be_present
      item_status = f("#context_module_item_#{module_item_id} .module-item-status-icon")
      expect(item_status.find_element(:css, '.' + icon_expected)).to be_displayed
    end
  end

  def vaildate_correct_pill_message(module_id, message_expected)
    pill_message = f("#context_module_#{module_id} .requirements_message li").text
    expect(pill_message).to eq message_expected
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
    f(".add_module_link").click
    expect(add_form).to be_displayed

    add_form
  end

  def add_module(module_name = 'Test Module')
    wait_for_modules_ui
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
    item_title = fj('.item_title:visible')
    expect(item_title).to be_displayed
    replace_content(item_title, item_title_text)
    yield if block_given?
    f('.add_item_button.ui-button').click
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

  def add_modules_and_set_prerequisites
    @module1 = @course.context_modules.create!(:name => "First module")
    @module2 = @course.context_modules.create!(:name => "Second module")
    @module3 = @course.context_modules.create!(:name => "Third module")
    @module3.prerequisites = "module_#{@module1.id},module_#{@module2.id}"
    @module3.save!
  end

  def edit_module_item(module_item)
    module_item.find_element(:css, '.al-trigger').click
    wait_for_ajaximations
    module_item.find_element(:css, '.edit_item_link').click
    edit_form = f('#edit_item_form')
    yield edit_form
    submit_dialog_form(edit_form)
    wait_for_ajaximations
  end

  def verify_persistence(title)
    refresh_page
    verify_module_title(title)
  end

  def verify_module_title(title)
    expect(f('#context_modules')).to include_text(title)
  end

  def need_to_wait_for_modules_ui?
    !@already_waited_for_modules_ui
  end

  def wait_for_modules_ui
    return unless need_to_wait_for_modules_ui?
    # context_modules.js has some setTimeout(..., 1000) calls
    # before it adds click handlers and drag/drop
    sleep 2
    @already_waited_for_modules_ui = true
  end

   def verify_edit_item_form
     f('.context_module_item .al-trigger').click
     wait_for_ajaximations
     f('.edit_item_link').click
     wait_for_ajaximations
     expect(f('#edit_item_form')).to be_displayed
     expect(f('#content_tag_title')).to be_displayed
     expect(f('#content_tag_indent_select')).to be_displayed
   end

  def lock_check_click(form)
    move_to_click('label[for=unlock_module_at]')
  end

  # so terrible
  def get(url)
    @already_waited_for_modules_ui = false
    super
    wait_for_modules_ui if url =~ %r{\A/courses/\d+/modules\z}
  end
end
