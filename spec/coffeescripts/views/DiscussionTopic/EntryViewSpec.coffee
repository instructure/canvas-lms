define [
  'jquery'
  'compiled/models/Entry'
  'compiled/views/DiscussionTopic/EntryView'
  'compiled/discussions/Reply'
  'helpers/fakeENV'
], ($, Entry, EntryView, Reply, fakeENV) ->

  module 'EntryView',
    setup: ->
      fakeENV.setup
        DISCUSSION:
          PERMISSIONS: { CAN_REPLY: true }
          CURRENT_USER: {}
          THREADED: true

    teardown: ->
      fakeENV.teardown()
      $('#fixtures').empty()

  test 'renders', ->
    entry = new Entry(id: 1, message: 'hi')
    $('#fixtures').append($('<div />').attr('id', 'e1'))
    view = new EntryView
      model: entry
      el: '#e1'
    view.render()
    ok view

  test 'two entries do not render keyboard shortcuts to the same place', ->
    clock = sinon.useFakeTimers()
    sinon.stub(Reply.prototype, 'edit')
    $('#fixtures').append($('<div />').attr('id', 'e1'))
    $('#fixtures').append($('<div />').attr('id', 'e2'))

    entry1 = new Entry(id: 1, message: 'hi')
    entry2 = new Entry(id: 2, message: 'reply')
    view1 = new EntryView
      model: entry1
      el: '#e1'
    view1.render()
    view1.addReply()
    view2 = new EntryView
      model: entry2
      el: '#e2'
    view2.render()
    view2.addReply()

    clock.tick 1

    equal view1.$('.tinymce-keyboard-shortcuts-toggle').length, 1
    equal view2.$('.tinymce-keyboard-shortcuts-toggle').length, 1

    clock.restore()
