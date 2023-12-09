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
  renderAudio,
  renderImage,
  renderLink,
  renderLinkedImage,
  renderVideo,
} from './contentRendering'
import {
  cleanUrl,
  getAnchorElement,
  isImageFigure,
  isOnlyTextSelected,
} from './contentInsertionUtils'
import {mediaPlayerURLFromFile} from './plugins/shared/fileTypeUtils'
import {absoluteToRelativeUrl} from '../common/fileUrl'

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
    setTimeout(() => {
      if (editor.iframeElement) {
        editor.iframeElement.scrollIntoView()
      }
    }, 100)
    // there's a bug in tinymce where insertContent calls execCommand('mceInsertContent'),
    // but doesn't correctly forward the second "args" argument. Let's go right for
    // execCommand
    // editor.insertContent(content, {skip_focus: true})
    editor.execCommand('mceInsertContent', false, content, {skip_focus: true})
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

export function insertImage(editor, image, canvasOrigin) {
  let content = ''
  if (shouldPreserveImgAnchor(editor)) {
    content = renderLinkedImage(editor.selection.getRng().startContainer, image, canvasOrigin)
  } else {
    // render the image, constraining its size on insertion
    const imgNode = editor.selection.getNode()
    // apply selected styles only in course/user images
    if (isElemImg(imgNode) && !image['data-inst-icon-maker-icon']) {
      const customStyles = imgNode.style
      const customWidth = imgNode.getAttribute('width')
      const parseStyles = {}
      for (let i = 0; i < customStyles.length; ++i) {
        const cssAttribute = customStyles.item(i)
        parseStyles[cssAttribute] = customStyles[cssAttribute]
      }
      image.width = customWidth
      image.style = parseStyles
    }
    content = renderImage(
      {
        ...image,
      },
      canvasOrigin
    )
  }
  return insertContent(editor, content)
}

export function insertEquation(editor, latex) {
  const docSz =
    parseFloat(
      editor.dom.doc.defaultView.getComputedStyle(editor.dom.doc.body).getPropertyValue('font-size')
    ) || 1

  const sel = editor.selection.getNode()
  const imgSz = sel
    ? parseFloat(editor.dom.doc.defaultView.getComputedStyle(sel).getPropertyValue('font-size')) ||
      1
    : docSz
  const scale = imgSz / docSz

  const url = `/equation_images/${encodeURIComponent(encodeURIComponent(latex))}?scale=${scale}`

  // if I simply create the html string, xsslint fails jenkins
  const img = document.createElement('img')
  img.setAttribute('alt', `LaTeX: ${latex}`)
  img.setAttribute('title', latex)
  img.setAttribute('class', 'equation_image')
  img.setAttribute('data-equation-content', latex)
  img.setAttribute('src', url)
  img.setAttribute('data-ignore-a11y-check', '')
  return insertContent(editor, img.outerHTML)
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
  return !!selection && selection !== ''
}

export function existingContentToLink(editor, link) {
  return (
    !editor.isHidden() &&
    ((link && (currentLink(editor, link) || !!link.selectedContent)) || hasSelection(editor))
  )
}

// Parses HTML string with support in old browsers because jQuery's parseHTML was added in 1.8.
function parseHTML(htmlString) {
  const tmp = document.implementation.createHTMLDocument()
  tmp.body.innerHTML = htmlString.trim()
  return tmp.body.children
}

function selectionIsImg(editor) {
  const selection = editor.selection.getContent()
  return editor.dom.$(parseHTML(selection)).is('img')
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
    inline_disabled: link.embed && link.embed.disableInlinePreview,
    no_preview: link.embed && link.embed.noPreview,
  })

  if (link.embed.type === 'video' || link.embed.type === 'audio') {
    link.id = `media_comment_${link.embed.id || 'maybe'}`
  }
}

export function insertLink(editor, link, canvasOrigin) {
  const linkAttrs = {...link}
  if (linkAttrs.embed) {
    decorateLinkWithEmbed(linkAttrs)
    delete linkAttrs.embed
  }
  return insertUndecoratedLink(editor, linkAttrs, canvasOrigin)
}

function textForLink(linkProps, editor, anchorElm) {
  // Some actions (like editing the link text in the link tray)
  // require an explicit update to the link text
  if (linkProps.forceRename) return linkProps.text

  // Other actions (link highlighting an existing link and changing
  // the linked file) should use the anchor text if present
  return getAnchorText(editor.selection, anchorElm) || linkProps.text
}

// link edit/create logic based on tinymce/plugins/link/plugin.ts
function insertUndecoratedLink(editor, linkProps, canvasOrigin) {
  const selectedElm = editor.selection.getNode()
  const anchorElm = getAnchorElement(editor, selectedElm)
  const selectedContent = editor.selection.getContent()
  const selectedPlainText = editor.selection.getContent({format: 'text'})
  const onlyText = isOnlyTextSelected(selectedContent)

  const linkText = onlyText && textForLink(linkProps, editor, anchorElm)
  // only keep the props we want as attributes on the <a>
  const linkAttrs = {
    id: linkProps.id,
    href: absoluteToRelativeUrl(cleanUrl(linkProps.href || linkProps.url), canvasOrigin),
    target: linkProps.target,
    class: linkProps.class,
    title: linkProps.title,
    'data-canvas-previewable': linkProps['data-canvas-previewable'],
    'data-course-type': linkProps['data-course-type'],
    'data-published': linkProps['data-published'],
  }

  if (linkAttrs.target === '_blank') {
    linkAttrs.rel = 'noopener noreferrer'
  }

  if (anchorElm && !editor.selection.isCollapsed()) {
    updateLink(editor, anchorElm, linkText, linkAttrs)
  } else if (selectedContent) {
    if (linkProps.userText && selectedPlainText !== linkText) {
      createLink(editor, selectedElm, linkText, linkAttrs, canvasOrigin)
    } else {
      createLink(editor, selectedElm, undefined, linkAttrs, canvasOrigin)
    }
  } else {
    createLink(editor, selectedElm, linkText, linkAttrs, canvasOrigin)
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

function createLink(editor, selectedElm, text, linkAttrs, canvasOrigin) {
  if (isImageFigure(selectedElm)) {
    linkImageFigure(editor, selectedElm, linkAttrs, canvasOrigin)
  } else if (text) {
    // create the whole wazoo
    insertContent(editor, renderLink(linkAttrs, text, canvasOrigin))
  } else {
    // create a link on the selected content
    editor.execCommand('mceInsertLink', false, linkAttrs)
  }
}

function linkImageFigure(editor, fig, attrs, canvasOrigin) {
  const img = fig.tagName === 'IMG' ? fig : editor.dom.select('img', fig)[0]
  if (img) {
    const a = renderLink(attrs, img, canvasOrigin)
    img.parentNode.insertBefore(a, img)
  }
}

/* ** video insertion ** */

export function insertVideo(editor, video, canvasOrigin) {
  return insertMedia(editor, video, renderVideo, canvasOrigin)
}

export function insertAudio(editor, audio, canvasOrigin) {
  return insertMedia(editor, audio, renderAudio, canvasOrigin)
}

function insertMedia(editor, media, renderMedia, canvasOrigin) {
  const src = mediaPlayerURLFromFile(media, canvasOrigin)
  if (editor.selection.isCollapsed()) {
    let result = insertContent(editor, renderMedia(media, canvasOrigin))
    // for some reason, editor.selection.getEnd() returned from
    // insertContent is parent paragraph when inserting the
    // media iframe. Look for the iframe with the right
    // src attribute. (Aside: tinymce strips the id or data-*
    // attributes from the iframe, that's why we can't look for those)
    result = result.querySelector(`iframe[src="${src}"]`)

    // When the iframe is inserted, it doesn't allow the media to play
    // because the wrapping span captures the click events. Setting
    // contentEditable to false disables this behavior.
    if (result?.parentElement) {
      editor.dom.setAttrib(result.parentElement, 'contenteditable', false)
    }

    return result
  } else {
    return insertLink(editor, {...media, href: src}, canvasOrigin)
  }
}
