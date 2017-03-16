import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import OutcomeAlignmentDeleteLink from 'jsx/outcomes/OutcomeAlignmentDeleteLink'

$('li.alignment').each((_, li) => {
  const $div = $(li).find('div.links')[0]

  ReactDOM.render(
    <OutcomeAlignmentDeleteLink
      has_rubric_association={$(li).data('has-rubric-association')}
      url={$(li).data('url')}
    />,
    $div
  )
})
