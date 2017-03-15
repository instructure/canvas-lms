require [
  'jquery'
  'react'
  'react-dom'
  'jsx/outcomes/OutcomeAlignmentDeleteLink'
], ($, React, ReactDOM, OutcomeAlignmentDeleteLink) ->
  $('li.alignment').each (_, li) ->
    $div = $(li).find('div.links')[0]

    OutcomeLink = React.createElement(OutcomeAlignmentDeleteLink, {
      has_rubric_association: $(li).data('has-rubric-association'),
      url: $(li).data('url')
    })

    ReactDOM.render(OutcomeLink, $div)
