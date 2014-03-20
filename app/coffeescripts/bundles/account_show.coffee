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
    # Customize autocomplete (if any) to show the term for each matched course.
    autocompleteData = $('#course_name').data('ui-autocomplete')
    autocompleteData && autocompleteData._renderItem = (ul, item) ->
      $(autocompleteItemTemplate(item)).appendTo(ul)
