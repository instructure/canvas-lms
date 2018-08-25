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

import classnames from "classnames";
import { renderLink, renderImage, renderLinkedImage } from "./contentRendering";
import { cleanUrl } from "./contentInsertionUtils";
import scroll from "../common/scroll";

/*** generic content insertion ***/

// when the editor is hidden, just replace the selected portion of the textarea
// with the content. branching is for cross-browser
function replaceTextareaSelection(editor, content) {
  const element = editor.getElement();
  if ("selectionStart" in element) {
    // mozilla / dom 3.0
    const before = element.value.substr(0, element.selectionStart);
    const after = element.value.substr(
      element.selectionEnd,
      element.value.length
    );
    element.value = before + content + after;
  } else if (document.selection) {
    // exploder
    element.focus();
    document.selection.createRange().text = content;
  } else {
    // browser not supported
    element.value += content;
  }
}

export function insertContent(editor, content) {
  if (editor.isHidden()) {
    // replaces the textarea selection with the new image. no element returned
    // to indicate because it's raw html.
    replaceTextareaSelection(editor, content);
    return null;
  } else {
    // inserts content at the cursor. getEnd() of the selection after the
    // insertion should reference the newly created node (or first of the newly
    // created nodes if there were multiple, unfortunately), because the cursor
    // itself stays just before the new content.
    scroll.scrollIntoViewWDelay(editor.iframeElement, {});
    editor.insertContent(content);
    return editor.selection.getEnd();
  }
}

/*** image insertion ***/

function isElemImg(elem) {
  return elem && elem.nodeName.toLowerCase() === "img";
}

function isElemAnchor(elem) {
  return elem && elem.nodeName.toLowerCase() === "a";
}

/*
  check if we should preserve the parent anchor tag. the criteria is pretty
  strict based on if we have a single image selected with an anchor tag
  surrounding
*/
function shouldPreserveImgAnchor(editor) {
  var selection = editor.selection;
  var selectedRange = selection.getRng();

  return (
    isElemImg(selection.getNode()) &&
    isElemAnchor(selectedRange.startContainer) &&
    selectedRange.startContainer === selectedRange.endContainer
  );
}

export function insertImage(editor, image) {
  var content = "";
  if (shouldPreserveImgAnchor(editor)) {
    content = renderLinkedImage(
      editor.selection.getRng().startContainer,
      image
    );
  } else {
    content = renderImage(image);
  }
  return insertContent(editor, content);
}

/*** link insertion ***/

// checks if there's an existing anchor containing the cursor
function currentLink(editor, link) {
  const cursor =
    link.selectionDetails && link.selectionDetails.node
      ? link.selectionDetails.node
      : editor.selection.getNode(); // This doesn't work in IE 11, but will stop brokeness in other browsers
  return editor.dom.getParent(cursor, "a");
}

// checks if the editor has a current selection (vs. just a cursor position)
function hasSelection(editor) {
  let selection = editor.selection.getContent();
  selection = editor.dom.decode(selection);
  return !!selection && selection != "";
}

export function existingContentToLink(editor, link) {
  return (
    !editor.isHidden() &&
    ((link && (currentLink(editor, link) || !!link.selectedContent)) ||
      hasSelection(editor))
  );
}

function selectionIsImg(editor) {
  let selection = editor.selection.getContent();
  return editor.dom.$(selection).is("img");
}

export function existingContentToLinkIsImg(editor) {
  return !editor.isHidden() && selectionIsImg(editor);
}

function insertUndecoratedLink(editor, link) {
  editor.focus();
  if (existingContentToLink(editor, link)) {
    if (!hasSelection(editor)) {
      // editor.selection doesn't work so well in IE 11 so we handle that case
      // here by setting our range to what it was prior to the insertion
      editor.selection.setRng(link.selectionDetails.range);
    }
    // link selected content or update existing link containing selected
    // content / cursor. given a non-empty selection outside any existing link,
    // will wrap a new link around the selection. alternately, given a
    // selection or cursor inside an existing link, will update that existing
    // link. (the boundaries where a selection passes across link boundaries
    // are a little weird, a tinymce bug afaik).
    editor.execCommand("mceInsertLink", false, link);
    return editor.selection.getNode();
  } else {
    // render html for a new link and insert it into the editor at the cursor
    return insertContent(editor, renderLink(link));
  }
}

function decorateLinkWithEmbed(link) {
  link["class"] = classnames(link["class"], {
    instructure_file_link: true,
    instructure_scribd_file: link.embed.type == "scribd",
    instructure_image_thumbnail: link.embed.type == "image",
    instructure_video_link: link.embed.type == "video",
    instructure_audio_link: link.embed.type == "audio"
  });

  if (link.embed.type == "video" || link.embed.type == "audio") {
    link["id"] = `media_comment_${link.embed.id || "maybe"}`;
  }
}

export function insertLink(editor, link) {
  if (link.href) {
    link.href = cleanUrl(link.href);
  }
  if (link.embed) {
    decorateLinkWithEmbed(link);
  }
  return insertUndecoratedLink(editor, link);
}
