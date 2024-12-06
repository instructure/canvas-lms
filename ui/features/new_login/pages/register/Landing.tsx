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
import {ActionPrompt, Card, ROUTES} from '../../shared'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Responsive} from '@instructure/ui-responsive'
import {canvas} from '@instructure/ui-theme-tokens'
import {type ViewOwnProps} from '@instructure/ui-view'
import {useNavigate} from 'react-router-dom'
import {useNewLogin} from '../../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

import iconTeacher from '../../assets/images/teacher.svg'
import iconStudent from '../../assets/images/student.svg'
import iconParent from '../../assets/images/parent.svg'

const I18n = useI18nScope('new_login')

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
                  icon={iconTeacher}
                  text={I18n.t('Teacher')}
                  href={ROUTES.REGISTER_TEACHER}
                  onClick={handleNavigate(ROUTES.REGISTER_TEACHER)}
                  compact={!isTabletOrLarger}
                />
              </Flex.Item>

              <Flex.Item shouldGrow={true}>
                <Card
                  icon={iconStudent}
                  text={I18n.t('Student')}
                  href={ROUTES.REGISTER_STUDENT}
                  onClick={handleNavigate(ROUTES.REGISTER_STUDENT)}
                  compact={!isTabletOrLarger}
                />
              </Flex.Item>

              <Flex.Item shouldGrow={true}>
                <Card
                  icon={iconParent}
                  text={I18n.t('Parent')}
                  href={ROUTES.REGISTER_PARENT}
                  onClick={handleNavigate(ROUTES.REGISTER_PARENT)}
                  compact={!isTabletOrLarger}
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
          {I18n.t('Create your account')}
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
