require [
  'jquery'
  'compiled/fn/preventDefault'
  'jqueryui/accordion'
  'jqueryui/tabs'
  'jqueryui/button'
  'jqueryui/tooltip'
  'jquery.instructure_date_and_time'
], ($, preventDefault) ->

  do ->
    dialog = $('#dialog-buttons-dialog').dialog({
      autoOpen: false
      height: 200
    }).data('dialog')
    $('#show-dialog-buttons-dialog').click -> dialog.open()


  ## OLD STYLEGUIDE ##

  iconEventsMap =
    mouseover: -> $(this).addClass "hover"
    click: -> $(this).addClass "active"
    mouseout: -> $(this).removeClass "hover active"

  $("#content").on iconEventsMap, ".demo-icons"

  # Accordion
  $(".accordion").accordion header: "h3"

  # Tabs
  $("#tabs").tabs()

  # Datepicker
  # $("#datepicker").datepicker().children().show()


  # hover states on the static widgets
  $("ul#icons li").hover ->
    $(this).addClass "ui-state-hover"
  , ->
    $(this).removeClass "ui-state-hover"

  # Button
  $(".styleguide-turnIntoUiButton, .styleguide-turnAllIntoUiButton > *").button()

  # Icon Buttons
  $("#leftIconButton").button icons:
    primary: "ui-icon-wrench"

  $("#bothIconButton").button icons:
    primary: "ui-icon-wrench"
    secondary: "ui-icon-triangle-1-s"

  # Button Set
  $("#radio1").buttonset()

  # Progressbar
  $("#progressbar").progressbar(value: 37).width 500
  $("#animateProgress").click preventDefault ->
    randNum = Math.random() * 90
    $("#progressbar div").animate width: "#{randNum}%"


  # Combinations
  $("#tabs2").tabs()
  $("#accordion2").accordion header: "h4"


  #Toolbar
  $("#play, #shuffle").button()
  $("#repeat").buttonset()

  $(".styleguide-datetime_field-example").datetime_field()


