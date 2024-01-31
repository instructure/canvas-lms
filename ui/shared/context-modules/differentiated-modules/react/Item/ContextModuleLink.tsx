/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useRef, useState} from 'react'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from '@instructure/html-escape'

const I18n = useI18nScope('differentiated_modules')

type ContextModuleLinkProps = {
  courseId?: string | null
  contextModuleId?: string | null
  contextModuleName?: string | null
}

function ContextModuleLink({courseId, contextModuleId, contextModuleName}: ContextModuleLinkProps) {
  const [isShowingTooltip, setIsShowingTooltip] = useState(false)
  const linkElementRef = useRef<Element | undefined>(undefined)
  const italicClassRef = useRef<string | null>(null)
  const linkClassRef = useRef<string | null>(null)
  const [rendered, setRendered] = useState(false)

  if (!courseId || !contextModuleId || !contextModuleName) return null

  if (!rendered) {
    return (
      <Text
        data-testid="temp-context-module-text"
        fontStyle="italic"
        elementRef={el => {
          if (!el) return
          italicClassRef.current = el.className
          setRendered(true)
        }}
      >
        <Link
          elementRef={el => {
            if (!el) return
            linkClassRef.current = el.className
          }}
        >
          &nbsp;
        </Link>
      </Text>
    )
  }

  return (
    <Tooltip
      renderTip={contextModuleName}
      placement="start"
      on={['hover']}
      isShowingContent={isShowingTooltip}
      positionTarget={linkElementRef.current}
    >
      <span
        data-testid="context-module-text"
        className={italicClassRef.current || undefined}
        style={{
          display: 'block',
          whiteSpace: 'nowrap',
          textOverflow: 'ellipsis',
          overflow: 'hidden',
          textAlign: 'right',
          // Equivalent to inst-ui's "small"
          padding: '0.375rem 0',
        }}
        ref={el => {
          if (el && el.offsetWidth < el.scrollWidth) {
            const linkEl = el.querySelector('a')
            if (linkEl) {
              linkElementRef.current = linkEl
              linkEl.onmouseenter = () => setIsShowingTooltip(true)
              linkEl.onmouseleave = () => setIsShowingTooltip(false)
            }
          }
        }}
        dangerouslySetInnerHTML={{
          __html: I18n.t('Inherited from *%{context}*', {
            context: htmlEscape(contextModuleName),
            wrappers: [
              `<a class=${linkClassRef.current} target="_blank" href="/courses/${courseId}/modules#${contextModuleId}">$1</a>`,
            ],
          }),
        }}
      />
    </Tooltip>
  )
}

export default ContextModuleLink
