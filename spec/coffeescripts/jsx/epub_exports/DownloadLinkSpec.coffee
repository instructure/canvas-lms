define [
  'underscore',
  'react',
  'jsx/epub_exports/DownloadLink',
  'i18n!epub_exports',
], (_, React, DownloadLink, I18n) ->
  TestUtils = React.addons.TestUtils

  module 'DownloadLink',
    setup: ->
      @props = {
        course: {
          name: 'Maths 101',
          id: 1
        }
      }

  test 'state showDownloadLink', ->
    component = TestUtils.renderIntoDocument(DownloadLink(@props))
    ok !component.showDownloadLink(), 'should be false without epub_export object'

    @props.course.epub_export = {
      permissions: {
        download: false
      }
    }
    component = TestUtils.renderIntoDocument(DownloadLink(@props))
    ok !component.showDownloadLink(), 'should be false without permissions to download'

    @props.course.epub_export = {
      attachment: {
        url: 'http://download.url'
      },
      permissions: {
        download: true
      }
    }
    component = TestUtils.renderIntoDocument(DownloadLink(@props))
    ok component.showDownloadLink(), 'should be true with permissions to download'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'render', ->
    component = TestUtils.renderIntoDocument(DownloadLink(@props))
    node = component.getDOMNode()
    ok _.isNull(node)

    @props.course.epub_export = {
      attachment: {
        url: 'http://download.url'
      },
      permissions: {
        download: true
      }
    }
    component = TestUtils.renderIntoDocument(DownloadLink(@props))
    node = component.getDOMNode()
    equal node.tagName, 'A', 'tag should be link'
    ok node.textContent.match(I18n.t("Download")),
      'should show download text'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)
