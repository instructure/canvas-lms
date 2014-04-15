define [
  'Backbone'
  'jquery'
  'compiled/views/ExternalTools/ExternalToolView'
  'compiled/models/ExternalTool'
  'helpers/jquery.simulate'
], (Backbone, $, ExternalToolView, ExternalTool) ->

  view = null
  tool = null

  module "ExternalTools",

    setup: ->
      tool = new ExternalTool(
        {
          "consumer_key": "N/A",
          "created_at": "2013-05-21T09:16:44-06:00",
          "description": "Online video lessons for math, science, etc.",
          "domain": null,
          "id": 106,
          "name": "Khan Academy",
          "updated_at": "2013-05-21T09:16:44-06:00",
          "url": "https://www.edu-apps.org/tool_redirect?id=khan_academy",
          "privacy_level": "anonymous",
          "custom_fields": {},
          "workflow_state": "anonymous",
          "vendor_help_link": null,
          "user_navigation": null,
          "course_navigation": null,
          "account_navigation": null,
          "resource_selection": {
            "url": "https://www.edu-apps.org/tool_redirect?id=khan_academy",
            "icon_url": "https://www.edu-apps.org/tools/khan_academy/icon.png",
            "text": "Khan Academy",
            "selection_width": 690,
            "selection_height": 530,
            "enabled": "true",
            "label": "Khan Academy"
          },
          "editor_button": {
            "url": "https://www.edu-apps.org/tool_redirect?id=khan_academy",
            "icon_url": "https://www.edu-apps.org/tools/khan_academy/icon.png",
            "text": "Khan Academy",
            "selection_width": 690,
            "selection_height": 530,
            "enabled": "true",
            "label": "Khan Academy"
          },
          "homework_submission": null,
          "migration_selection": null,
          "icon_url": "https://www.edu-apps.org/tools/khan_academy/icon.png"
        }
      )

      view = new ExternalToolView
        model: tool

      view.render()
      $('#fixtures').html view.$el

    teardown: ->
      view.remove()

  test 'ExternalToolView: render', ->
    equal $('.external_tool').size(), 1,
      'shows the external tool table row'
    equal $('.external_tool').html(), tool.get('name'),
      'shows the name of the tool'

    ok $('.editor_button'), 'editor button is visible'
    ok $('.resource_selection'), 'resource select box is visible'
    ok $('.edit_tool_link'), 'edit tool link is visible'
    ok $('.delete_tool_link'), 'delete tool link is visible'

  test 'ExternalToolView: toJSON', ->
    json = view.toJSON()
    equal json.description, tool.get('description'),
      'sets the description'
    equal json.extras.length, 2,
      'sets the extensions'
