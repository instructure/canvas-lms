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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Responsive} from '@instructure/ui-responsive'
import {canvas} from '@instructure/ui-themes'
import {type ViewOwnProps} from '@instructure/ui-view'
import React from 'react'
import {useNavigate} from 'react-router-dom'
import {useNewLogin} from '../../context'
import {ROUTES} from '../../routes/routes'
import {ActionPrompt, Card} from '../../shared'

import iconParent from '../../assets/images/parent.svg'
import iconStudent from '../../assets/images/student.svg'
import iconTeacher from '../../assets/images/teacher.svg'

const I18n = createI18nScope('new_login')

const Landing = () => {
  const navigate = useNavigate()
  const {isUiActionPending} = useNewLogin()

  const handleNavigate = (path: string) => (event: React.MouseEvent<ViewOwnProps>) => {
    event.preventDefault()
    if (!isUiActionPending) {
      navigate(path)
    }
  }

  const renderCards = () => {
    return (
      <Responsive
        match="media"
        query={{
          tablet: {minWidth: canvas.breakpoints.tablet}, // 768px
        }}
      >
        {(_props, matches) => {
          const isTabletOrLarger = matches?.includes('tablet')

          return (
            <Flex direction={isTabletOrLarger ? 'row' : 'column'} gap="small">
              <Flex.Item shouldGrow={true}>
                <Card
                  compact={!isTabletOrLarger}
                  href={ROUTES.REGISTER_TEACHER}
                  icon={iconTeacher}
                  label={I18n.t('Create Teacher Account')}
                  onClick={handleNavigate(ROUTES.REGISTER_TEACHER)}
                  testId="teacher-card-link"
                  text={I18n.t('Teacher')}
                />
              </Flex.Item>

              <Flex.Item shouldGrow={true}>
                <Card
                  compact={!isTabletOrLarger}
                  href={ROUTES.REGISTER_STUDENT}
                  icon={iconStudent}
                  label={I18n.t('Create Student Account')}
                  onClick={handleNavigate(ROUTES.REGISTER_STUDENT)}
                  testId="student-card-link"
                  text={I18n.t('Student')}
                />
              </Flex.Item>

              <Flex.Item shouldGrow={true}>
                <Card
                  compact={!isTabletOrLarger}
                  href={ROUTES.REGISTER_PARENT}
                  icon={iconParent}
                  label={I18n.t('Create Parent Account')}
                  onClick={handleNavigate(ROUTES.REGISTER_PARENT)}
                  testId="parent-card-link"
                  text={I18n.t('Parent')}
                />
              </Flex.Item>
            </Flex>
          )
        }}
      </Responsive>
    )
  }

  return (
    <Flex direction="column" gap="large">
      <Flex direction="column" gap="small">
        <Heading as="h1" level="h2">
          {I18n.t('Create Your Account')}
        </Heading>

        <Flex.Item overflowX="visible" overflowY="visible">
          <ActionPrompt variant="signIn" />
        </Flex.Item>
      </Flex>

      {renderCards()}
    </Flex>
  )
}

export default Landing
