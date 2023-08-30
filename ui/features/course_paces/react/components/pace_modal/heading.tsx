// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {connect} from 'react-redux'

import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {CoursePace, PaceContext, Section, StoreState} from '../../types'
import {Text} from '@instructure/ui-text'
import {IconUserSolid} from '@instructure/ui-icons'
import {getBlueprintLocked} from '../../reducers/ui'
import Settings from '../header/settings/settings'
import BlueprintLock from '../header/blueprint_lock'

const I18n = useI18nScope('course_paces_modal')

interface Props {
  readonly coursePace: CoursePace
  readonly contextName: string
  readonly enrolledSection: Section
  readonly paceContext: PaceContext
}

interface StoreProps {
  readonly blueprintLocked: boolean | undefined
}

const PaceModalHeading = ({
  coursePace,
  contextName,
  paceContext,
  enrolledSection,
  blueprintLocked,
}: Props & StoreProps) => {
  const renderPaceInfo = () => {
    if (['Section', 'Course'].includes(coursePace.context_type)) {
      return (
        <>
          <Text>
            {coursePace.context_type === 'Course'
              ? I18n.t('Students enrolled in this course')
              : I18n.t('Students enrolled in this section')}
          </Text>
          <Text as="div" weight="bold">
            {paceContext?.associated_student_count}
          </Text>
        </>
      )
    }
    if (coursePace.context_type === 'Enrollment') {
      return <Text as="div">{paceContext.name}</Text>
    }
    return null
  }

  const getPaceName = () => {
    if (['Section', 'Course'].includes(coursePace.context_type)) return contextName
    return enrolledSection.name
  }

  const getPaceTitle = () => {
    switch (coursePace.context_type) {
      case 'Section':
        return I18n.t('Section Pace')
      case 'Enrollment':
        return I18n.t('Student Pace')
      default:
        return I18n.t('Default Course Pace')
    }
  }

  const renderDetails = () => {
    return (
      <>
        <Text tabIndex={0} data-testid="pace-type" as="div" size="medium" weight="bold">
          {getPaceTitle()}
        </Text>
        <Text data-testid="section-name" as="div" size="x-large" weight="bold">
          {getPaceName()}
        </Text>
        <Flex as="div" margin="medium none">
          <IconUserSolid size="medium" />
          <View data-testid="pace-info" as="div" margin="none small">
            {renderPaceInfo()}
          </View>
        </Flex>
      </>
    )
  }

  return (
    <Flex as="section" justifyItems="space-between">
      <Flex.Item>{renderDetails()}</Flex.Item>
      <Flex.Item margin="none none auto none">
        <Settings isBlueprintLocked={blueprintLocked} margin="0 0 0 small" />
        <BlueprintLock newPace={!coursePace.id} bannerSelector=".pace-redesign-inner-modal" />
      </Flex.Item>
    </Flex>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    blueprintLocked: getBlueprintLocked(state),
  }
}

export default connect(mapStateToProps)(PaceModalHeading)
