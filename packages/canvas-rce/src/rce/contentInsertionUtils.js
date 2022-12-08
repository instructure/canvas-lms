/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

/**
 * functions in this module SHOULD NOT have side effects,
 * but should be focused around providing necessary data
 * or dom transformations with no state in this file.
 */

/**
 * transforms an input url to make a link out of
 * into a correctly formed url.  If it's clearly a mailing link,
 * adds mailto: to the front, and if it has no protocol but isn't an
 * absolute path, it prepends "http://".
 *
 * @param {string} input the raw url representative input by a user
 *
 * @returns {string} a well formed url
 */
export function cleanUrl(input) {
  let url = input
  if (input) {
    if (input.match(/@/) && !input.match(/\//) && !input.match(/^mailto:/)) {
      url = 'mailto:' + input
    } else if (
      !input.match(/^\w+:\/\//) &&
      !input.match(/^(?:mailto|skype|tel):/) &&
      !input.match(/^\//)
    ) {
      url = 'http://' + input
    }

    if (url.indexOf('@') != -1 && url.indexOf('mailto:') != 0 && !url.match(/^http/)) {
      url = 'mailto:' + url
    }
  }
  return url
}

// given the current selection, find the containing anchor
export function getAnchorElement(editor, selectedElm) {
  selectedElm = selectedElm || editor.selection.getNode()
  if (isImageFigure(selectedElm)) {
    return editor.dom.select('a[href]', selectedElm)[0]
  } else {
    return editor.dom.getParent(selectedElm, 'a[href]')
  }
}

// is the selection only text, or are other elements selected
const d = document.createElement('div')
export function isOnlyTextSelected(html) {
  // this regex-based code is lifted from tinymce's link plugin, but I didn't like it.
  // if (/</.test(html) && (!/^<a [^>]+>[^<]+<\/a>$/.test(html) || html.indexOf('href=') === -1)) {
  //   return false
  // }
  // return true
  d.innerHTML = html
  return !d.querySelector('img,iframe,video,audio')
}

export function isOKToLink(html) {
  // I know, parsing html with regexp is dangerous, but this is called way too often
  // from the instructure_link/plugin.ts to create the nodes for a better check
  if (/(?:<(iframe|audio|video)|data-placeholder-for)/.test(html)) {
    return false
  }
  return true
}

export function isImageFigure(elm) {
  return (
    elm && elm.nodeName === 'FIGURE' && /\bimage\b/i.test(elm.className)
    // (elm.nodeName === 'IMG' || (elm.nodeName === 'FIGURE' && /\bimage\b/i.test(elm.className)))
  )
}
