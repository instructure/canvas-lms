require ['compiled/behaviors/autocomplete'], ->
  $(document).ready ->
    # Add an on-select event to the course name autocomplete.
    $('#course_name').on 'autocompleteselect', (e, ui) ->
      path = $(this).data('autocomplete-options')['source'].replace(/\?.+$/, '')
      window.location = "#{path}/#{ui.item.id}"
