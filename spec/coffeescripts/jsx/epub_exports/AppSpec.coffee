define [
  'underscore',
  'react',
  'jsx/epub_exports/App',
  'jsx/epub_exports/CourseStore'
], (_, React, App, CourseEpubExportStore) ->
  TestUtils = React.addons.TestUtils

  module 'AppSpec',
    setup: ->
      @props = {
        1: {
          name: 'Maths 101',
          id: 1
        },
        2: {
          name: 'Physics 101',
          id: 2
        }
      }
      sinon.stub(CourseEpubExportStore, 'getAll', -> true)

    teardown: ->
      CourseEpubExportStore.getAll.restore()

  test 'handeCourseStoreChange', ->
    component = TestUtils.renderIntoDocument(App())
    ok _.isEmpty(component.state), 'precondition'

    CourseEpubExportStore.setState(@props)
    deepEqual component.state, CourseEpubExportStore.getState(),
      'CourseEpubExportStore.setState should trigger component setState'
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

