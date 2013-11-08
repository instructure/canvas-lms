require [
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'compiled/views/PublishButtonView'
  'compiled/views/PublishIconView'
  'jqueryui/accordion'
  'jqueryui/tabs'
  'jqueryui/button'
  'jqueryui/tooltip'
  'jquery.instructure_date_and_time'
], ($, _, preventDefault, PublishButtonView, PublishIconView) ->

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


  # Publish Button
  # --
  # Hooks into a 'publishable' Backbone model. The backbone model requires
  # the 'published' and 'publishable' attributes to determine initial state,
  # and the  publish() and unpublish() methods that return a deferred objects.
  #
  class Publishable extends Backbone.Model
    defaults:
      "published":   false
      "publishable": true

    publish: ->
      this.set("published", true)
      deferred = $.Deferred()
      setTimeout deferred.resolve, 1000
      deferred

    unpublish: ->
      this.set("published", false)
      deferred = $.Deferred()
      setTimeout deferred.resolve, 1000
      deferred

    disabledMessage: ->
      "Can't unpublish"

  # PublishButtonView doesn't require an element to initialize. It is
  # passed in here for the style-guide demonstration purposes

  # publish
  model   = new Publishable(published: false, publishable: true)
  btnView = new PublishButtonView(model: model, el: "#publish").render()

  # published
  model   = new Publishable(published: true,  publishable: true)
  btnView = new PublishButtonView(model: model, el: "#published").render()

  # published & disables
  model   = new Publishable(published: true,  publishable: false)
  btnView = new PublishButtonView(model: model, el: "#published-disabled").render()

  # publish icon
  _.each $('.publish-icon'), ($el) ->
    model   = new Publishable(published: false,  publishable: true)
    btnView = new PublishIconView(model: model, el: $el).render()


  # Element Toggler
  $('.element_toggler').click (e) ->
    $(e.currentTarget).find('i')
      .toggleClass('icon-mini-arrow-down')
      .toggleClass('icon-mini-arrow-right')


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
