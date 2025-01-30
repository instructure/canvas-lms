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

import $ from 'jquery'
import KyleMenu from 'jquery-kyle-menu'

// this is a behaviour that will automatically set up a set of .admin-links
// when the button is clicked, see _admin_links.scss for markup
$(document).on('mousedown click keydown', '.al-trigger', function (event) {
  const $trigger = $(this)
  if ($trigger.data('kyleMenu')) return

  let opts = $.extend({noButton: true}, $trigger.data('kyleMenuOptions'))
  if ($trigger.data('append-to-body')) opts.appendMenuTo = 'body'
  const shouldPlaceAbove = hasMoreSpaceAbove($trigger)
  opts = $.extend(opts, {
    popupOpts: {
      position: {
        my: shouldPlaceAbove ? 'center bottom' : $trigger.data('popup-my'),
        at: $trigger.data('popup-at'),
        within: $trigger.data('popup-within'),
        offset: shouldPlaceAbove ? '0 -35px' : undefined,
        collision: $trigger.data('popup-collision'),
      },
    },
  })
  new KyleMenu($trigger, opts)
  $trigger.trigger(event)
})

function hasMoreSpaceAbove($element) {
  if (!$element || !$element.length) {
      throw new Error("element is required");
  }

  const rect = $element[0].getBoundingClientRect();

  const spaceAbove = rect.top; // Distance from element to top of the viewport
  const spaceBelow = $(window).height() - rect.bottom; // Distance from element to bottom of the viewport

  return spaceAbove > spaceBelow;
}