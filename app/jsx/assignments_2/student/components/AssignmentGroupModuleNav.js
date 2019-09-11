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
import {Assignment} from '../graphqlData/Assignment'
import I18n from 'i18n!assignments_2'
import React from 'react'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-layout'

const MAX_DISPLAYED_MODULES = 2

function AssignmentGroupModuleNav(props) {
  const {
    assignment: {assignmentGroup, modules, env}
  } = props

  return (
    <Flex margin="0 0 large 0" direction="column">
      {modules.slice(0, MAX_DISPLAYED_MODULES).map(module => (
        <Flex.Item key={module.id} overflowY="visible">
          <Button
            data-testid="module-link"
            href={env.moduleUrl}
            variant="link"
            theme={{mediumPadding: '0', mediumHeight: 'normal'}}
          >
            {module.name}
          </Button>
        </Flex.Item>
      ))}
      {modules.length > MAX_DISPLAYED_MODULES && (
        <Flex.Item overflowY="visible">
          <Button
            data-testid="more-module-link"
            href={env.moduleUrl}
            variant="link"
            theme={{mediumPadding: '0', mediumHeight: 'normal'}}
          >
            {I18n.t('More Modules')}
          </Button>
        </Flex.Item>
      )}

      {assignmentGroup && (
        <Flex.Item overflowY="visible">
          <Button
            data-testid="assignmentgroup-link"
            href={env.assignmentUrl}
            variant="link"
            theme={{mediumPadding: '0', mediumHeight: 'normal'}}
          >
            {assignmentGroup.name}
          </Button>
        </Flex.Item>
      )}
    </Flex>
  )
}

AssignmentGroupModuleNav.propTypes = {
  assignment: Assignment.shape
}

export default React.memo(AssignmentGroupModuleNav)
