/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {type ReactNode} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Img} from '@instructure/ui-img'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconArrowDownLine,
  IconArrowUpLine,
  IconEditLine,
  IconTrashLine,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AuthProviderHeaderProps} from '../types'

const I18n = createI18nScope('discovery_page')

function ActionButton({
  screenReaderLabel,
  tooltipLabel,
  icon,
  disabled,
  onClick,
}: {
  screenReaderLabel: string
  tooltipLabel: string
  icon: ReactNode
  disabled: boolean
  onClick: () => void
}) {
  const button = (
    <IconButton
      screenReaderLabel={screenReaderLabel}
      withBackground={false}
      withBorder={false}
      interaction={disabled ? 'disabled' : 'enabled'}
      onClick={
        disabled
          ? undefined
          : e => {
              e.stopPropagation()
              onClick()
            }
      }
      size="small"
    >
      {icon}
    </IconButton>
  )
  return disabled ? button : <Tooltip renderTip={tooltipLabel}>{button}</Tooltip>
}

export function AuthProviderHeader({
  label,
  iconUrl,
  providerUrl,
  isEditing,
  isDisabled,
  disableMoveUp,
  disableMoveDown,
  onEditStart,
  onDelete,
  onMoveUp,
  onMoveDown,
}: AuthProviderHeaderProps) {
  return (
    <Flex alignItems="start" as="div" gap="x-small" justifyItems="space-between">
      <Flex.Item shouldShrink={true}>
        <Flex alignItems="center" gap="small">
          <Flex.Item align="start" shouldGrow={false} shouldShrink={false} size="24px">
            {iconUrl ? (
              <Img alt="" display="block" src={iconUrl} width="100%" />
            ) : (
              <Flex alignItems="center" justifyItems="center" height="24px">
                <IconUnpublishedLine color="secondary" size="x-small" />
              </Flex>
            )}
          </Flex.Item>

          <Flex direction="column">
            <Text weight="bold" wrap="break-word">
              {label || '\u00A0'}
            </Text>

            <Text size="small" color="secondary">
              {providerUrl || '\u00A0'}
            </Text>
          </Flex>
        </Flex>
      </Flex.Item>

      <Flex alignItems="center" gap="xxx-small">
        <ActionButton
          screenReaderLabel={I18n.t('Edit item')}
          tooltipLabel={I18n.t('Edit')}
          icon={<IconEditLine />}
          disabled={isDisabled || isEditing}
          onClick={onEditStart}
        />

        <ActionButton
          screenReaderLabel={I18n.t('Delete item')}
          tooltipLabel={I18n.t('Delete')}
          icon={<IconTrashLine />}
          disabled={isDisabled || isEditing}
          onClick={onDelete}
        />

        <ActionButton
          screenReaderLabel={I18n.t('Move up')}
          tooltipLabel={I18n.t('Move up')}
          icon={<IconArrowUpLine />}
          disabled={!!disableMoveUp || isEditing || isDisabled}
          onClick={onMoveUp}
        />

        <ActionButton
          screenReaderLabel={I18n.t('Move down')}
          tooltipLabel={I18n.t('Move down')}
          icon={<IconArrowDownLine />}
          disabled={!!disableMoveDown || isEditing || isDisabled}
          onClick={onMoveDown}
        />
      </Flex>
    </Flex>
  )
}
