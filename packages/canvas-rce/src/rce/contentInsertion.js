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

import classnames from 'classnames'
import {
  renderLink,
  renderImage,
  renderLinkedImage,
  renderVideo,
  renderAudio,
  mediaIframeSrcFromFile
} from './contentRendering'
import scroll from '../common/scroll'
import {defaultImageSize} from './plugins/instructure_image/ImageEmbedOptions'
import {cleanUrl} from './contentInsertionUtils'

/** * generic content insertion ** */

// when the editor is hidden, just replace the selected portion of the textarea
// with the content. branching is for cross-browser
function replaceTextareaSelection(editor, content) {
  const element = editor.getElement()
  if ('selectionStart' in element) {
    // mozilla / dom 3.0
    const before = element.value.substr(0, element.selectionStart)
    const after = element.value.substr(element.selectionEnd, element.value.length)
    element.value = before + content + after
  } else if (document.selection) {
    // exploder
    element.focus()
    document.selection.createRange().text = content
  } else {
    // browser not supported
    element.value += content
  }
}

export function insertContent(editor, content) {
  if (editor.isHidden()) {
    // replaces the textarea selection with the new image. no element returned
    // to indicate because it's raw html.
    replaceTextareaSelection(editor, content)
    return null
  } else {
    // inserts content at the cursor. getEnd() of the selection after the
    // insertion should reference the newly created node (or first of the newly
    // created nodes if there were multiple, unfortunately), because the cursor
    // itself stays just before the new content.
    scroll.scrollIntoViewWDelay(editor.iframeElement, {})
    editor.insertContent(content)
    return editor.selection.getEnd()
  }
}

/** * image insertion ** */

function isElemImg(elem) {
  return elem && elem.nodeName.toLowerCase() === 'img'
}

function isElemAnchor(elem) {
  return elem && elem.nodeName.toLowerCase() === 'a'
}

/*
  check if we should preserve the parent anchor tag. the criteria is pretty
  strict based on if we have a single image selected with an anchor tag
  surrounding
*/
function shouldPreserveImgAnchor(editor) {
  const selection = editor.selection
  const selectedRange = selection.getRng()

  return (
    isElemImg(selection.getNode()) &&
    isElemAnchor(selectedRange.startContainer) &&
    selectedRange.startContainer === selectedRange.endContainer
  )
}

export function insertImage(editor, image) {
  let content = ''
  if (shouldPreserveImgAnchor(editor)) {
    content = renderLinkedImage(editor.selection.getRng().startContainer, image)
  } else {
    // render the image, constraining its size on insertion
    content = renderImage({
      ...image,
      style: {maxWidth: `${defaultImageSize}px`, maxHeight: `${defaultImageSize}px`}
    })
  }
  return insertContent(editor, content)
}

/** * link insertion ** */

// checks if there's an existing anchor containing the cursor
function currentLink(editor, link) {
  const cursor =
    link.selectionDetails && link.selectionDetails.node
      ? link.selectionDetails.node
      : editor.selection.getNode() // This doesn't work in IE 11, but will stop brokeness in other browsers
  return editor.dom.getParent(cursor, 'a')
}

// checks if the editor has a current selection (vs. just a cursor position)
function hasSelection(editor) {
  let selection = editor.selection.getContent()
  selection = editor.dom.decode(selection)
  return !!selection && selection != ''
}

export function existingContentToLink(editor, link) {
  return (
    !editor.isHidden() &&
    ((link && (currentLink(editor, link) || !!link.selectedContent)) || hasSelection(editor))
  )
}

function selectionIsImg(editor) {
  const selection = editor.selection.getContent()
  return editor.dom.$(selection).is('img')
}

export function existingContentToLinkIsImg(editor) {
  return !editor.isHidden() && selectionIsImg(editor)
}

function decorateLinkWithEmbed(link) {
  const type = link.embed && link.embed.type
  link.class = classnames(link.class, {
    instructure_file_link: true,
    instructure_scribd_file: type === 'scribd' || link['data-canvas-previewable'],
    instructure_image_thumbnail: type === 'image',
    instructure_video_link: type === 'video',
    instructure_audio_link: type === 'audio',
    auto_open: link.embed && link.embed.autoOpenPreview,
    inline_disabled: link.embed && link.embed.disablePreview
  })

  if (link.embed.type == 'video' || link.embed.type == 'audio') {
    link.id = `media_comment_${link.embed.id || 'maybe'}`
  }
}

export function insertLink(editor, link) {
  const linkAttrs = {...link}
  if (linkAttrs.embed) {
    decorateLinkWithEmbed(linkAttrs)
    delete linkAttrs.embed
  }
  return insertUndecoratedLink(editor, linkAttrs)
}

// link edit/create logic based on tinymce/plugins/link/plugin.js
function insertUndecoratedLink(editor, linkAttrs) {
  const selectedElm = editor.selection.getNode()
  const anchorElm = getAnchorElement(editor, selectedElm)
  const selectedHtml = editor.selection.getContent({format: 'html'})
  if (linkAttrs.target === '_blank') {
    linkAttrs.rel = 'noopener noreferrer'
  }
  linkAttrs.href = cleanUrl(linkAttrs.href || linkAttrs.url)

  editor.focus()
  if (anchorElm) {
    updateLink(editor, anchorElm, linkAttrs.text, linkAttrs)
  } else if (selectedHtml) {
    editor.execCommand('mceInsertLink', null, linkAttrs)
  } else {
    createLink(editor, selectedElm, linkAttrs.text, linkAttrs)
  }
  return editor.selection.getEnd() // this will be the newly created or updated content
}

function getAnchorElement(editor, selectedElm) {
  selectedElm = selectedElm || editor.selection.getNode()
  if (isImageFigure(selectedElm)) {
    return editor.dom.select('a[href]', selectedElm)[0]
  } else {
    return editor.dom.getParent(selectedElm, 'a[href]')
  }
}

function isImageFigure(elm) {
  return elm && elm.nodeName === 'FIGURE' && /\bimage\b/i.test(elm.className)
}
function updateLink(editor, anchorElm, text, linkAttrs) {
  if (anchorElm.hasOwnProperty('innerText')) {
    anchorElm.innerText = text
  } else {
    anchorElm.textContent = text
  }
  editor.dom.setAttribs(anchorElm, linkAttrs)
  editor.selection.select(anchorElm)
}
function createLink(editor, selectedElm, text, linkAttrs) {
  if (isImageFigure(selectedElm)) {
    linkImageFigure(editor, selectedElm, linkAttrs)
  } else {
    insertContent(editor, renderLink(linkAttrs, text))
  }
}
function linkImageFigure(editor, fig, attrs) {
  const img = editor.dom.select('img', fig)[0]
  if (img) {
    const a = editor.dom.create('a', attrs)
    img.parentNode.insertBefore(a, img)
    a.appendChild(img)
  }
}

/* ** video insertion ** */

export function insertVideo(editor, video) {
  let result = insertContent(editor, renderVideo(video))
  // for some reason, editor.selection.getEnd() returned from
  // insertContent is parent paragraph when inserting the
  // video iframe. Look for the iframe with the right
  // src attribute. (Aside: tinymce strips the id or data-*
  // attributes from the iframe, that's why we can't look for those)
  const src = mediaIframeSrcFromFile(video)
  result = result.querySelector(`iframe[src="${src}"]`)
  return result
}

export function insertAudio(editor, audio) {
  let result = insertContent(editor, renderAudio(audio))
  const src = mediaIframeSrcFromFile(audio)
  result = result.querySelector(`iframe[src="${src}"]`)
  return result
}
