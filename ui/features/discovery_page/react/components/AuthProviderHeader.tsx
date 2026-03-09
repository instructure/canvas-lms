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

import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconArrowDownLine, IconArrowUpLine, IconTrashLine} from '@instructure/ui-icons'
import {SVGIcon} from '@instructure/ui-svg-images'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discovery_page')

interface AuthProviderHeaderProps {
  label: string
  iconUrl?: string
  disableMoveUp?: boolean
  disableMoveDown?: boolean
  onDelete: () => void
  onMoveUp: () => void
  onMoveDown: () => void
}

const PlaceholderIcon = () => (
  <SVGIcon title="" viewBox="0 0 24 24" size="small" color="secondary">
    <circle cx="12" cy="12" r="10" />
  </SVGIcon>
)

export function AuthProviderHeader({
  label,
  iconUrl,
  disableMoveUp,
  disableMoveDown,
  onDelete,
  onMoveUp,
  onMoveDown,
}: AuthProviderHeaderProps) {
  return (
    <Flex as="div" alignItems="center" justifyItems="space-between" gap="x-small">
      <Flex.Item shouldShrink={true}>
        <Flex alignItems="center" gap="x-small">
          {iconUrl ? (
            <img src={iconUrl} alt="" style={{width: '24px', height: '24px'}} />
          ) : (
            <PlaceholderIcon />
          )}

          <Text weight="bold" wrap="break-word">
            {label}
          </Text>
        </Flex>
      </Flex.Item>

      <Flex alignItems="center" gap="xxx-small">
        <Tooltip renderTip={I18n.t('Delete')}>
          <IconButton
            screenReaderLabel={I18n.t('Delete item')}
            withBackground={false}
            withBorder={false}
            onClick={e => {
              e.stopPropagation()
              onDelete()
            }}
            size="small"
          >
            <IconTrashLine />
          </IconButton>
        </Tooltip>

        {disableMoveUp ? (
          <IconButton
            screenReaderLabel={I18n.t('Move up')}
            withBackground={false}
            withBorder={false}
            interaction="disabled"
            size="small"
          >
            <IconArrowUpLine />
          </IconButton>
        ) : (
          <Tooltip renderTip={I18n.t('Move up')}>
            <IconButton
              screenReaderLabel={I18n.t('Move up')}
              withBackground={false}
              withBorder={false}
              onClick={e => {
                e.stopPropagation()
                onMoveUp()
              }}
              size="small"
            >
              <IconArrowUpLine />
            </IconButton>
          </Tooltip>
        )}

        {disableMoveDown ? (
          <IconButton
            screenReaderLabel={I18n.t('Move down')}
            withBackground={false}
            withBorder={false}
            interaction="disabled"
            size="small"
          >
            <IconArrowDownLine />
          </IconButton>
        ) : (
          <Tooltip renderTip={I18n.t('Move down')}>
            <IconButton
              screenReaderLabel={I18n.t('Move down')}
              withBackground={false}
              withBorder={false}
              onClick={e => {
                e.stopPropagation()
                onMoveDown()
              }}
              size="small"
            >
              <IconArrowDownLine />
            </IconButton>
          </Tooltip>
        )}
      </Flex>
    </Flex>
  )
}
