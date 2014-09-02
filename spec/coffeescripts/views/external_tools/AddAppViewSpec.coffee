define [
  'Backbone'
  'jquery'
  'compiled/views/ExternalTools/AddAppView'
  'compiled/models/ExternalTool'
  'helpers/jquery.simulate'
], (Backbone, $, AddAppView, ExternalTool) ->

  view = null
  app = null
  server = null

  module "ExternalTools",
    setup: ->
      $('.ui-dialog').remove()

      server = sinon.fakeServer.create()
      server.respondWith("POST", /external_tools/,
        [200, { "Content-Type": "application/json" }, JSON.stringify([
          {
            "consumer_key": "N/A",
            "created_at": "2013-05-21T08:42:47-06:00",
            "description": "Link to Google (http://google.com)",
            "domain": null,
            "id": 104,
            "name": "Redirect Tool",
            "updated_at": "2013-05-21T08:42:47-06:00",
            "url": "https://lti-examples.heroku.com/tool_redirect?url=http%3A%2F%2Fgoogle.com",
            "privacy_level": "anonymous",
            "custom_fields": {},
            "workflow_state": "anonymous",
            "vendor_help_link": null,
            "user_navigation": {
              "url": "https://lti-examples.heroku.com/tool_redirect?url=http%3A%2F%2Fgoogle.com",
              "text": "Google",
              "enabled": "true",
              "label": "Google"
            },
            "course_navigation": {
              "url": "https://lti-examples.heroku.com/tool_redirect?url=http%3A%2F%2Fgoogle.com",
              "text": "Google",
              "enabled": "true",
              "label": "Google"
            },
            "account_navigation": {
              "url": "https://lti-examples.heroku.com/tool_redirect?url=http%3A%2F%2Fgoogle.com",
              "text": "Google",
              "enabled": "true",
              "label": "Google"
            },
            "resource_selection": null,
            "editor_button": null,
            "homework_submission": null,
            "icon_url": "https://www.edu-apps.org/tools/redirect/icon.png"
          }
        ])])

      app = new Backbone.Model(
        {
          "name": "Redirect Tool",
          "id": "redirect",
          "description": "Add links to external web resources that show up as navigation items in course.",
          "extensions": [
            "course_nav",
            "user_nav",
            "account_nav"
          ],
          "launch_url": "https://lti-examples.heroku.com/tool_redirect?url={{ escape:url }}",
          "config_options": [
            {
              "name": "name",
              "description": "Link Name",
              "type": "text",
              "value": "Link",
              "required": true
            },
            {
              "name": "url",
              "description": "URL Redirect",
              "type": "text",
              "value": "https://",
              "required": true
            },
            {
              "name": "course_nav",
              "description": "Show in Course Navigation",
              "type": "checkbox",
              "value": "1"
            },
            {
              "name": "user_nav",
              "description": "Show in User Navigation",
              "type": "checkbox",
              "value": "1"
            },
            {
              "name": "account_nav",
              "description": "Show in Account Navigation",
              "type": "checkbox",
              "value": "1"
            }
          ],
          "variable_name": "{{ name }}",
          "variable_description": "Link to {{ name }} ({{ url }})",
          "ratings_count": 4,
          "comments_count": 4,
          "avg_rating": 4.5,
          "requires_secret": true
          "banner_url": "https://www.edu-apps.org/tools/redirect/banner.png",
          "logo_url": "https://www.edu-apps.org/tools/redirect/logo.png",
          "icon_url": "https://www.edu-apps.org/tools/redirect/icon.png",
          "config_url": "https://www.edu-apps.org/tools/redirect/config.xml"
        }
      )

      view = new AddAppView
        model: new ExternalTool
        app: app
      view.render()

    teardown: ->
      view.remove()
      server.restore()

  test 'AddAppView: render', ->
    equal $.trim($('.ui-dialog-title:visible').text()), "Add App",
      '"Add App" appears as dialog title'

    equal $('#canvas_app_name').val(), app.get('name'),
      'Name is pre-populated from app'

    equal $('fieldset .control-group').size(), 8,
      'All fields are present (6 plus key/secret)'

#  Causing an intermitent spec failure
#  test 'AddAppView: submit', ->
#    $('#app_name').val('Google')
#    $('#app_url').val('http://google.com')
#    $('#app_course_nav').prop('checked', true)
#    $('#app_user_nav').prop('checked', true)
#    $('#app_account_nav').prop('checked', true)
#    view.submit()
#    equal view.model.get('config_type'), 'by_url',
#      'config type should be set'
#    equal view.model.get('description'), app.get('description'),
#      'description should be set'
#    equal(new RegExp("edu-apps").exec(view.model.get('config_url'))[0], "edu-apps",
#      'config_url should be set')
#
#  test 'AddAppView: validate', ->
#    view.submit()
#    equal $('.control-group.error').size(), 4,
#      'Missing required fields appear with red borders'

  test 'AddAppView: onSaveFail', ->
    view.model.trigger('error')
    ok view.$('.alert.alert-error')
