/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import I18n from 'i18n!assignments_2'
import React from 'react'

import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'

import {StudentAssignmentShape} from '../assignmentData'

const MAX_DISPLAYED_MODULES = 2

function AssignmentGroupModuleNav(props) {
  const {
    assignment: {assignmentGroup, modules, env}
  } = props

  return (
    <Flex margin="0 0 large 0" direction="column">
      {modules.slice(0, MAX_DISPLAYED_MODULES).map(module => (
        <FlexItem key={module.id}>
          <Link data-test-id="module-link" href={env.moduleUrl} theme={{color: '#000000'}}>
            <Text size="medium">{module.name}</Text>
          </Link>
        </FlexItem>
      ))}
      {modules.length > MAX_DISPLAYED_MODULES && (
        <FlexItem>
          <Link data-test-id="module-link" href={env.moduleUrl} theme={{color: '#000000'}}>
            <Text size="medium">{I18n.t('More Modules')}</Text>
          </Link>
        </FlexItem>
      )}

      {assignmentGroup && (
        <FlexItem>
          <Link
            data-test-id="assignmentgroup-link"
            href={env.assignmentUrl}
            theme={{color: '#000000'}}
          >
            <Text size="medium">{assignmentGroup.name}</Text>
          </Link>
        </FlexItem>
      )}
    </Flex>
  )
}

AssignmentGroupModuleNav.propTypes = {
  assignment: StudentAssignmentShape
}

export default React.memo(AssignmentGroupModuleNav)
