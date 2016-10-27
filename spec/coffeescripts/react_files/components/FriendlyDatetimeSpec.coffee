define [
  'react'
  'react-dom'
  'jsx/shared/FriendlyDatetime'
  'i18nObj'
  'helpers/I18nStubber'
], (React, ReactDOM, FriendlyDatetime, I18n, I18nStubber) ->

  TestUtils = React.addons.TestUtils

  module 'FriendlyDatetime',
    setup: ->
      I18nStubber.clear()

  test "parses datetime from a string", ->
    fDT = React.createFactory(FriendlyDatetime)
    rendered = TestUtils.renderIntoDocument(fDT(dateTime: '1970-01-17'))
    equal $(rendered.getDOMNode()).find('.visible-desktop').text(), "Jan 17, 1970", "converts to readable format"
    equal $(rendered.getDOMNode()).find('.hidden-desktop').text(), "1/17/1970", "converts to readable format"
    ReactDOM.unmountComponentAtNode(rendered.getDOMNode().parentNode)

  test "parses datetime from a Date", ->
    fDT = React.createFactory(FriendlyDatetime)
    rendered = TestUtils.renderIntoDocument(fDT(dateTime: new Date(1431570574)))
    equal $(rendered.getDOMNode()).find('.visible-desktop').text(), "Jan 17, 1970", "converts to readable format"
    equal $(rendered.getDOMNode()).find('.hidden-desktop').text(), "1/17/1970", "converts to readable format"
    ReactDOM.unmountComponentAtNode(rendered.getDOMNode().parentNode)
