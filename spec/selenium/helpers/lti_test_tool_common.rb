module LtiTestToolCommon

  def create_lti_1_tool_provider(context)
    t = ContextExternalTool.new(
      domain: 'lti.docker',
      url: 'http://lti.docker/messages/blti',
      shared_secret: 'secret',
      consumer_key: 'key',
      name: 'LTI 1 Tool Provider'
    )
    t.context = context
    t.save!
  end

  def populate_tool_placements(tool_id)
    t = ContextExternalTool.find(tool_id)
    content_item_selection_request = [
      :editor_button, :homework_submission, :migration_selection, :assignment_selection, :link_selection
    ]
    content_item_selection = [
      :assignment_menu, :discussion_menu, :file_menu, :module_menu, :quiz_menu, :wiki_page_menu
    ]
    Lti::ResourcePlacement::PLACEMENTS.each do |extension_type|
      settings_hash = {
        'canvas_icon_class' => 'icon-lti',
        'icon_url' => "http =//lti.docker/selector.png?#{extension_type}",
        'text' => "#{extension_type} Text",
        'url' => 'http://lti.docker/messages/blti'
      }
      if content_item_selection_request.include? extension_type
        settings_hash['message_type'] = 'ContentItemSelectionRequest'
        settings_hash['url'] = 'http://lti.docker/messages/content-item'
      elsif content_item_selection.include? extension_type
        settings_hash['message_type'] = 'ContentItemSelection'
        settings_hash['url'] = 'http://lti.docker/messages/content-item'
      end
    t.send("#{extension_type}=", settings_hash) unless extension_type['resource_selection']
    end
    t.save
  end

  def add_content_item_selection_text(iframe, text)
    driver.switch_to.frame(iframe)
    f('.glyphicon-plus.add-icon').click
    wait_for_ajaximations
    f('#text').send_keys text
    f("button[type='button']").click
    wait_for_ajaximations
  end

  def submit_external_tool_config_widget
    driver.switch_to.frame(f('.ui-dialog.ui-widget'))
    f('.ui-dialog-buttonset .add_item_button').click
    wait_for_ajaximations
  end
end
