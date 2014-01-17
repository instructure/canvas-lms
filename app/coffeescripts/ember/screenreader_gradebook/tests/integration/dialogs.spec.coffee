define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
  'jquery'
  'vendor/jquery.ba-tinypubsub'
], (startApp, Ember, fixtures, $) ->

  App = null

  fixtures.create()

  openDialog = (trigger) ->
    click(trigger).then ->
      $dialog = find('.ui-dialog:visible', 'body')
      equal($dialog.length, 1, 'the dialog opens')

  openWithTitleAssert = (trigger, expectedTitle) ->
    openDialog(trigger).then ->
      $dialog = find('.ui-dialog:visible', 'body')
      ok(find('.ui-dialog-title:contains("#{expectedTitle}")', $dialog), 'dialog has the expected title')

  openAndCloseDialog = (trigger, expectedTitle) ->
    openWithTitleAssert(trigger, expectedTitle).then -> click(find('.ui-dialog-titlebar-close:visible', 'body')).then ->
      $dialog = find('.ui-dialog:visible', 'body')
      equal($dialog.length, 0, 'the dialog closes')

  sendSuccess = (server, url, response = '') ->
    server.respond 'POST', url, [
      200
      'Content-Type': 'application/json'
      JSON.stringify Ember.copy response, true
    ]

  module 'screenreader_gradebook: dialogs open and close',
    setup: ->
      App = startApp()
    teardown: ->
      Ember.run App, 'destroy'

  test 'upload scores dialog displays properly', ->
    visit('/')
    openAndCloseDialog('#upload', 'Choose a CSV to Upload')

  test 'set group weights dialog displays propery', ->
    visit('/')
    openAndCloseDialog('#ag_weights', 'Manage assignment group weighting')


  module 'screenreader_gradebook: assignment dialogs open and close',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        @selected = @controller.get('assignments').objectAt(0)
        Ember.run =>
          @controller.set('selectedAssignment', @selected)

    teardown: ->
      Ember.run App, 'destroy'

  #relies on some HTML in the DOM already
  #test 'message students dialog displays properly', ->
    #visit('/').then =>
      #openAndCloseDialog('#message_students', "Message students for #{@selected.name}")

  test 'default grade dialog displays properly', ->
    openAndCloseDialog('#set_default_grade', "Default grade for #{@selected.name}")

  test 'curve grades dialog displays properly', ->
    openAndCloseDialog('#curve_grades', "Curve Grades for #{@selected.name}")

  module 'screenreader_gradebook: submission dialogs open and close',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        @assignment = @controller.get('assignments').objectAt(0)
        @student = @controller.get('students').objectAt(0)
        Ember.run =>
          @controller.setProperties
            'selectedAssignment': @assignment
            'selectedStudent': @student
    teardown: ->
      Ember.run App, 'destroy'

  test 'submission details dialog', ->
    openAndCloseDialog('#submission_details', "#{@student.name}")

  module 'screenreader_gradebook: assignment dialogs saving',
    setup: ->
      App = startApp()
      visit('/').then =>
        @controller = App.__container__.lookup('controller:screenreader_gradebook')
        @selAssignment = @controller.get('assignments').objectAt(0)
        @selStudent = @controller.get('students').objectAt(0)
        @server = sinon.fakeServer.create()
        @alert = sinon.stub(window, 'alert')
        Ember.run =>
          @controller.set('submissions', Em.copy fixtures.submissions, true)
          @controller.set('selectedAssignment', @selAssignment)
          @controller.set('selectedStudent', @selStudent)

    teardown: ->
      # cleanup if test failed
      if Ember.$('.ui-dialog:visible').length
        Ember.$('.ui-dialog:visible').remove()
      @alert.restore()
      @server.restore()

      Ember.run App, 'destroy'

  test 'default grade dialog updates the current students grade', ->
    $dialog = null
    server = @server
    visit('/').then =>
      openDialog('#set_default_grade').then =>
        $dialog = find('.ui-dialog:visible', 'body')
        fillIn(find('[name=default_grade]', $dialog), 100).then =>
          click(find('[name=overwrite_existing_grades]', $dialog)).then =>
            click('.button_type_submit', $dialog)
            sendSuccess(@server, "/courses/#{ENV.GRADEBOOK_OPTIONS.context_id}/gradebook/update_submission", fixtures.set_default_grade_response)


    andThen ->
      equal parseInt(find('#student_and_assignment_grade').val(), 10), 100

