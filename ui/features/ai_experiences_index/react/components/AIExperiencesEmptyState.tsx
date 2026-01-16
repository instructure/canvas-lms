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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'

interface AIExperiencesEmptyStateProps {
  canManage: boolean
  onCreateNew: () => void
}

const AIExperiencesEmptyState: React.FC<AIExperiencesEmptyStateProps> = ({
  canManage,
  onCreateNew,
}) => {
  const I18n = useI18nScope('ai_experiences')

  return (
    <Flex direction="column" alignItems="center" justifyItems="center" margin="x-large 0">
      <Flex.Item margin="0 0 medium 0">
        <Img src="/images/spaceman.png" alt={I18n.t('Spaceman floating in space')} width="200px" />
      </Flex.Item>
      <Flex.Item margin="0 0 small 0">
        <Text size="large" weight="bold">
          {canManage
            ? I18n.t('No AI experiences created yet.')
            : I18n.t('No AI experiences available yet.')}
        </Text>
      </Flex.Item>
      <Flex.Item margin="0 0 medium 0">
        <Text size="medium" color="secondary">
          {canManage
            ? I18n.t('Click the Create New button to start building your first AI experience.')
            : I18n.t('Your instructor has not published any AI experiences yet.')}
        </Text>
      </Flex.Item>
      {canManage && (
        <Flex.Item>
          <Button color="primary" renderIcon={() => <IconAddLine />} onClick={onCreateNew}>
            {I18n.t('Create new')}
          </Button>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default AIExperiencesEmptyState
