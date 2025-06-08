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

import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation} from '@canvas/util/globalUtils'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React from 'react'
import lockedSVG from '../../images/Locked1.svg'

const I18n = createI18nScope('assignments_2_login_action_prompt')

const navigateToLogin = () => {
  assignLocation('/login')
}

interface LoginActionTextProps {
  enrollmentState: string | null
  nonAcceptedEnrollment?: boolean
}

function LoginActionText(props: LoginActionTextProps) {
  let text

  if (props.enrollmentState === 'accepted') {
    text = I18n.t('Course has not started yet')
  } else if (props.nonAcceptedEnrollment) {
    text = I18n.t('Accept course invitation to participate in this assignment')
  } else {
    text = I18n.t('Log in to submit')
  }

  return (
    <View margin="small">
      <Text size="medium" data-testid="login-action-text">
        {text}
      </Text>
    </View>
  )
}

interface LoginActionButtonProps {
  enrollmentState: string | null
  nonAcceptedEnrollment?: boolean
}

function LoginActionButton(props: LoginActionButtonProps) {
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

interface LoginActionPromptProps {
  nonAcceptedEnrollment?: boolean
  enrollmentState: string | null
}

function LoginActionPrompt(props: LoginActionPromptProps) {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <Flex.Item>
        <View margin="medium" as="div">
          <img alt={I18n.t('Submission Locked Image')} src={lockedSVG} />
        </View>
      </Flex.Item>
      <Flex.Item>
        <View margin="small">
          <Text size="x-large">{I18n.t('Submission Locked')}</Text>
        </View>
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

export default LoginActionPrompt
