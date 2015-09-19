define [
  'react'
  'jquery'
  'jsx/files/NoResults'
], (React, $, NoResults) ->
  TestUtils = React.addons.TestUtils

  module "NoResults",
  test "displays search term in no results text", ->
    noResults = React.createFactory(NoResults)
    search_term = "texas toast"
    rendered = TestUtils.renderIntoDocument(noResults(search_term: search_term))

    equal rendered.refs.yourSearch.props.children, "Your search - \"#{search_term}\" - did not match any files.", "has the right text"

    React.unmountComponentAtNode(rendered.getDOMNode().parentNode)

