define [
  'react'
  'compiled/react_files/components/FriendlyDatetime'
  'i18nObj'
  'helpers/I18nStubber'
], (React, FriendlyDatetime, I18n, I18nStubber) ->

  TestUtils = React.addons.TestUtils

  module 'FriendlyDatetime',
    setup: ->
      I18nStubber.clear()

  test "parses datetime from a string", ->
    fDT = React.createFactory(FriendlyDatetime)
    rendered = TestUtils.renderIntoDocument(fDT(datetime:'1431570574'))
    equal $(rendered.getDOMNode()).find('.visible-desktop').text(), "Jan 17, 1970", "converts to readable format"
    equal $(rendered.getDOMNode()).find('.hidden-desktop').text(), "1/17/1970", "converts to readable format"

    React.unmountComponentAtNode(rendered.getDOMNode().parentNode)

  test "parses datetime from a Date", ->
    timestamp = new Date(1431570574)
    fDT = React.createFactory(FriendlyDatetime)
    rendered = TestUtils.renderIntoDocument(fDT(datetime: timestamp))

    equal $(rendered.getDOMNode()).find('.visible-desktop').text(), "Jan 17, 1970", "converts to readable format"
    equal $(rendered.getDOMNode()).find('.hidden-desktop').text(), "1/17/1970", "converts to readable format"

    React.unmountComponentAtNode(rendered.getDOMNode().parentNode)
