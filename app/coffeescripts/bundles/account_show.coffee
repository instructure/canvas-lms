require [
  'jquery'
  'jst/courses/autocomplete_item'
  'compiled/behaviors/autocomplete'
], ($, autocompleteItemTemplate) ->
  $(document).ready ->
    # Add an on-select event to the course name autocomplete.
    $('#course_name').on 'autocompleteselect', (e, ui) ->
      path = $(this).data('autocomplete-options')['source'].replace(/\?.+$/, '')
      window.location = "#{path}/#{ui.item.id}"
    # Customize autocomplete to show the term for each matched course.
    $('#course_name').data('ui-autocomplete')._renderItem = (ul, item) ->
      $(autocompleteItemTemplate(item)).appendTo(ul)
