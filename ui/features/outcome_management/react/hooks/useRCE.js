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
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const useRCE = (height = 256, customOptions = {}) => {
  const [isLoaded, setIsLoaded] = useState(false)
  const [elemRef, setElemRef] = useState(null)

  const {useRceEnhancements} = useCanvasContext()
  const plugins = useRceEnhancements
    ? 'hr,fullscreen,instructure-ui-icons,instructure_condensed_buttons,instructure_html_view'
    : 'textcolor'
  const defaultOptions = {
    height,
    resize: false,
    plugins: `autolink,paste,table,lists,${plugins},link,directionality,a11y_checker,wordcount`,
    external_plugins: {
      instructure_embed: '/javascripts/tinymce_plugins/instructure_embed/plugin.js',
      instructure_equation: '/javascripts/tinymce_plugins/instructure_equation/plugin.js'
    }
  }

  useEffect(() => {
    if (!isLoaded && elemRef) {
      RichContentEditor.loadNewEditor(
        elemRef,
        {
          focus: false,
          manageParent: false,
          tinyOptions: {
            ...defaultOptions,
            ...customOptions
          }
        },
        () => setIsLoaded(true)
      )
    }
    return () => {
      if (elemRef) {
        if (RichContentEditor.callOnRCE(elemRef, 'exists?')) {
          RichContentEditor.closeRCE(elemRef)
          RichContentEditor.destroyRCE(elemRef)
        }
        setIsLoaded(false)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [elemRef])

  const getCode = useCallback(() => RichContentEditor.callOnRCE(elemRef, 'get_code'), [elemRef])

  return [setElemRef, getCode]
}

export default useRCE
