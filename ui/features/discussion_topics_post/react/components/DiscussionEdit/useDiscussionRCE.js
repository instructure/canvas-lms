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

import {useState, useEffect, useCallback} from 'react'
import RichContentEditor from '@canvas/rce/RichContentEditor'

export const useDiscussionRCE = (useRceMentions = false) => {
  const [isLoaded, setIsLoaded] = useState(false)
  const [textareaRef, setTextareaRef] = useState(null)
  const defaultRCEOpts = {
    focus: false,
    manageParent: false
  }

  useEffect(() => {
    async function getEditorOptions() {
      const options = {...defaultRCEOpts}

      if (useRceMentions) {
        // Use the canvas mentions tinymce plugin
        const mentionsPlugin = await import('@canvas/rce/plugins/canvas_mentions/plugin')
        options.tinyOptions = {plugins: [mentionsPlugin.name]}
        options.optionsToMerge = ['plugins']
      }

      return options
    }

    if (!isLoaded && textareaRef) {
      getEditorOptions()
        .then(options => {
          RichContentEditor.loadNewEditor(textareaRef, options, () => {
            setIsLoaded(true)
          })
        })
        .catch(error => {
          console.error(error)
          // If there was an error loading the mentions plugin, load without it
          RichContentEditor.loadNewEditor(textareaRef, defaultRCEOpts, () => {
            setIsLoaded(true)
          })
        })
    }

    return () => {
      if (textareaRef) {
        if (RichContentEditor.callOnRCE(textareaRef, 'exists?')) {
          RichContentEditor.closeRCE(textareaRef)
          RichContentEditor.destroyRCE(textareaRef)
        }
        setIsLoaded(false)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [textareaRef])

  const getText = useCallback(
    () => RichContentEditor.callOnRCE(textareaRef, 'get_code'),
    [textareaRef]
  )
  const setText = useCallback(
    content => RichContentEditor.callOnRCE(textareaRef, 'set_code', content),
    [textareaRef]
  )

  return [setTextareaRef, getText, setText]
}

export default useDiscussionRCE
