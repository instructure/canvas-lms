require [
  "jquery"
], ($) ->
  $(document).ready ->
    $(".select_action").change(->
      $(".sub_setting").hide().filter("." + $(this).val()).show()
    ).change()