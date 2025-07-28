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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert as AlertData, AlertUIMetadata} from './types'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'

const I18n = createI18nScope('alerts')

export interface AlertProps {
  alert: AlertData
  uiMetadata: AlertUIMetadata
  onEdit: (alertId: AlertData) => void
  onDelete: (alertId: AlertData) => void
}

const Alert = ({alert, uiMetadata, onEdit, onDelete}: AlertProps) => {
  return (
    <Flex justifyItems="space-between" alignItems="start">
      <Flex direction="column" gap="small">
        <div>
          <Text weight="bold">{I18n.t('Trigger when')}</Text>
          <List margin="0" themeOverride={{listPadding: '1rem'}}>
            {alert.criteria.map(criterion => (
              <List.Item key={criterion.criterion_type}>
                {uiMetadata.POSSIBLE_CRITERIA[criterion.criterion_type].label(criterion.threshold)}
              </List.Item>
            ))}
          </List>
        </div>
        <div>
          <Text weight="bold">{I18n.t('Send to')}</Text>
          <List margin="0" themeOverride={{listPadding: '1rem'}}>
            {alert.recipients.map(recipientId => (
              <List.Item key={recipientId}>{uiMetadata.POSSIBLE_RECIPIENTS[recipientId]}</List.Item>
            ))}
          </List>
        </div>
        <div>
          <Text weight="bold">{I18n.t('Resend alerts')}</Text>
          <List margin="0" themeOverride={{listPadding: '1rem'}}>
            <List.Item>
              {alert.repetition
                ? I18n.t('Every %{count} days until resolved.', {
                    count: alert.repetition,
                  })
                : I18n.t('Do not resend.')}
            </List.Item>
          </List>
        </div>
      </Flex>
      <Flex gap="medium">
        <IconButton
          withBackground={false}
          withBorder={false}
          aria-label={I18n.t('Edit alert button')}
          screenReaderLabel={I18n.t('Edit alert')}
          onClick={() => onEdit(alert)}
        >
          <IconEditLine />
        </IconButton>
        <IconButton
          withBackground={false}
          withBorder={false}
          aria-label={I18n.t('Delete alert button')}
          screenReaderLabel={I18n.t('Delete alert')}
          onClick={() => onDelete(alert)}
        >
          <IconTrashLine />
        </IconButton>
      </Flex>
    </Flex>
  )
}

export default Alert
