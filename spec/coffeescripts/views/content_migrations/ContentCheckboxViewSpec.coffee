define [
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/views/content_migrations/ContentCheckboxView'
  'compiled/models/content_migrations/ContentCheckbox'
  ], (CheckboxCollection, CheckboxView, CheckboxModel) ->

  class CheckboxHelper

    @renderView = (options) -> 
      options ||= {}

      checkboxModel = new CheckboxModel options

      # Set defaults
      checkboxModel.property ||= "copy[all_course_settings]"
      checkboxModel.title ||= "Course Settings"
      checkboxModel.type ||= "course_settings"

      @checkboxView = new CheckboxView(model: checkboxModel) 
      @$fixtures.html @checkboxView.render().el

    @teardown = -> @checkboxView.remove()

    @$fixtures = $('#fixtures')
    @checkboxView = undefined
    @$checkbox = -> @$fixtures.find('[type=checkbox]').first()
    @$sublevelCheckboxes = -> @checkboxView.$el.find('ul [type=checkbox]')
    @serverResponse = -> [200, { "Content-Type": "application/json" }, JSON.stringify([
                                              {
                                                  "type": "assignment_groups",
                                                  "property": "copy[assignment_groups][i6314c45816f1cc6d9519d88e4b7f64ab]",
                                                  "title": "Assignments",
                                                  "migration_id": "i6314c45816f1cc6d9519d88e4b7f64ab",
                                                  "sub_items": [
                                                      {
                                                          "type": "assignments",
                                                          "property": "copy[assignments][i1a139fc4cbf94f961973c63bd90fc1c7]",
                                                          "title": "Assignment 1",
                                                          "migration_id": "i1a139fc4cbf94f961973c63bd90fc1c7"
                                                      },
                                                      {
                                                          "type": "assignments",
                                                          "property": "copy[assignments][i7af74171d7c7207f1578328d8bbf9dae]",
                                                          "title": "Unnamed Quiz",
                                                          "migration_id": "i7af74171d7c7207f1578328d8bbf9dae"
                                                      },
                                                      {
                                                          "type": "assignments",
                                                          "property": "copy[assignments][i4af043da2399a5ec221f666b38714fa8]",
                                                          "title": "Unnamed Quiz",
                                                          "migration_id": "i4af043da2399a5ec221f666b38714fa8"
                                                      }
                                                  ]
                                              }
                                          ])]

  module "Toplevel Content Checkbox Behaviors", 
    teardown: -> CheckboxHelper.teardown()

  test 'renders a checkbox with name set from model property', -> 
    CheckboxHelper.renderView(property: 'copy[all_course_settings]')
    nameValue = CheckboxHelper.$checkbox().prop('name')

    equal nameValue, 'copy[all_course_settings]', 'Adds the correct name attribute from property'

  test 'checkbox is checked by default', -> 
    CheckboxHelper.renderView()
    ok CheckboxHelper.$checkbox().is(":checked"), "Checkbox is checked"

  module "Sublevel Content Checkbox Behaviors",
    setup: ->
      @server = sinon.fakeServer.create()
    teardown: -> 
      @server.restore()
      CheckboxHelper.teardown()
  test 'unchecking a checkbox with a url attribute creates a sub-level collection with that url', -> 
    url = "http://www.google.com"
    CheckboxHelper.renderView(sub_items_url: url)
    CheckboxHelper.$checkbox().click()
    checkboxView = CheckboxHelper.checkboxView

    equal checkboxView.sublevelCheckboxes.url, url, "Sets a sublevel checkbox collections url"

  test 'unchecking a checkbox calls fetch on a CheckboxCollection', -> 
    fetch = sinon.spy(CheckboxCollection.prototype, 'fetch')
    url = "http://www.google.com"
    CheckboxHelper.renderView(sub_items_url: url)
    CheckboxHelper.$checkbox().click()
    ok fetch.calledOnce, "Calls fetch on the CheckboxCollection"

  test 'renders sublevel checkboxes in their own ul tag', ->
    url = '/api/v1/courses/42/content_migrations/5/selective_data?type=assignments'
    @server.respondWith('GET', url, CheckboxHelper.serverResponse())

    CheckboxHelper.renderView(sub_items_url: url)
    CheckboxHelper.$checkbox().click()
    @server.respond()

    equal CheckboxHelper.$sublevelCheckboxes().length, 4, "Renders all sublevel checkboxes"

  test 'checking and unchecking parent checkboxes checks child checkboxes', ->
    url = '/api/v1/courses/42/content_migrations/5/selective_data?type=assignments'
    @server.respondWith('GET', url, CheckboxHelper.serverResponse())

    CheckboxHelper.renderView(sub_items_url: url)
    CheckboxHelper.$checkbox().click()
    @server.respond()
    $subCheckboxes = CheckboxHelper.checkboxView.$el.find('ul').last().find('[type=checkbox]')
    
    CheckboxHelper.$sublevelCheckboxes().first().click()
    $subCheckboxes.each ->
      ok !$(this).is(':checked'), "Unchecked child checkboxes"

    CheckboxHelper.$sublevelCheckboxes().first().click()
    $subCheckboxes.each ->
      ok $(this).is(':checked'), "Checked child checkboxes"
