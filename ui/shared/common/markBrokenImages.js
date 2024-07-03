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

import {useScope as useI18nScope} from '@canvas/i18n'
import ready from '@instructure/ready'

const I18n = useI18nScope('broken_images')

export function attachErrorHandler(imgEl) {
  imgEl.addEventListener('error', e => {
    const img = e.currentTarget
    const broken = () => img.classList.add('broken-image')
    if (img.src) {
      // eslint-disable-next-line promise/catch-or-return
      fetch(img.src).then(res => {
        if (res.status === 403) {
          // if 403 Forbidden, replace the image with a lock image
          img.src = '/images/svg-icons/icon_lock.svg'
          img.alt = I18n.t('Locked image')
          img.width = 100
          img.height = 100
        } else {
          // in all other cases just add the broken-image class
          broken()
        }
      }, broken)
    } else {
      broken()
    }
  })
}

export function getImagesAndAttach() {
  Array.from(document.querySelectorAll('img:not([src=""])')).forEach(attachErrorHandler)
}

// this behavior will set up all broken images on the page with an error handler that
// can apply the broken-image class if there is an error loading the image.
ready(getImagesAndAttach)
