/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

const noop = () => {}

export function beforeCheck(editor = {}, done = noop) {
  const [, ...ourCustomStylesheets] = Array.from(editor.dom.doc.styleSheets)
  const hcStyles = window.ENV.url_for_high_contrast_tinymce_editor_css
  ourCustomStylesheets.forEach(s => (s.disabled = true))

  // One day when we are on TinyMCE 4.7.2 or above we can replace this stuff with `editor.dom.styleSheetLoader.loadAll`
  let loadedStyleSheetCount = 0
  const handleOnLoad = () => {
    loadedStyleSheetCount++
  }

  const runDoneWhenReady = () => {
    if (loadedStyleSheetCount === hcStyles.length) {
      done()
    } else {
      setTimeout(runDoneWhenReady, 100)
    }
  }

  hcStyles.forEach(url => {
    editor.dom.styleSheetLoader.load(url, handleOnLoad)
  })

  runDoneWhenReady()
}

export function afterCheck(editor = {}, done = noop) {
  Array.from(editor.dom.doc.styleSheets).forEach(sheet => {
    if (window.ENV.url_for_high_contrast_tinymce_editor_css.includes(sheet.href)) {
      sheet.ownerNode.parentElement.removeChild(sheet.ownerNode)
    } else {
      sheet.disabled = false
    }
  })
  done()
}
