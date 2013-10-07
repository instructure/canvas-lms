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
      checkboxModel.property ||= "copy[all_assignments]"
      checkboxModel.title ||= "Assignments"
      checkboxModel.type ||= "assignments"

      checkboxCollection = new CheckboxCollection [checkboxModel],
                               isTopLevel: true

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
                                                  "property": "copy[assignment_groups][id_i6314c45816f1cc6d9519d88e4b7f64ab]",
                                                  "title": "Assignments",
                                                  "migration_id": "i6314c45816f1cc6d9519d88e4b7f64ab",
                                                  "sub_items": [
                                                      {
                                                          "type": "assignments",
                                                          "property": "copy[assignments][id_i1a139fc4cbf94f961973c63bd90fc1c7]",
                                                          "title": "Assignment 1",
                                                          "migration_id": "i1a139fc4cbf94f961973c63bd90fc1c7"
                                                      },
                                                      {
                                                          "type": "assignments",
                                                          "property": "copy[assignments][id_i7af74171d7c7207f1578328d8bbf9dae]",
                                                          "title": "Unnamed Quiz",
                                                          "migration_id": "i7af74171d7c7207f1578328d8bbf9dae"
                                                      },
                                                      {
                                                          "type": "assignments",
                                                          "property": "copy[assignments][id_i4af043da2399a5ec221f666b38714fa8]",
                                                          "title": "Unnamed Quiz",
                                                          "migration_id": "i4af043da2399a5ec221f666b38714fa8",
                                                          "linked_resource": {
                                                            "type": "assignments",
                                                            "migration_id": "i7af74171d7c7207f1578328d8bbf9dae"
                                                          }
                                                      }
                                                  ]
                                              }
                                          ])]

  module "Toplevel Content Checkbox Behaviors",
    teardown: -> CheckboxHelper.teardown()

  test 'renders a checkbox with name set from model property', ->
    CheckboxHelper.renderView(property: 'copy[all_assignments]')
    nameValue = CheckboxHelper.$checkbox().prop('name')

    equal nameValue, 'copy[all_assignments]', 'Adds the correct name attribute from property'

  test 'toplevel checkbox is checked by default', ->
    CheckboxHelper.renderView()
    ok CheckboxHelper.$checkbox().is(":checked"), "Checkbox is checked"

  test 'sublevel checkbox is unchecked by default', ->
    CheckboxHelper.renderView()
    ok !CheckboxHelper.$sublevelCheckboxes().is(":checked"), "Checkbox is unchecked"

  module "Sublevel Content Checkbox Behaviors",
    setup: ->
      @url = '/api/v1/courses/42/content_migrations/5/selective_data?type=assignments'
      @clock = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()
      @server.respondWith('GET', @url, CheckboxHelper.serverResponse())
      CheckboxHelper.renderView(sub_items_url: @url)
      CheckboxHelper.$checkbox().simulate 'click'
      @server.respond()
      @clock.tick 15
    teardown: ->
      @server.restore()
      @clock.restore()
      CheckboxHelper.teardown()

  test 'renders sublevel checkboxes', ->
    equal CheckboxHelper.checkboxView.$el.find('.collectionViewItems').last().find('[type=checkbox]').length, 3,  "Renders all sublevel checkboxes"

  test 'checkboxes with sublevel checkboxes and no url only display labels', ->
    equal CheckboxHelper.checkboxView.$el.find('ul').first().find('[type=checkbox]').length, 3, "Doesn't include checkbox"

  test 'clicking Select All, checks all sublevel checkboxes', ->
    CheckboxHelper.checkboxView.$el.find("a").first().simulate 'click'

    $subCheckboxes = CheckboxHelper.checkboxView.$el.find('ul').first().find('[type=checkbox]')
    equal $subCheckboxes.length, 3
    $subCheckboxes.each ->
      ok $(this).is(':checked'), "Checked child checkboxes"

  test 'clicking Select None, unchecks all sublevel checkboxes', ->
    $subCheckboxes = CheckboxHelper.checkboxView.$el.find('ul').first().find('[type=checkbox]')
    equal $subCheckboxes.length, 3

    CheckboxHelper.checkboxView.$el.find("a").last().simulate 'click'
    $subCheckboxes.each ->
      ok !$(this).is(':checked'), "Unchecked child checkboxes"

  test 'clicking on a checkbox should unmark and mark linked checkbox', ->
    $subCheckboxes = CheckboxHelper.checkboxView.$el.find('ul').first().find('[type=checkbox]')
    equal $subCheckboxes.length, 3

    $($subCheckboxes[2]).simulate 'click'
    ok !$($subCheckboxes[1]).is(':checked'), "Unchecked linked resource"

    $($subCheckboxes[2]).simulate 'click'
    ok $($subCheckboxes[1]).is(':checked'), "Checked linked resource"
