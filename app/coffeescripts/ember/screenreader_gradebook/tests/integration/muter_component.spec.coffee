define [
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
  'jquery'
], (startApp, Ember, fixtures, $) ->

  App = null
  ariaMuted = "Click to unmute."
  ariaUnmuted = "Click to mute."
  dialogTitleMuted = "Unmute Assignment"
  dialogTitleUnmuted = "Mute Assignment"

  sendSuccess = (server, url, state) ->
    server.respond 'POST', url, [
      200
      'Content-Type': 'application/json'
      JSON.stringify {assignment: {muted: state}}
    ]

  checkLabel = (stateLabel) ->
    equal find('#assignment_muted_check').attr('aria-label'), stateLabel

  checkChecked = (expectedBool) ->
    equal find('#assignment_muted_check').prop('checked'), expectedBool

  checkDialogClosed = () ->
    dialog = find('.ui-dialog:visible', 'body')
    equal(dialog.length, 0, 'the dialog closes')

  closeDialog = (dialog) ->
    click find('a', dialog)
    checkDialogClosed()

  module 'screenreader_gradebook assignment_muter_component: muted',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @con = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @con.set('selectedAssignment', Ember.copy fixtures.assignment_groups[0].assignments[1], true)
        @server = sinon.fakeServer.create()
    teardown: ->
      @server.restore()
      Ember.run App, 'destroy'

  test 'dialog cancels dialog without changes', ->
    checkLabel(ariaMuted)
    checkChecked(true)
    click('#assignment_muted_check').then =>
      dialog = find('.ui-dialog:visible', 'body')
      click('[data-action="cancel"]', dialog)
      checkDialogClosed()
      checkChecked(true)
      checkLabel(ariaMuted)

  test 'dialog opens and closes without changes', ->
    checkLabel(ariaMuted)
    checkChecked(true)
    click('#assignment_muted_check').then =>
      dialog = find('.ui-dialog:visible', 'body')
      equal find('[data-action="unmute"]', dialog).text(), dialogTitleMuted
      closeDialog(dialog)
      checkChecked(true)
      checkLabel(ariaMuted)

  test 'dialog opens and makes changes upon confirmation', ->
    server = @server
    checkLabel(ariaMuted)
    checkChecked(true)
    click('#assignment_muted_check').then =>
      dialog = find('.ui-dialog:visible', 'body')
      click('[data-action="unmute"]', dialog)
      sendSuccess(server, "#{ENV.GRADEBOOK_OPTIONS.context_url}/assignments/#{@con.get('selectedAssignment.id')}/mute", false)
      andThen =>
        dialog = find('.ui-dialog:visible', 'body')
        equal(dialog.length, 0, 'the dialog is closed')
        checkChecked(false)
        checkLabel(ariaUnmuted)
        equal @con.get('selectedAssignment.muted'), false
        server.restore()

  module 'screenreader_gradebook assignment_muter_component: unmuted',
    setup: ->
      fixtures.create()
      App = startApp()
      visit('/').then =>
        @con = App.__container__.lookup('controller:screenreader_gradebook')
        Ember.run =>
          @con.set('selectedAssignment', Ember.copy fixtures.assignment_groups[0].assignments[0], true)
        @server = sinon.fakeServer.create()
    teardown: ->
      @server.restore()
      Ember.run App, 'destroy'

  test 'dialog cancels dialog without changes', ->
    checkLabel(ariaUnmuted)
    checkChecked(false)
    click('#assignment_muted_check').then =>
      dialog = find('.ui-dialog:visible', 'body')
      click('[data-action="cancel"]', dialog)
      checkDialogClosed()
      checkChecked(false)
      checkLabel(ariaUnmuted)

  test 'dialog opens and closes without changes', ->
    checkLabel(ariaUnmuted)
    checkChecked(false)
    click('#assignment_muted_check').then =>
      dialog = find('.ui-dialog:visible', 'body')
      equal find('[data-action="mute"]', dialog).text(), dialogTitleUnmuted
      closeDialog(dialog)
      checkChecked(false)
      checkLabel(ariaUnmuted)

  test 'dialog opens and makes changes upon confirmation', ->
    server = @server
    checkLabel(ariaUnmuted)
    checkChecked(false)
    click('#assignment_muted_check').then =>
      dialog = find('.ui-dialog:visible', 'body')
      click('[data-action="mute"]', dialog)
      sendSuccess(server, "#{ENV.GRADEBOOK_OPTIONS.context_url}/assignments/#{@con.get('selectedAssignment.id')}/mute", true)
      andThen =>
        dialog = find('.ui-dialog:visible', 'body')
        equal(dialog.length, 0, 'the dialog is closed')
        checkChecked(true)
        checkLabel(ariaMuted)
        equal @con.get('selectedAssignment.muted'), true
        server.restore()
