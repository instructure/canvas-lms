define [
  'Backbone'
  'compiled/views/content_migrations/SelectContentView'
  'compiled/models/ProgressingContentMigration'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
], (Backbone, SelectContentView, ProgressingMigration) -> 

  class SelectContentHelper
    @url = '/api/v1/courses/42/content_migrations/5/selective_data'
    @$carrot = -> @$fixtures.find('.checkbox-carrot').first()
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

  module 'SelectContentView: Main Behaviors',
    setup: -> 
      @server = sinon.fakeServer.create()
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

    teardown: -> 
      @server.restore()
      @selectContentView.remove()

  test 'render top level checkboxes when opened', -> 
    $checkboxes = @selectContentView.$el.find('[type=checkbox]')
    equal $checkboxes.length, 3, "Renders all checkboxes"

  test 'changes parents to intermediate when not all of the sublevel checkboxes are check', ->
    @server.respondWith('GET',SelectContentHelper.url+"?type=assignments", SelectContentHelper.sublevelCheckboxResponse())
    @selectContentView.$el.find('.checkbox-carrot[data-type=assignments]').simulate 'click'
    @server.respond()
    $subCheckboxes = @selectContentView.$el.find('.collectionViewItems').last().find('[type=checkbox]')
    @selectContentView.$el.find("[data-state='closed']").show()
    @selectContentView.$el.find($subCheckboxes[2]).simulate 'click'
    indeterminate = @selectContentView.$el.find("input[name='copy[all_assignments]']").first().prop('indeterminate')
    
    ok (indeterminate || indeterminate == 'true'), "Parent changed to intermediate"
    
  test "clicking the carrot shows and hides checkboxes", ->
    $carrot = @selectContentView.$el.find(".checkbox-carrot[data-type=assignments]")
    $sublevelCheckboxes = $carrot.siblings('ul').first()

    equal $carrot.data('state'), 'closed'
    equal $sublevelCheckboxes.is(':visible'), false
    $carrot.simulate 'click'

    equal $carrot.data('state'), 'open'
    equal $sublevelCheckboxes.is(':visible'), true

  test "checking a checkbox checks all children checkboxes", ->
    @server.respondWith('GET',SelectContentHelper.url+"?type=assignments", SelectContentHelper.sublevelCheckboxResponse())
    $assignmentCarrot = @selectContentView.$el.find('.checkbox-carrot[data-type=assignments]')
    $assignmentCarrot.simulate 'click'
    @server.respond()

    clock = sinon.useFakeTimers()

    @selectContentView.$el.find("input[name='copy[all_assignments]']").simulate 'click'

    clock.tick 1

    $assignmentCarrot.siblings('ul').first().find('input[type=checkbox]').each ->
      ok $(this).is(':checked'), 'checkbox is checked'
    clock.restore()

  test 'checking toplevel then expanding should also check all children when they are loaded', ->
    @server.respondWith('GET',SelectContentHelper.url+"?type=assignments", SelectContentHelper.sublevelCheckboxResponse())
    @selectContentView.$el.find("input[name='copy[all_assignments]']").simulate 'click'

    clock = sinon.useFakeTimers()
    $assignmentCarrot = @selectContentView.$el.find('.checkbox-carrot[data-type=assignments]')
    $assignmentCarrot.simulate 'click'
    @server.respond()

    clock.tick 1

    $assignmentCarrot.siblings('ul').first().find('input[type=checkbox]').each ->
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

