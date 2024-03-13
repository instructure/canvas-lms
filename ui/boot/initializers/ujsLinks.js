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

// copied from
// https://github.com/rails/jquery-ujs

import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import authenticityToken from '@canvas/authenticity-token'

// #
// Handles "data-method" on links such as:
// <a data-url="/users/5" data-method="delete" rel="nofollow" data-confirm="Are you sure?">Delete</a>
function handleMethod(link) {
  link.data('handled', true)
  const href = link.data('url') || link.attr('href')
  const method = link.data('method')
  const target = link.attr('target')
  const token = authenticityToken() || 'tokenWasEmpty'
  const form = $(`<form method="post" action="${htmlEscape(href)}"></form>`)
  const metadataInputHtml = `
    <input name="_method" value="${htmlEscape(method)}" type="hidden" />
    <input name="authenticity_token" value="${htmlEscape(token)}" type="hidden" />
  `

  if (target) form.attr('target', target)
  form.hide().append(metadataInputHtml).appendTo('body').submit()
}

// For 'data-confirm' attribute:
//  - Shows the confirmation dialog
function allowAction(element) {
  const message = element.data('confirm')
  if (!message) return true

  // eslint-disable-next-line no-alert
  return window.confirm(message)
}

$(document).on('click', 'a[data-confirm], a[data-method], a[data-remove]', function (_event) {
  const $link = $(this)

  if ($link.data('handled') || !allowAction($link)) return false

  if ($link.data('remove')) {
    handleRemove($link)
    return false
  } else if ($link.data('method')) {
    handleMethod($link)
    return false
  }
})

// #
// for clicking link to remove element from page and send DELETE request to remove it from db
// sample markup:
// <div class="user">
//   Clicking the × will make the .user div go away, if the ajax request fails it will reappear.
//   <a class="close" href="#" data-url="/users/5" data-remove=".user" data-confirm="Are you sure?"> × </a>
// </div>
function handleRemove($link) {
  const selector = $link.data('remove')
  let $startLookingFrom = $link
  const url = $link.data('url')

  // special case for handling links inside of a KyleMenu that were appendedTo the body and are
  // no longer children of where they should be
  const closestKyleMenu = $link.closest(':ui-popup').popup('option', 'trigger').data('KyleMenu')
  if (closestKyleMenu && closestKyleMenu.opts.appendMenuTo) {
    $startLookingFrom = closestKyleMenu.$placeholder
  }

  const $elToRemove = $startLookingFrom.closest(selector)

  // bind the 'beforeremove' and 'remove' events if you want to handle this with your own code
  // if you stop propigation this will not remove it
  $elToRemove.bind({
    beforeremove() {
      $elToRemove.hide()
    },
    remove() {
      $elToRemove.remove()
    },
  })

  $elToRemove.trigger('beforeremove')

  const triggerRemove = () => $elToRemove.trigger('remove')
  const revert = () => $elToRemove.show()

  if (url) {
    $.ajaxJSON(url, 'DELETE', {}, triggerRemove, revert)
  } else {
    triggerRemove()
  }
}
