define [
  'jquery'
  'Backbone'
  'compiled/views/content_migrations/SelectContentView'
  'compiled/models/ProgressingContentMigration'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], ($, Backbone, SelectContentView, ProgressingMigration, fakeENV) -> 

  class SelectContentHelper
    @url = '/api/v1/courses/42/content_migrations/5/selective_data'
    @$caret = -> @$fixtures.find('.checkbox-caret').first()
    @toplevelCheckboxResponse = -> [200, { "Content-Type": "application/json" }, JSON.stringify([

                                              {
                                                  "type": "course_settings",
                                                  "property": "copy[all_course_settings]",
                                                  "title": "Course Settings"
                                              },
                                              {
                                                  "type": "syllabus_body",
                                                  "property": "copy[all_syllabus_body]",
                                                  "title": "Syllabus Body"
                                              },
                                              {
                                                "count": 2,
                                                "property": "copy[all_assignments]",
                                                "sub_items_url": @url + "?type=assignments",
                                                "title": "Assignments",
                                                "type": "assignments",
                                              }
                                          ])]
    @sublevelCheckboxResponse = -> [200, { "Content-Type": "application/json" }, JSON.stringify([
                                              {
                                                  "type": "assignment_groups",
                                                  "property": "copy[assignment_groups][id_i6314c45816f1cc6d9519d88e4b7f64ab]",
                                                  "title": "Assignment group",
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

  module 'SelectContentView: Integration Tests',
    setup: -> 
      @server = sinon.fakeServer.create()
      fakeENV.setup()
      @$fixtures = $('#fixtures')
      @model = new ProgressingMigration
                  id: 5
                  course_id: 42

      @selectContentView = new SelectContentView 
                              model: @model
                              title: 'Select Content'
                              width: 600
                              height: 400
                              fixDialogButtons: false

      @$fixtures.append @selectContentView.$el

      @server.respondWith('GET',SelectContentHelper.url, SelectContentHelper.toplevelCheckboxResponse())
      @selectContentView.open()
      @server.respond()
      @tree = @selectContentView.$el.find('ul[role=tree]')

    teardown: -> 
      fakeENV.teardown()
      @server.restore()
      @selectContentView.remove()

  test 'render top level checkboxes when opened', -> 
    $checkboxes = @selectContentView.$el.find('[type=checkbox]')
    equal $checkboxes.length, 3, "Renders all checkboxes"

  test 'changes parents to intermediate when not all of the sublevel checkboxes are check', ->
    @server.respondWith('GET',SelectContentHelper.url+"?type=assignments", SelectContentHelper.sublevelCheckboxResponse())
    @selectContentView.$el.find('[data-type=assignments] .checkbox-caret').simulate 'click'
    @server.respond()
    $subCheckboxes = @selectContentView.$el.find('.collectionViewItems').last().find('[type=checkbox]')
    @selectContentView.$el.find("[data-state='closed']").show()
    @selectContentView.$el.find($subCheckboxes[2]).simulate 'click'
    indeterminate = @selectContentView.$el.find("input[name='copy[all_assignments]']").first().prop('indeterminate')
    
    ok (indeterminate || indeterminate == 'true'), "Parent changed to intermediate"
    
  test "clicking the caret shows and hides checkboxes", ->
    $caret = @selectContentView.$el.find("[data-type=assignments] .checkbox-caret").first()
    $sublevelCheckboxes = $caret.closest('div').siblings('ul').first()

    equal $caret.parents('[role=treeitem]').attr('aria-expanded'), 'false'
    $caret.simulate 'click'

    equal $caret.parents('[role=treeitem]').attr('aria-expanded'), 'true'

  test "checking a checkbox checks all children checkboxes", ->
    @server.respondWith('GET',SelectContentHelper.url+"?type=assignments", SelectContentHelper.sublevelCheckboxResponse())
    $assignmentCarrot = @selectContentView.$el.find('[data-type=assignments] .checkbox-caret')
    $assignmentCarrot.simulate 'click'
    @server.respond()

    clock = sinon.useFakeTimers()

    @selectContentView.$el.find("input[name='copy[all_assignments]']").simulate 'click'

    clock.tick 1

    @selectContentView.$el.find('[data-type=assignments] input[type=checkbox]').each ->
      ok $(this).is(':checked'), 'checkbox is checked'
    clock.restore()

  test 'checking toplevel then expanding should also check all children when they are loaded', ->
    @server.respondWith('GET',SelectContentHelper.url+"?type=assignments", SelectContentHelper.sublevelCheckboxResponse())
    @selectContentView.$el.find("input[name='copy[all_assignments]']").simulate 'click'

    clock = sinon.useFakeTimers()
    $assignmentCarrot = @selectContentView.$el.find('[data-type=assignments] .checkbox-caret')
    $assignmentCarrot.simulate 'click'
    @server.respond()

    clock.tick 1
    @selectContentView.$el.find('[data-type=assignments] input[type=checkbox]').each -> 
      ok $(this).is(':checked'), 'checkbox is checked'

    clock.restore()

  test "pressing the cancel button closes the dialog view", -> 
    @selectContentView.$el.find('#cancelSelect').simulate 'click'
    ok !@selectContentView.dialog.isOpen(), "Dialog is closed"

  test "select content button is disabled unless content is selected", -> 
    ok @selectContentView.$el.find('#selectContentBtn').prop('disabled'), 'Disabled by default'
    @selectContentView.$el.find('input[type=checkbox]').first().simulate('click')
    ok !@selectContentView.$el.find('#selectContentBtn').prop('disabled'), 'Enabled after checking item'
    @selectContentView.$el.find('input[type=checkbox]').first().simulate('click')
    ok @selectContentView.$el.find('#selectContentBtn').prop('disabled'), 're-disabled if no selected'

  test "pressing the up/down arrow selects the next treeitem", ->
    downEvent = jQuery.Event( "keyup", { which: 40 } )
    upEvent = jQuery.Event( "keyup", { which: 38 } )

    $treeitems = @selectContentView.$el.find('[role=treeitem]:visible')
    @tree = @selectContentView.$el.find('ul[role=tree]')

    @tree.trigger(downEvent)
    @tree.trigger(downEvent)
    $currentlySelected = @selectContentView.$el.find('[aria-selected=true]')
    equal $treeitems.index($currentlySelected), 1, "pressing down moves to the second item"

    @tree.trigger(upEvent)
    $currentlySelected = @selectContentView.$el.find('[aria-selected=true]')
    equal $treeitems.index($currentlySelected), 0, "pressing up moves to the first item"

  test "pressing home/end buttons move you to the first and last treeitem", ->
    homeEvent = jQuery.Event( "keyup", { which: 36 } )
    endEvent = jQuery.Event( "keyup", { which: 35 } )
    $treeitems = @selectContentView.$el.find('[role=treeitem]:visible')

    @tree.trigger endEvent
    $currentlySelected = @selectContentView.$el.find('[aria-selected=true]')
    equal $treeitems.index($currentlySelected), $treeitems.length - 1, "pressing the end button moves to last item"

    @tree.trigger homeEvent
    $currentlySelected = @selectContentView.$el.find('[aria-selected=true]')
    equal $treeitems.index($currentlySelected), 0, "pressing the home button moves to the first item"

  test "pressing right arrow expands", ->
    rightEvent = jQuery.Event( "keyup", { which: 39 } )
    downEvent = jQuery.Event( "keyup", { which: 40 } )

    @tree.trigger downEvent
    @tree.trigger downEvent
    @tree.trigger downEvent
    @tree.trigger rightEvent

    $currentlySelected = @selectContentView.$el.find('[aria-selected=true]')
    equal $currentlySelected.attr('aria-expanded'), "true", "expands the tree item when right is pressed"

  test "aria levels are correctly represented", ->
    @server.respondWith('GET',SelectContentHelper.url+"?type=assignments", SelectContentHelper.sublevelCheckboxResponse())
    @selectContentView.$el.find("input[name='copy[all_assignments]']").simulate 'click'

    clock = sinon.useFakeTimers()
    $assignmentCarrot = @selectContentView.$el.find('[data-type=assignments] .checkbox-caret')
    $assignmentCarrot.simulate 'click'
    @server.respond()

    clock.tick 1

    equal @selectContentView.$el.find("[name='copy[all_assignments]']").parents('[role=treeitem]').attr('aria-level'), "1", 'top level aria level is 1'
    equal @selectContentView.$el.find("[name='copy[assignment_groups][id_i6314c45816f1cc6d9519d88e4b7f64ab]']").parents('[role=treeitem]').attr('aria-level'), "2", 'second level has a level of 2'

    clock.restore()

  test "active decendant is set propertly when clicking on treeitems", ->
    $tree = @selectContentView.$el.find('[role=tree]')
    $treeitem = @selectContentView.$el.find('[role=treeitem]:first')
    $treeitemHeading = @selectContentView.$el.find('[role=treeitem]:first .treeitem-heading')

    $treeitemHeading.click()

    equal $tree.attr('aria-activedescendant'), $treeitem.attr('id')
