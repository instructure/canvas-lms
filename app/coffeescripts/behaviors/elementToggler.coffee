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
#     <a class="button dialog_closer">This will cause the dialog to close</a>
#   </div>
# </form>

define [
  'jquery'
  'compiled/fn/preventDefault'
  'compiled/jquery/fixDialogButtons'
], ($, preventDefault) ->

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

  toggleRegion = ($region, showRegion) ->
    showRegion ?= ($region.is(':ui-dialog:hidden') || ($region.attr('aria-expanded') != 'true'))
    $allElementsControllingRegion = $(".element_toggler[aria-controls=#{$region.attr('id')}]")

    # hide/un-hide .element_toggler's that point to this $region that were hidden because they have
    # the data-hide-while-target-shown attribute
    $allElementsControllingRegion.filter(-> $(this).data('hideWhileTargetShown')).toggle !showRegion

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
      else if $region.dialog('isOpen')
        $region.dialog('close')

    # move focus to the region if tabbable (to make anything tabbable, just give it a tabindex)
    $region.focus() if showRegion && $region.is(':focusable')

    $allElementsControllingRegion.each updateTextToState( if showRegion then 'Shown' else 'Hidden' )

  $(document).delegate '.element_toggler[aria-controls]', 'click', preventDefault ->
    $this = $(this)

    # allow .links inside .user_content to be elementTogglers, but only for other elements inside of
    # that .user_content area
    $parent = $this.closest('.user_content')
    $parent = $(document.body) unless $parent.length

    $region = $parent.find("##{$this.attr('aria-controls')}")
    toggleRegion($region) if $region.length
