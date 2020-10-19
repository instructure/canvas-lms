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
import {renderImage, renderLinkedImage, renderVideo, renderAudio} from './contentRendering'
import scroll from '../common/scroll'
import {
  cleanUrl,
  getAnchorElement,
  isOnlyTextSelected,
  isImageFigure
} from './contentInsertionUtils'
import {mediaPlayerURLFromFile} from './plugins/shared/fileTypeUtils'

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
      ...image
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
function insertUndecoratedLink(editor, linkProps) {
  const selectedElm = editor.selection.getNode()
  const anchorElm = getAnchorElement(editor, selectedElm)
  const selectedContent = editor.selection.getContent()
  const selectedPlainText = editor.selection.getContent({format: 'text'})
  const onlyText = isOnlyTextSelected(selectedContent)

  const linkText = onlyText && (linkProps.text || getAnchorText(editor.selection, anchorElm))

  // only keep the props we want as attributes on the <a>
  const linkAttrs = {
    id: linkProps.id,
    href: cleanUrl(linkProps.href || linkProps.url),
    target: linkProps.target,
    class: linkProps.class,
    title: linkProps.title,
    'data-canvas-previewable': linkProps['data-canvas-previewable']
  }

  if (linkAttrs.target === '_blank') {
    linkAttrs.rel = 'noopener noreferrer'
  }

  editor.focus()
  if (anchorElm && !editor.selection.isCollapsed()) {
    updateLink(editor, anchorElm, linkText, linkAttrs)
  } else if (selectedContent) {
    if (linkProps.userText && selectedPlainText !== linkText) {
      createLink(editor, selectedElm, linkText, linkAttrs)
    } else {
      createLink(editor, selectedElm, undefined, linkAttrs)
    }
  } else {
    createLink(editor, selectedElm, linkText, linkAttrs)
  }
  return editor.selection.getEnd() // this will be the newly created or updated content
}

function getAnchorText(selection, anchorElm) {
  return anchorElm ? anchorElm.innerText : selection.getContent({format: 'text'})
}

function updateLink(editor, anchorElm, text, linkAttrs) {
  if (text && anchorElm.innerText !== text) {
    anchorElm.innerText = text
  }
  editor.dom.setAttribs(anchorElm, linkAttrs)
  editor.selection.select(anchorElm)
  editor.undoManager.add()
}

function createLink(editor, selectedElm, text, linkAttrs) {
  if (isImageFigure(selectedElm)) {
    linkImageFigure(editor, selectedElm, linkAttrs)
  } else if (text) {
    // create the whole wazoo
    editor.insertContent(editor.dom.createHTML('a', linkAttrs, editor.dom.encode(text)))
  } else {
    // create a link on the selected content
    editor.execCommand('mceInsertLink', false, linkAttrs)
  }
}

function linkImageFigure(editor, fig, attrs) {
  const img = fig.tagName === 'IMG' ? fig : editor.dom.select('img', fig)[0]
  if (img) {
    const a = editor.dom.create('a', attrs)
    img.parentNode.insertBefore(a, img)
    a.appendChild(img)
  }
}

/* ** video insertion ** */

export function insertVideo(editor, video) {
  if (editor.selection.isCollapsed()) {
    let result = insertContent(editor, renderVideo(video))
    // for some reason, editor.selection.getEnd() returned from
    // insertContent is parent paragraph when inserting the
    // video iframe. Look for the iframe with the right
    // src attribute. (Aside: tinymce strips the id or data-*
    // attributes from the iframe, that's why we can't look for those)
    const src = mediaPlayerURLFromFile(video)
    result = result.querySelector(`iframe[src="${src}"]`)

    // When the iframe is inserted, it doesn't allow the video to play
    // because the wrapping span captures the click events. Setting
    // contentEditable to false disables this behavior.
    if (result?.parentElement) {
      editor.dom.setAttrib(result.parentElement, 'contenteditable', false)
    }

    return result
  } else {
    return insertLink(editor, {...video, href: mediaPlayerURLFromFile(video)})
  }
}

export function insertAudio(editor, audio) {
  if (editor.selection.isCollapsed()) {
    let result = insertContent(editor, renderAudio(audio))
    const src = mediaPlayerURLFromFile(audio)
    result = result.querySelector(`iframe[src="${src}"]`)

    // When the iframe is inserted, it doesn't allow the audio to play
    // because the wrapping span captures the click events. Setting
    // contentEditable to false disables this behavior.
    if (result?.parentElement) {
      editor.dom.setAttrib(result.parentElement, 'contenteditable', false)
    }

    return result
  } else {
    return insertLink(editor, {...audio, href: mediaPlayerURLFromFile(audio)})
  }
}
