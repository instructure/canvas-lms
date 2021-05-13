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

import {useState, useEffect, useCallback, useRef} from 'react'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const useRCE = (height = 256, customOptions = {}) => {
  const [code, setCodeState] = useState(null)
  const elemRef = useRef(null)
  const intervalRef = useRef(null)

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

  const clear = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current)
    }

    if (elemRef.current && RichContentEditor.callOnRCE(elemRef.current, 'exists?')) {
      RichContentEditor.closeRCE(elemRef.current)
      RichContentEditor.destroyRCE(elemRef.current)
    }
  }

  const setElemRef = useCallback(elem => {
    // somehow, is calling elem with null
    if (!elem) {
      return
    }
    if (elemRef.current !== elem) {
      clear()
      elemRef.current = elem

      intervalRef.current = setInterval(() => {
        setCodeState(getCode())
      }, 500)

      RichContentEditor.loadNewEditor(elemRef.current, {
        focus: false,
        manageParent: false,
        tinyOptions: {
          ...defaultOptions,
          ...customOptions
        }
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const getCode = useCallback(() => {
    if (elemRef.current) {
      return RichContentEditor.callOnRCE(elemRef.current, 'get_code')
    }
  }, [])

  const setCode = useCallback(content => {
    if (elemRef.current) {
      RichContentEditor.callOnRCE(elemRef.current, 'set_code', content)
    }
  }, [])

  useEffect(() => {
    return () => {
      clear()
    }
  }, [])

  return [setElemRef, getCode, setCode, code]
}

export default useRCE
