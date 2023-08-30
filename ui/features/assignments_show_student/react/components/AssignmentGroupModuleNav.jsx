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
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {Flex} from '@instructure/ui-flex'

import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('assignments_2')

const MAX_DISPLAYED_MODULES = 2

export default function AssignmentGroupModuleNav({assignment}) {
  const {assignmentGroup, modules, env} = assignment
  return (
    <Flex margin="0 0 large 0" direction="column">
      {modules.slice(0, MAX_DISPLAYED_MODULES).map(module => (
        <Flex.Item key={module.id} overflowY="visible">
          <Link
            data-testid="module-link"
            href={env.moduleUrl}
            isWithinText={false}
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
          >
            {module.name}
          </Link>
        </Flex.Item>
      ))}
      {modules.length > MAX_DISPLAYED_MODULES && (
        <Flex.Item overflowY="visible">
          <Link
            data-testid="more-module-link"
            href={env.moduleUrl}
            isWithinText={false}
            themeOverride={{mediumPaddingHorizontal: '0', mediumHeight: 'normal'}}
          >
            {I18n.t('More Modules')}
          </Link>
        </Flex.Item>
      )}

      {assignmentGroup && (
        <Flex.Item overflowY="visible">
          <Link
            data-testid="assignmentgroup-link"
            href={env.assignmentUrl}
            isWithinText={false}
            themeOverride={{mediumPadmediumPaddingHorizontalding: '0', mediumHeight: 'normal'}}
          >
            {assignmentGroup.name}
          </Link>
        </Flex.Item>
      )}
    </Flex>
  )
}

AssignmentGroupModuleNav.propTypes = {
  assignment: Assignment.shape,
}
