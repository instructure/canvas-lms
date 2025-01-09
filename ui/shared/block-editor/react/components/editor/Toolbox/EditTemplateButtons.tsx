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

import React, {useCallback} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconXLine} from '@instructure/ui-icons'
import {type KeyboardOrMouseEvent} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type EditTemplateButtonsProps = {
  templateId: string
  onEditTemplate: (id: string) => void
  onDeleteTemplate: (id: string) => void
}

const EditTemplateButtons = ({
  templateId,
  onEditTemplate,
  onDeleteTemplate,
}: EditTemplateButtonsProps) => {
  const handleDeleteTemplate = useCallback(
    (id: string, event: KeyboardOrMouseEvent) => {
      event.stopPropagation()
      onDeleteTemplate(id)
    },
    [onDeleteTemplate],
  )

  const handleEditTemplate = useCallback(
    (id: string, event: KeyboardOrMouseEvent) => {
      event.stopPropagation()
      onEditTemplate(id)
    },
    [onEditTemplate],
  )

  return (
    <div
      style={{
        position: 'absolute',
        display: 'flex',
        justifyContent: 'flex-end',
        gap: '4px',
        top: 0,
        right: 0,
        lineHeight: '.75rem',
      }}
    >
      <IconButton
        themeOverride={{smallHeight: '.75rem'}}
        screenReaderLabel={I18n.t('Edit Template')}
        title={I18n.t('Edit Template')}
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={handleEditTemplate.bind(null, templateId)}
        data-testid="edit-template-icon-button-edit"
      >
        <IconEditLine size="x-small" themeOverride={{sizeXSmall: '.5rem'}} />
      </IconButton>
      <IconButton
        themeOverride={{smallHeight: '.75rem'}}
        screenReaderLabel={I18n.t('Delete Template')}
        title={I18n.t('Delete Template')}
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={handleDeleteTemplate.bind(null, templateId)}
        data-testid="edit-template-icon-button-delete"
      >
        <IconXLine size="x-small" themeOverride={{sizeXSmall: '.5rem'}} />
      </IconButton>
    </div>
  )
}

export {EditTemplateButtons}
