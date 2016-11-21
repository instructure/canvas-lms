define [
  'jquery',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/epub_exports/GenerateLink',
  'jsx/epub_exports/CourseStore',
  'i18n!epub_exports',
], ($, React, ReactDOM, TestUtils, GenerateLink, CourseEpubExportStore, I18n) ->

  module 'GenerateLink',
    setup: ->
      @props = {
        course: {
          name: 'Maths 101',
          id: 1
        }
      }

  test 'showGenerateLink', ->
    GenerateLinkElement = React.createElement(GenerateLink, @props)
    component = TestUtils.renderIntoDocument(GenerateLinkElement)
    ok component.showGenerateLink(), 'should be true without epub_export object'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

    @props.course.epub_export = {
      permissions: {
        regenerate: false
      }
    }
    GenerateLinkElement = React.createElement(GenerateLink, @props)
    component = TestUtils.renderIntoDocument(GenerateLinkElement)
    ok !component.showGenerateLink(), 'should be false without permissions to rengenerate'

    @props.course.epub_export = {
      permissions: {
        regenerate: true
      }
    }
    GenerateLinkElement = React.createElement(GenerateLink, @props)
    component = TestUtils.renderIntoDocument(GenerateLinkElement)
    ok component.showGenerateLink(), 'should be true with permissions to rengenerate'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'state triggered', ->
    clock = sinon.useFakeTimers()
    sinon.stub(CourseEpubExportStore, 'create')
    GenerateLinkElement = React.createElement(GenerateLink, @props)
    component = TestUtils.renderIntoDocument(GenerateLinkElement)
    node = component.getDOMNode()

    TestUtils.Simulate.click(node)
    ok component.state.triggered, 'should set state to triggered'

    clock.tick(1005)
    ok !component.state.triggered, 'should toggle back to not triggered after 1000'

    clock.restore()
    CourseEpubExportStore.create.restore()
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'render', ->
    clock = sinon.useFakeTimers()
    sinon.stub(CourseEpubExportStore, 'create')

    GenerateLinkElement = React.createElement(GenerateLink, @props)
    component = TestUtils.renderIntoDocument(GenerateLinkElement)
    node = component.getDOMNode()
    equal node.tagName, 'BUTTON', 'tag should be a button'
    ok node.querySelector('span').textContent.match(I18n.t("Generate ePub")),
      'should show generate text'

    TestUtils.Simulate.click(node)
    node = component.getDOMNode()
    equal node.tagName, 'SPAN', 'tag should be span'
    ok node.textContent.match(I18n.t("Generating...")),
      'should show generating text'

    @props.course.epub_export = {
      permissions: {
        regenerate: true
      }
    }
    component.setProps(@props)
    clock.tick(2000)
    node = component.getDOMNode()
    equal node.tagName, 'BUTTON', 'tag should be a button'
    ok node.querySelector('span').textContent.match(I18n.t("Regenerate ePub")),
      'should show regenerate text'

    clock.restore()
    CourseEpubExportStore.create.restore()
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
