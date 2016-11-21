define [
  'jquery'
  'jsx/discussion_topics/DiscussionTopicKeyboardShortcutModal'
  'react'
  'react-dom'
  'react-addons-test-utils'
], ($, DiscussionTopicKeyboardShortcutModal, React, ReactDOM, TestUtils) ->

  SHORTCUTS = [
    { keycode: 'j', description: I18n.t('Next Message') },
    { keycode: 'k', description: I18n.t('Previous Message') },
    { keycode: 'e', description: I18n.t('Edit Current Message') },
    { keycode: 'd', description: I18n.t('Delete Current Message') },
    { keycode: 'r', description: I18n.t('Reply to Current Message') },
    { keycode: 'n', description: I18n.t('Reply to Topic') }
  ]

  module 'DiscussionTopicKeyboardShortcutModal#render',
    setup: ->
      $('#fixtures').append('<div id="application" />')

    teardown: ->
      ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)
      $('#fixtures').empty()

  test 'renders shortcuts', ->
    DiscussionTopicKeyboardShortcutModalElement = React.createElement(DiscussionTopicKeyboardShortcutModal, { isOpen: true })
    @component = TestUtils.renderIntoDocument(DiscussionTopicKeyboardShortcutModalElement)
    list = $('.ReactModalPortal').find('.navigation_list li')
    equal SHORTCUTS.length, list.length
    ok SHORTCUTS.every (sc) ->
      list.toArray().some (li) ->
        keycode = $(li).find('.keycode').text()
        description = $(li).find('.description').text()
        sc.keycode is keycode and sc.description is description
