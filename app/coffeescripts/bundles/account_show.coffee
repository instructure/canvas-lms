require [
  'jquery'
  'jst/courses/autocomplete_item'
  'compiled/behaviors/autocomplete'
], ($, autocompleteItemTemplate) ->
  $(document).ready ->
    $courseSearchField = $('#course_name')
    if $courseSearchField.length
      autocompleteSource = $courseSearchField.data('autocomplete-source')
      $courseSearchField.autocomplete
        minLength: 4
        delay: 150
        source: autocompleteSource
        select: (e, ui) ->
          # When selected, go to the course page.
          path = autocompleteSource.replace(/\?.+$/, '')
          window.location = "#{path}/#{ui.item.id}"
      # Customize autocomplete to show the enrollment term for each matched course.
      $courseSearchField.data('ui-autocomplete')._renderItem = (ul, item) ->
        $(autocompleteItemTemplate(item)).appendTo(ul)
