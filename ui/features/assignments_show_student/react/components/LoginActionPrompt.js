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

import {bool, string} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import lockedSVG from '../../images/Locked1.svg'
import React from 'react'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('assignments_2_login_action_prompt')

const navigateToLogin = () => {
  window.location.assign('/login')
}

function LoginActionText(props) {
  let text

  if (props.enrollmentState === 'accepted') {
    text = I18n.t('Course has not started yet')
  } else if (props.nonAcceptedEnrollment) {
    text = I18n.t('Accept course invitation to participate in this assignment')
  } else {
    text = I18n.t('Log in to submit')
  }

  return (
    <Text margin="small" size="medium" data-testid="login-action-text">
      {text}
    </Text>
  )
}

function LoginActionButton(props) {
  if (props.enrollmentState === 'accepted') {
    return null
  }

  if (props.nonAcceptedEnrollment) {
    return (
      <a
        href={`/courses/${ENV.COURSE_ID}/enrollment_invitation?accept=true`}
        className="Button"
        data-method="POST"
        data-url={`/courses/${ENV.COURSE_ID}/enrollment_invitation?accept=true`}
        data-testid="login-action-button"
      >
        {I18n.t('Accept course invitation')}
      </a>
    )
  }

  return (
    <Button color="primary" onClick={navigateToLogin} data-testid="login-action-button">
      {I18n.t('Log in')}
    </Button>
  )
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
        <LoginActionText {...props} />
      </Flex.Item>
      <Flex.Item>
        <View margin="medium" as="div">
          <LoginActionButton {...props} />
        </View>
      </Flex.Item>
    </Flex>
  )
}

LoginActionPrompt.propTypes = {
  nonAcceptedEnrollment: bool,
  enrollmentState: string,
}

LoginActionPrompt.defaultProps = {
  enrollmentState: null,
}

export default LoginActionPrompt
