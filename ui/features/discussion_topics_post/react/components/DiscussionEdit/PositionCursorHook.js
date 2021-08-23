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

/**
 * Handles moving the cursor past reply previews
 *
 * There are three primary cases:
 * 1. No reply preview present (noop)
 * 2. Reply preview present in a new reply (move cursor to after reply preview)
 * 3. Reply preview present in a reply being edited (move cursor to end of post-preview content)
 */
const positionCursor = rceRef => {
  // Don't do anything until RCE is initialized
  if (!rceRef.current) return

  // Grab the instance of TinyMCE
  const {editor} = rceRef.current
  const replyPreview = editor.dom.select('div.reply_preview')[0]
  const postReplyPreview = editor.dom.select('p.post-reply-preview')[0]

  // New reply with a preview
  if (replyPreview && !postReplyPreview) {
    positionForCreateReply(editor)

    // Editing an existing reply with a preview
  } else if (postReplyPreview?.innerText.trim() !== '') {
    positionForEditReply(editor, postReplyPreview)
  }
}

const positionForCreateReply = editor => {
  // Inject a paragraph right after the discussion preview
  editor.selection.setCursorLocation(editor.getBody().lastElementChild, 0)
  editor.execCommand('mceInsertContent', false, '<p class="post-reply-preview"></p>')

  // Move cursor to the paragraph
  const target = editor.dom.select('p.post-reply-preview')[0]
  editor.selection.setCursorLocation(target, 0)
}

const positionForEditReply = (editor, postReplyPreview) => {
  editor.selection.select(postReplyPreview)
  editor.selection.collapse()
}

export default positionCursor
