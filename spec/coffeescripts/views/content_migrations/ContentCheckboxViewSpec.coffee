define [
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/views/content_migrations/ContentCheckboxView'
  'compiled/models/content_migrations/ContentCheckbox'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
  ], (CheckboxCollection, CheckboxView, CheckboxModel, $, fakeENV) ->

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
    @$carrot = -> @$fixtures.find('.checkbox-carrot').first()
    @$sublevelCheckboxes = (scope) => 
                            $boxes = @checkboxView.$el
                                         .find('.collectionViewItems')
                                         .last()
                                         .find('[type=checkbox]')
                            $boxes = $boxes.filter(scope) if scope
                            $boxes
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

  QUnit.module "Content Checkbox Behaviors",
    teardown: -> CheckboxHelper.teardown()

  test 'renders a checkbox with name set from model property', ->
    CheckboxHelper.renderView(property: 'copy[all_assignments]')
    nameValue = CheckboxHelper.$checkbox().prop('name')

    equal nameValue, 'copy[all_assignments]', 'Adds the correct name attribute from property'

  QUnit.module "Sublevel Content Checkbox and Carrot Behaviors",
    setup: ->
      fakeENV.setup()
      @url = '/api/v1/courses/42/content_migrations/5/selective_data?type=assignments'
      @clock = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()
      @server.respondWith('GET', @url, CheckboxHelper.serverResponse())

      CheckboxHelper.renderView(sub_items_url: @url)
      CheckboxHelper.checkboxView.$el.trigger 'fetchCheckboxes'

      @server.respond()
      @clock.tick 15

      CheckboxHelper.checkboxView.$el.find("[data-state='closed']").show()

    teardown: ->
      fakeENV.teardown()
      @server.restore()
      @clock.restore()
      CheckboxHelper.teardown()

  test 'renders sublevel checkboxes', ->
    equal CheckboxHelper.$sublevelCheckboxes().length, 3,  "Renders all sublevel checkboxes"

  test 'checkboxes with sublevel checkboxes and no url only display labels', ->
    equal CheckboxHelper.checkboxView.$el.find('label[title=Assignments]').siblings('[type=checkbox]').length, 0, "Doesn't include checkbox"


  # fragile spec
  # test 'clicking on a checkbox should unmark and mark linked checkbox', ->
  #   $subCheckboxes = CheckboxHelper.checkboxView.$el.find('ul').first().find('[type=checkbox]')
  #   equal $subCheckboxes.length, 3

  #   $($subCheckboxes[2]).click()
  #   ok !$($subCheckboxes[1]).is(':checked'), "Unchecked linked resource"

  #   $($subCheckboxes[2]).click()
  #   ok $($subCheckboxes[1]).is(':checked'), "Checked linked resource"
