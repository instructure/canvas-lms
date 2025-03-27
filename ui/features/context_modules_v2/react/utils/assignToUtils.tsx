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

import React from 'react'
import {createRoot} from 'react-dom/client'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'
import type {ItemType, IconType} from '@canvas/context-modules/differentiated-modules/react/types'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'

const I18n = createI18nScope('context_modules_v2')

const ENV = window.ENV as GlobalEnv

export const getIconType = (contentType?: string): IconType => {
  if (!contentType) return 'page'

  const type = contentType.toLowerCase()

  if (type.includes('assignment')) return 'assignment'
  if (type.includes('quiz')) return 'quiz'
  if (type.includes('discussion')) return 'discussion'
  if (type.includes('wiki') || type.includes('page')) return 'page'

  return 'page'
}

export const getItemType = (contentType?: string): ItemType => {
  if (!contentType) return 'wiki_page'

  const type = contentType.toLowerCase()

  if (type.includes('assignment')) return 'assignment'
  if (type.includes('quiz')) return 'quiz'
  if (type.includes('discussion')) return 'discussion_topic'
  if (type.includes('wiki') || type.includes('page')) return 'wiki_page'

  return 'wiki_page'
}

export interface ItemAssignToProps {
  courseId: string
  moduleItemName: string
  moduleItemType: ItemType
  moduleItemContentId?: string
  pointsPossible?: number
}

export const renderItemAssignToManager = (
  open: boolean,
  returnFocusTo: HTMLElement,
  itemProps: ItemAssignToProps
) => {
  let container = document.getElementById('module-item-assign-to-mount-point')
  if (!container) {
    container = document.createElement('div')
    container.id = 'module-item-assign-to-mount-point'
    document.body.appendChild(container)
  }

  if ((container as any).reactRoot) {
    (container as any).reactRoot.unmount()
  }

  (container as any).reactRoot = createRoot(container)
  ;(container as any).reactRoot.render(
    <ItemAssignToManager
      open={open}
      onClose={() => {
        if ((container as any).reactRoot) {
          (container as any).reactRoot.unmount()
        }
      }}
      onDismiss={() => {
        if ((container as any).reactRoot) {
          (container as any).reactRoot.unmount()
        }
        returnFocusTo.focus()
      }}
      onSave={() => {
        if ((container as any).reactRoot) {
          (container as any).reactRoot.unmount()
        }
        returnFocusTo.focus()
        showFlashSuccess(I18n.t('Assignment settings saved successfully'))
      }}
      courseId={itemProps.courseId}
      itemName={itemProps.moduleItemName}
      itemType={itemProps.moduleItemType}
      iconType={getIconType(itemProps.moduleItemType)}
      itemContentId={itemProps.moduleItemContentId}
      pointsPossible={itemProps.pointsPossible}
      locale={ENV.LOCALE || 'en'}
      timezone={ENV.TIMEZONE || 'UTC'}
    />
  )
}
