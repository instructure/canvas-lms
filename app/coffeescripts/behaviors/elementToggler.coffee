# a way to hide show one element/dialog by clicking on another

# see: http://test.cita.illinois.edu/aria/hideshow/hideshow1.php

# examples:

# <a href="#" class="element_toggler" role="button" data-html-while-target-shown="Hide Thing" aria-controls="thing">Show Thing</a>
# <div id="thing" tabindex="-1" role="region" style="display:none">
#     Here is a bunch more info about "thing"
# </div>

# <a href="#" class="element_toggler" role="button" data-hide-while-target-shown=true aria-controls="thing">Show Thing, then hide me</a>
# <div id="thing" tabindex="-1" role="region" style="display:none">blah</div>
#

# a dialog example
#
# <button class="element_toggler" aria-controls="thing">Show Thing Dialog</button>
# <form id="thing" data-turn-into-dialog='{"width":450,"modal":true}' style="display:none">
#   This will pop up as a dialog when you click the button and pass along the data-turn-into-dialog
#   options.  then it will pass it through fixDialogButtons to turn the buttons in your markup
#   into proper dialog buttons (look at fixDialogButtons to see what it does)
#   <div class="button-container">
#     <button type="submit">This will Submit the form</button>
#     <a class="btn dialog_closer">This will cause the dialog to close</a>
#   </div>
# </form>

define [
  'jquery'
  'compiled/jquery/fixDialogButtons'
], ($) ->

  updateTextToState = (newStateOfRegion) ->
    return ->
      $this = $(this)
      return unless newHtml = $this.data("htmlWhileTarget#{newStateOfRegion}")

      # save the old state as the current html unless it has already been set
      oldStateKey = "htmlWhileTarget#{if newStateOfRegion is 'Hidden' then 'Shown' else 'Hidden'}"
      savedHtml = $this.data(oldStateKey)
      $this.data(oldStateKey, $this.html()) unless savedHtml

      # update the element with the new text
      $this.html(newHtml)

  toggleRegion = ($region, showRegion, $trigger) ->
    showRegion ?= ($region.is(':ui-dialog:hidden') || ($region.attr('aria-expanded') != 'true'))
    $allElementsControllingRegion = $("[aria-controls*=#{$region.attr('id')}]")

    # hide/un-hide .element_toggler's that point to this $region that were hidden because they have
    # the data-hide-while-target-shown attribute
    $allElementsControllingRegion.filter(-> $(this).data('hideWhileTargetShown')).toggle !showRegion

    if $trigger and $trigger.attr('aria-expanded') isnt undefined
      $trigger.attr('aria-expanded', !($trigger.attr('aria-expanded') is 'true'))
      $region.toggle($trigger.attr('aria-expanded') is 'true')
    else
      $region.attr('aria-expanded', '' + showRegion).toggle showRegion

    # behavior if $region is a dialog
    if $region.is(':ui-dialog') || dialogOpts = $region.data('turnIntoDialog')

      if dialogOpts && showRegion
        # markup said data-turn-into-dialog, but it's not a dialog yet, make it one
        dialogOpts = $.extend({
          autoOpen: false
          close: -> toggleRegion($region, false)
        }, dialogOpts)
        $region.dialog(dialogOpts).fixDialogButtons()

      if showRegion
        $region.dialog('open')

        if $region.data('read-on-open')
          $region.dialog('widget')
            .attr('aria-live', 'assertive')
            .attr('aria-atomic', 'true')

      else if $region.dialog('isOpen')
        $region.dialog('close')

    $allElementsControllingRegion.each updateTextToState( if showRegion then 'Shown' else 'Hidden' )


  elementTogglerBehavior =
    bind: ->
      $(document).on 'click change keyclick', '.element_toggler[aria-controls]', (event) ->
        $this = $(this)

        if $this.is('input[type="checkbox"]')
          return if event.type is 'click'
          force = $this.prop('checked')

        event.preventDefault() if event.type is 'click'

        # allow .links inside .user_content to be elementTogglers, but only for other elements inside of
        # that .user_content area
        $parent = $this.closest('.user_content')
        $parent = $(document.body) unless $parent.length

        $region = $parent.find("##{$this.attr('aria-controls').replace(/\s/g, ', #')}")
        toggleRegion($region, force, $this) if $region.length

        $icon = $this.find('i[class*="icon-mini-arrow"].auto_rotate')
        if $icon.length
          $icon.toggleClass('icon-mini-arrow-down')
          $icon.toggleClass('icon-mini-arrow-right')


  elementTogglerBehavior.bind()

  return elementTogglerBehavior
