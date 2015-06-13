require [
  'jquery',
  'react',
  'jsx/outcomes/OutcomeAlignmentDeleteLink',
], ($, React, OutcomeAlignmentDeleteLink) ->
  $('li.alignment').each (_, li) ->
    $div = $(li).find('div.links')[0];

    React.renderComponent(OutcomeAlignmentDeleteLink({
      has_rubric_association: $(li).data('has-rubric-association'),
      url: $(li).data('url')
    }), $div)
