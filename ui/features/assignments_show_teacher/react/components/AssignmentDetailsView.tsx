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
import {useScope as createI18nScope} from '@canvas/i18n'

import AssignmentDescription from '@canvas/assignments/react/AssignmentDescription'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('assignment_2_teacher_assignment_details')

const AssignmentDetailsView = ({description}: {description?: string}) => {
  return (
    <Flex as="div" direction="column">
      <Flex.Item as="div" direction="column" margin="medium 0">
        <Heading variant="label">{I18n.t('Description')}</Heading>
        <AssignmentDescription description={description} />
      </Flex.Item>
    </Flex>
  )
}

export default AssignmentDetailsView
