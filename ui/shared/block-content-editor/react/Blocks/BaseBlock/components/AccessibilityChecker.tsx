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
import {checkHtmlContent} from '../../../accessibilityChecker/htmlChecker'
import {debounce} from 'es-toolkit/compat'
import {View} from '@instructure/ui-view'
import {useInstUIRef} from '../../../hooks/useInstUIRef'
import {AccessibilityRule} from '../../../accessibilityChecker/types'
import {useAccessibilityChecker} from '../../../hooks/useAccessibilityChecker'

interface BaseBlockA11yWrapperProps {
  children: ReactNode
  customAccessibilityCheckRules?: AccessibilityRule[]
  componentProps: unknown
}

export function AccessibilityChecker({
  children,
  customAccessibilityCheckRules,
  componentProps,
}: BaseBlockA11yWrapperProps) {
  const [renderedContentRef, setRenderedContentRef] = useInstUIRef<Element>()
  const {addA11yIssues} = useAccessibilityChecker()
  const {id, blockName} = useNode(node => ({
    blockName: node.data.name,
  }))

  useEffect(() => {
    const debouncedCheckA11y = debounce(async () => {
      if (renderedContentRef.current && id) {
        const result = await checkHtmlContent(
          renderedContentRef.current,
          customAccessibilityCheckRules,
        )
        // TODO: check if node is still mounted?
        addA11yIssues(id, result.issues)
      }
    }, 600)

    debouncedCheckA11y()
    return () => {
      debouncedCheckA11y.cancel()
    }
  }, [componentProps, id, blockName])

  return <View elementRef={setRenderedContentRef}>{children}</View>
}
