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

import React from 'react'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('assignment_teacher_header')

interface HeaderProps {
  edit: boolean
}

const AssignmentHeader: React.FC<HeaderProps> = ({edit}) => {
  return (
    <Flex alignItems="start" width="100%">
      <Heading data-testid="assignment-heading" level="h1">
        {edit ? I18n.t('Edit Assignment') : I18n.t('Create Assignment')}
      </Heading>
    </Flex>
  )
}

export default AssignmentHeader
