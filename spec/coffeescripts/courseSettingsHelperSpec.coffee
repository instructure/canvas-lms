define ['course_settings_helper', 'jquery'], (courseSettingsHelper, $) ->
  QUnit.module "course_settings_helper",
    test 'non LTI 2 tools', ->
      externalTool = document.createElement('li')
      externalTool.id = 'nav_edit_tab_id_context_external_tool_165'
      tabId = courseSettingsHelper.tabIdFromElement(externalTool)
      equal tabId, 'context_external_tool_165'

    test 'LTI 2 tools', ->
      externalTool = document.createElement('li')
      externalTool.id = 'nav_edit_tab_id_lti/message_handler_1'
      tabId = courseSettingsHelper.tabIdFromElement(externalTool)
      equal tabId, 'lti/message_handler_1'

    test 'standard navigation items', ->
      externalTool = document.createElement('li')
      externalTool.id = 'nav_edit_tab_id_4'
      tabId = courseSettingsHelper.tabIdFromElement(externalTool)
      equal tabId, '4'
