/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

// Copied from https://github.com/dollarshaveclub/shave/blob/master/src/shave.js
// with few modifications

export default function shave(target, maxHeight, opts = {}) {
  // eslint-disable-next-line no-restricted-globals
  if (typeof maxHeight === 'undefined' || isNaN(maxHeight)) throw Error('maxHeight is required')
  let els = typeof target === 'string' ? document.querySelectorAll(target) : target
  if (!els) return

  const character = opts.character || '…'
  const classname = opts.classname || 'js-shave'
  const spaces = typeof opts.spaces === 'boolean' ? opts.spaces : true
  // xsslint safeString.identifier character
  const charHtml = `<span class="js-shave-char" aria-hidden="true">${character}</span>`

  let trucated = false

  if (!('length' in els)) els = [els]
  for (let i = 0; i < els.length; i += 1) {
    const el = els[i]
    const styles = el.style
    const span = el.querySelector(`.${classname}`)
    const textProp = el.textContent === undefined ? 'innerText' : 'textContent'

    // If element text has already been shaved
    if (span) {
      // Remove the ellipsis to recapture the original text
      el.removeChild(el.querySelector('.js-shave-char'))
      // eslint-disable-next-line no-self-assign
      el[textProp] = el[textProp]
      // nuke span, recombine text
    }

    const fullText = el[textProp]
    const words = spaces ? fullText.split(' ') : fullText
    // If 0 or 1 words, we're done
    if (words.length < 2) continue

    // Temporarily remove any CSS height for text height calculation
    const heightStyle = styles.height
    styles.height = 'auto'
    const maxHeightStyle = styles.maxHeight
    styles.maxHeight = 'none'

    // If already short enough, we're done
    if (el.offsetHeight <= maxHeight) {
      styles.height = heightStyle
      styles.maxHeight = maxHeightStyle
      continue
    }

    trucated = true

    // Binary search for number of words which can fit in allotted height
    let max = words.length - 1
    let min = 0
    let pivot
    while (min < max) {
      pivot = (min + max + 1) >> 1 // eslint-disable-line no-bitwise
      el[textProp] = spaces ? words.slice(0, pivot).join(' ') : words.slice(0, pivot)
      el.insertAdjacentHTML('beforeend', charHtml)
      if (el.offsetHeight > maxHeight) max = pivot - 1
      else min = pivot
    }

    el[textProp] = spaces ? words.slice(0, max).join(' ') : words.slice(0, max)
    el.insertAdjacentHTML('beforeend', charHtml)
    const diff = spaces ? ` ${words.slice(max).join(' ')}` : words.slice(max)

    const shavedText = document.createTextNode(diff)
    const elWithShavedText = document.createElement('span')
    elWithShavedText.classList.add(classname)
    elWithShavedText.style.display = 'none'
    elWithShavedText.appendChild(shavedText)
    el.insertAdjacentElement('beforeend', elWithShavedText)

    styles.height = heightStyle
    styles.maxHeight = maxHeightStyle
  }

  return trucated
}
