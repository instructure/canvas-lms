//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// a way to hide show one element/dialog by clicking on another

// see: http://test.cita.illinois.edu/aria/hideshow/hideshow1.php

// examples:

// <a href="#" class="element_toggler" role="button" data-html-while-target-shown="Hide Thing" aria-controls="thing">Show Thing</a>
// <div id="thing" tabindex="-1" role="region" style="display:none">
//     Here is a bunch more info about "thing"
// </div>

// <a href="#" class="element_toggler" role="button" data-hide-while-target-shown=true aria-controls="thing">Show Thing, then hide me</a>
// <div id="thing" tabindex="-1" role="region" style="display:none">blah</div>
//

// a dialog example
//
// <button class="element_toggler" aria-controls="thing">Show Thing Dialog</button>
// <form id="thing" data-turn-into-dialog='{"width":450,"modal":true}' style="display:none">
//   This will pop up as a dialog when you click the button and pass along the data-turn-into-dialog
//   options.  then it will pass it through fixDialogButtons to turn the buttons in your markup
//   into proper dialog buttons (look at fixDialogButtons to see what it does)
//   <div class="button-container">
//     <button type="submit">This will Submit the form</button>
//     <a class="btn dialog_closer">This will cause the dialog to close</a>
//   </div>
// </form>

import $ from 'jquery'
import '../jquery/fixDialogButtons'

function updateTextToState (newStateOfRegion) {
  return function () {
    let newText
    const $this = $(this)
    if (!(newText = $this.data(`textWhileTarget${newStateOfRegion}`))) return

    // save the old state as the current html unless it has already been set
    const oldStateKey = `textWhileTarget${newStateOfRegion === 'Hidden' ? 'Shown' : 'Hidden'}`
    const savedText = $this.data(oldStateKey)
    if (!savedText) $this.data(oldStateKey, $this.text())

    // update the element with the new text
    $this.text(newText)
  }
}

function toggleRegion ($region, showRegion, $trigger) {
  let dialogOpts
  if (showRegion == null) {
    showRegion = $region.is(':ui-dialog:hidden') || $region.attr('aria-expanded') !== 'true'
  }
  const $allElementsControllingRegion = $(`[aria-controls*=${$region.attr('id')}]`)

  // hide/un-hide .element_toggler's that point to this $region that were hidden because they have
  // the data-hide-while-target-shown attribute
  $allElementsControllingRegion
    .filter(function () {
      return $(this).data('hideWhileTargetShown')
    })
    .toggle(!showRegion)

  if ($trigger && $trigger.attr('aria-expanded') !== undefined) {
    $trigger.attr('aria-expanded', !($trigger.attr('aria-expanded') === 'true'))
    $region.toggle($trigger.attr('aria-expanded') === 'true')
  } else {
    $region.attr('aria-expanded', `${showRegion}`).toggle(showRegion)
  }

  // behavior if $region is a dialog
  if ($region.is(':ui-dialog') || (dialogOpts = $region.data('turnIntoDialog'))) {
    if (dialogOpts && showRegion) {
      // markup said data-turn-into-dialog, but it's not a dialog yet, make it one
      dialogOpts = $.extend({
        autoOpen: false,
        close () {
          toggleRegion($region, false)
        }
      }, dialogOpts)
      $region.dialog(dialogOpts).fixDialogButtons()
    }

    if (showRegion) {
      $region.dialog('open')

      if ($region.data('read-on-open')) {
        $region.dialog('widget').attr('aria-live', 'assertive').attr('aria-atomic', 'true')
      }
    } else if ($region.dialog('isOpen')) {
      $region.dialog('close')
    }
  }

  $allElementsControllingRegion.each(updateTextToState(showRegion ? 'Shown' : 'Hidden'))
}

const elementTogglerBehavior = {
  bind () {
    $(document).on('click change keyclick', '.element_toggler[aria-controls]', function (event) {
      let force
      const $this = $(this)

      if ($this.is('input[type="checkbox"]')) {
        if (event.type === 'click') return
        force = $this.prop('checked')
      }

      if (event.type === 'click') event.preventDefault()

      // allow .links inside .user_content to be elementTogglers, but only for other elements inside of
      // that .user_content area
      let $parent = $this.closest('.user_content')
      if (!$parent.length) $parent = $(document.body)

      const $region = $parent.find(`#${$this.attr('aria-controls').replace(/\s/g, ', #')}`)
      if ($region.length) toggleRegion($region, force, $this)

      const $icon = $this.find('i[class*="icon-mini-arrow"].auto_rotate')
      if ($icon.length) {
        $icon.toggleClass('icon-mini-arrow-down')
        $icon.toggleClass('icon-mini-arrow-right')
      }
    })
  }
}

elementTogglerBehavior.bind()

export default elementTogglerBehavior
