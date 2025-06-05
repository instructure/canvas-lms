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

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {ModuleItemContent, ModuleProgression} from '../utils/types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemTitleStudentProps {
  content: ModuleItemContent
  progression?: ModuleProgression
  position?: number
  requireSequentialProgress?: boolean
  url: string
  onClick?: () => void
}

const missingTitleText = I18n.t('Untitled Item')

const ModuleItemTitleStudent = ({
  content,
  progression,
  position,
  requireSequentialProgress,
  url,
  onClick,
}: ModuleItemTitleStudentProps) => {
  return progression?.locked ||
    (requireSequentialProgress &&
      progression?.currentPosition &&
      position &&
      progression?.currentPosition < position) ? (
    <Flex alignItems="center">
      <Text weight="light" color="secondary" data-testid="module-item-title-locked">
        {content?.title || missingTitleText}
      </Text>
    </Flex>
  ) : content?.type === 'SubHeader' ? (
    <Text weight="bold" color="primary" data-testid="subheader-title-text">
      {content?.title || missingTitleText}
    </Text>
  ) : (
    <Link href={url} isWithinText={false} onClick={onClick}>
      <Text weight="bold" color="primary" data-testid="module-item-title">
        {content?.title || missingTitleText}
      </Text>
    </Link>
  )
}

export default ModuleItemTitleStudent
