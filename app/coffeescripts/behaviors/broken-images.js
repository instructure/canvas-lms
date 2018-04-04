//
// Copyright (C) 2017 - present Instructure, Inc.
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
import I18n from 'i18n!broken_images'

export function attachErrorHandler(imgElement) {
  $(imgElement).on('error', e => {
    if (e.currentTarget.src) {
      $.get(e.currentTarget.src)
      .fail(response => {
        if (response.status === 403) {
          // Replace the image with a lock image
          $(e.currentTarget).attr({
            src: '/images/svg-icons/icon_lock.svg',
            alt: I18n.t('Locked image'),
            width: 100,
            height: 100
          })
        } else {
          // Add the broken-image class
          $(e.currentTarget).addClass('broken-image')
        }
      })
    } else {
      // Add the broken-image class (if there is no source)
      $(e.currentTarget).addClass('broken-image')
    }
  })
}

export function getImagesAndAttach () {
  $('img[src!=""]')
    .toArray()
    .forEach(attachErrorHandler)
}

// this behavior will set up all broken images on the page with an error handler that
// can apply the broken-image class if there is an error loading the image.
$(document).ready(() => getImagesAndAttach())
