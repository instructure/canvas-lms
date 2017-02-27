define [
  'jquery',
  'helpers/util',
  'helpers/fakeENV',
  'compiled/views/conversations/MessageFormDialog',
  'compiled/collections/FavoriteCourseCollection',
  'compiled/collections/CourseCollection',
  'compiled/collections/GroupCollection'
], ($, util, fakeENV, MessageFormDialog, FavoriteCourseCollection, CourseCollection, GroupCollection) ->
  recipients = [
    {
      id: '9010000000000001', # rounds to 9010000000000000
      common_courses: [{0: 'FakeEnrollment'}],
      avatar_url: 'http://example.com',
      common_groups: {},
      name: 'first person'
    },
    {
      id: '9010000000000003', # rounds to 9010000000000004
      common_courses: [{0: 'FakeEnrollment'}],
      avatar_url: 'http://example.com',
      common_groups: {},
      name: 'second person'
    }
  ]

  QUnit.module 'MessageFormDialog',
    setup: ->
      @server = sinon.fakeServer.create()
      @clock = sinon.useFakeTimers()
      util.useOldDebounce()

      fakeENV.setup
        CONVERSATIONS:
          CAN_MESSAGE_ACCOUNT_CONTEXT: false

    teardown: ->
      fakeENV.teardown()

      util.useNormalDebounce()
      @clock.restore()
      @server.restore()

  test 'recipient ids are not parsed as numbers', ->
    dialog = new MessageFormDialog
      courses:
        favorites: new FavoriteCourseCollection()
        all: new CourseCollection()
        groups: new GroupCollection()
    dialog.show(null, {})

    dialog.recipientView.$input.val('person')
    dialog.recipientView.$input.trigger('input')
    @clock.tick(250)

    @server.respond 'GET', /recipients/, [
      200
      'Content-Type': 'application/json'
      JSON.stringify(recipients)
    ]

    equal dialog.recipientView.selectedModel.id, '9010000000000001'

    dialog.recipientView.$el.find('.ac-result:eq(1)').trigger($.Event('mousedown', button: 0));
    deepEqual(dialog.recipientView.tokens, ['9010000000000003'])
