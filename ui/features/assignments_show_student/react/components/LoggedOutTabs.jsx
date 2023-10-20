/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool} from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import LoginActionPrompt from './LoginActionPrompt'
import React from 'react'
import RubricTab from './RubricTab'

LoggedOutTabs.propTypes = {
  assignment: Assignment.shape.isRequired,
  nonAcceptedEnrollment: bool,
}

export default function LoggedOutTabs(props) {
  return (
    <div>
      {props.assignment.rubric && (
        <RubricTab rubric={props.assignment.rubric} peerReviewModeEnabled={false} />
      )}
      {ENV.current_user ? null : (
        <Flex as="header" alignItems="center" justifyItems="center" direction="column">
          <Flex.Item>
            <LoginActionPrompt
              nonAcceptedEnrollment={props.nonAcceptedEnrollment}
              enrollmentState={props.assignment.env.enrollmentState}
            />
          </Flex.Item>
        </Flex>
      )}
    </div>
  )
}
