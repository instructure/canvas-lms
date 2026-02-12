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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import type {MasteryLevel} from './types'
import MasteryIcon from './MasteryIcon'

const I18n = createI18nScope('outcome_management')

interface MasteryDetailProps {
  masteryLevel: MasteryLevel
}

const masteryMap: Record<MasteryLevel, string> = {
  exceeds_mastery: I18n.t('Exceeds Mastery'),
  mastery: I18n.t('Mastery'),
  near_mastery: I18n.t('Near Mastery'),
  remediation: I18n.t('Remediation'),
  unassessed: I18n.t('Unassessed'),
  no_evidence: I18n.t('No Evidence'),
}

const MasteryDetail = ({masteryLevel}: MasteryDetailProps) => {
  return (
    <Flex gap="x-small" justifyItems="start" alignItems="center">
      <Flex.Item>
        <Text size="small" weight="bold">
          {masteryMap[masteryLevel] ?? I18n.t('Unknown')}
        </Text>
      </Flex.Item>
      <Flex.Item>
        <MasteryIcon masteryLevel={masteryLevel} />
      </Flex.Item>
    </Flex>
  )
}

export default MasteryDetail
