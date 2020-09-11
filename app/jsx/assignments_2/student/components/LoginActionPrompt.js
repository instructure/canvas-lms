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

import {bool} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {Flex, View} from '@instructure/ui-layout'
import I18n from 'i18n!assignments_2_login_action_prompt'
import lockedSVG from '../SVG/Locked1.svg'
import React from 'react'
import {Text} from '@instructure/ui-elements'

const navigateToLogin = () => {
  window.location.assign('/login')
}

function LoginActionPrompt(props) {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <Flex.Item>
        <View margin="medium" as="div">
          <img alt={I18n.t('Submission Locked Image')} src={lockedSVG} />
        </View>
      </Flex.Item>
      <Flex.Item>
        <Text margin="small" size="x-large">
          {I18n.t('Submission Locked')}
        </Text>
      </Flex.Item>
      <Flex.Item>
        <Text margin="small" size="medium">
          {props.nonAcceptedEnrollment
            ? I18n.t('Accept course invitation to participate in this assignment')
            : I18n.t('Log in to submit')}
        </Text>
      </Flex.Item>
      <Flex.Item>
        <View margin="medium" as="div">
          {props.nonAcceptedEnrollment ? (
            <a
              href={`/courses/${ENV.COURSE_ID}/enrollment_invitation?accept=true`}
              className="Button"
              data-method="POST"
              data-url={`/courses/${ENV.COURSE_ID}/enrollment_invitation?accept=true`}
            >
              {I18n.t('Accept course invitation')}
            </a>
          ) : (
            <Button variant="primary" onClick={navigateToLogin}>
              {I18n.t('Log in')}
            </Button>
          )}
        </View>
      </Flex.Item>
    </Flex>
  )
}

LoginActionPrompt.propTypes = {
  nonAcceptedEnrollment: bool
}

export default LoginActionPrompt
