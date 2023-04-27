// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import CopyToClipboardButton from '@canvas/copy-to-clipboard-button'
import React from 'react'
import {IconInfoLine, IconPublishSolid, IconResetSolid, IconTrashLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = useI18nScope('internal-settings')

export type InternalSettingActionButtonsProps = {
  name: string
  value?: string
  secret?: boolean
  pendingChange?: boolean
  allowCopy?: boolean
  onSubmitPendingChange: () => void
  onClearPendingChange: () => void
  onDelete?: () => void
}

export const InternalSettingActionButtons = (props: InternalSettingActionButtonsProps) => (
  <div style={{display: 'flex', justifyContent: 'space-around'}}>
    {props.secret ? (
      <Tooltip
        renderTip={I18n.t('This is a secret setting, and may only be modified from the console')}
        on={['hover', 'focus']}
      >
        <IconInfoLine />
      </Tooltip>
    ) : props.pendingChange ? (
      <>
        <Tooltip renderTip={I18n.t('Save')} on={['hover', 'focus']}>
          <IconButton
            size="small"
            margin="auto x-small"
            color="primary"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t(`Save "%{name}"`, {name: props.name})}
            onClick={props.onSubmitPendingChange}
          >
            <IconPublishSolid />
          </IconButton>
        </Tooltip>
        <Tooltip renderTip={I18n.t('Reset')} on={['hover', 'focus']}>
          <IconButton
            size="small"
            margin="auto x-small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t(`Reset "%{name}"`, {name: props.name})}
            onClick={props.onClearPendingChange}
          >
            <IconResetSolid />
          </IconButton>
        </Tooltip>
      </>
    ) : (
      <>
        {props.allowCopy && (
          <CopyToClipboardButton
            value={props.value || ''}
            buttonProps={{
              withBackground: false,
              withBorder: false,
              margin: 'auto x-small',
            }}
            tooltip={true}
          />
        )}
        {props.onDelete && (
          <Tooltip renderTip={I18n.t('Delete')} on={['hover', 'focus']}>
            <IconButton
              size="small"
              margin="auto x-small"
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t(`Delete "%{name}"`, {name: props.name})}
              onClick={props.onDelete}
            >
              <IconTrashLine />
            </IconButton>
          </Tooltip>
        )}
      </>
    )}
  </div>
)
