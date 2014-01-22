require ["jquery"], ($) ->
  $(document).ready ->
    $("#enrollment_term_id").change ->
      $(this).closest("form").submit()


