/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import formatMessage from '../format-message'
import {closest, getData, setData} from './jqueryish_funcs'

const MEDIA_COMMENT_THUMBNAIL_SIZES = {
  normal: {width: 140, height: 100},
  small: {width: 70, height: 50},
}

function createMediaCommentThumbnail(elem, size, keepOriginalText, kalturaSettings) {
  // a lot of places in canvas rely on INST.kalturaSettings. Fallback if they are not provided
  const kalturaSettings_ = kalturaSettings || window.INST?.kalturaSettings
  // eslint-disable-next-line no-console
  if (!kalturaSettings_) return console.log('Kaltura has not been enabled for this account')
  let idAttr, url
  const $link = elem

  try {
    const a = document.createElement('a')
    a.href = $link.getAttribute('href')
    url = a
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(error)
  }

  if (url) {
    const urlParams = new URLSearchParams(url.search)
    if (urlParams.has('no_preview') && urlParams.get('no_preview') !== 'false') return
  }

  const dimensions = MEDIA_COMMENT_THUMBNAIL_SIZES[size] || MEDIA_COMMENT_THUMBNAIL_SIZES.normal
  const id =
    getData($link, 'media_comment_id') ||
    $link.getAttribute('data-media_comment_id') ||
    $link.querySelector('.media_comment_id')?.textContent ||
    ((idAttr = $link.id) && idAttr.match(/^media_comment_/) && idAttr.substring(14)) ||
    $link.parentElement.querySelector('.media_comment_id')?.textContent?.trim()

  const authorName = getData($link, 'author') || $link.getAttribute('data-author')
  const createdAt = getData($link, 'created_at') || $link.getAttribute('data-created_at')
  let altText

  if (authorName && createdAt) {
    altText = formatMessage('Play media comment by {name} from {createdAt}.', {
      name: authorName,
      createdAt,
    })
  } else {
    altText = formatMessage('Play media comment.')
  }

  if (id) {
    const domain = `https://${kalturaSettings_.resource_domain}`

    const backgroundUrl =
      `${domain}/p/${kalturaSettings_.partner_id}/thumbnail/entry_id/${id}/width/` +
      `${dimensions.width}/height/${dimensions.height}/bgcolor/000000/type/2/vid_sec/5`

    const $thumbnail = document.createElement('span')
    $thumbnail.setAttribute('style', `background-image: url(${backgroundUrl});`)
    $thumbnail.setAttribute('class', `media_comment_thumbnail media_comment_thumbnail-${size}`)

    const span1 = document.createElement('span')
    span1.classList.add('media_comment_thumbnail_play_button')
    const span2 = document.createElement('span')
    span2.classList.add('screenreader-only')
    span2.textContent = altText
    span1.appendChild(span2)
    $thumbnail.appendChild(span1)

    const $p = closest($link, 'p')
    if ($p && !$p.getAttribute('title')) {
      $p.setAttribute('title', altText)
    }

    let $a = $link
    if (keepOriginalText) {
      $a = $link.cloneNode()
      $a.classList.remove('instructure_file_link')
      const $holder = $link.parentElement
      if ($holder.matches('.instructure_file_link_holder')) {
        $holder.appendChild($a)
      } else {
        $link.after($a)
      }
    } else {
      $link.innerHTML = ''
    }

    $a.setAttribute('data-download', $a.getAttribute('href'))
    $a.setAttribute('href', '#')
    $a.classList.add('instructure_inline_media_comment')
    $a.appendChild($thumbnail)
    $a.style.backgroundImage = ''
    $a.style.padding = 0
  }
}

// public API
export default function mediaCommentThumbnail(
  comment_element,
  size = 'normal',
  keepOriginalText,
  kalturaSettings,
  jqueryData = undefined
) {
  // defer each thumbnail generation till the next time through the event loop to not kill browser rendering,
  // has the effect of saying "only work on thumbnailing these while the browser is not doing something else"
  return new Promise(resolve =>
    window.setTimeout(() => {
      if (jqueryData) {
        Object.keys(jqueryData).forEach(k => setData(comment_element, k, jqueryData[k]))
      }
      createMediaCommentThumbnail(comment_element, size, keepOriginalText, kalturaSettings)
      resolve()
    }, 1)
  )
}
