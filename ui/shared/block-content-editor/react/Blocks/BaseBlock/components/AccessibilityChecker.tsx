/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {ReactNode, useEffect} from 'react'
import {useNode} from '@craftjs/core'
import {useBlockContentEditorContext} from '../../../BlockContentEditorContext'
import {checkHtmlContent} from '../../../accessibilityChecker/htmlChecker'
import {debounce} from 'lodash'
import {View} from '@instructure/ui-view'
import {useInstUIRef} from '../useInstUIRef'

interface BaseBlockA11yWrapperProps {
  children: ReactNode
  componentProps: any
}

export function AccessibilityChecker({children, componentProps}: BaseBlockA11yWrapperProps) {
  const [renderedContentRef, setRenderedContentRef] = useInstUIRef<Element>()

  const {
    accessibility: {addA11yIssues},
  } = useBlockContentEditorContext()
  const {id} = useNode()

  useEffect(() => {
    const debouncedCheckA11y = debounce(async () => {
      if (renderedContentRef.current && id) {
        const result = await checkHtmlContent(renderedContentRef.current)
        addA11yIssues(id, result.issues)
      }
    }, 600)

    debouncedCheckA11y()
    return () => {
      debouncedCheckA11y.cancel()
    }
  }, [componentProps, id])

  return <View elementRef={setRenderedContentRef}>{children}</View>
}
