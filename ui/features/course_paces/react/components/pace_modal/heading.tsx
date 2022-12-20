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

import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {CoursePace, PaceContext, Section} from '../../types'
import {Text} from '@instructure/ui-text'
import {IconUserSolid} from '@instructure/ui-icons'
import Settings from '../header/settings/settings'
import BlueprintLock from '../header/blueprint_lock'

const I18n = useI18nScope('course_paces_modal')

interface Props {
  readonly coursePace: CoursePace
  readonly contextName: string
  readonly enrolledSection: Section
  readonly isBlueprintLocked: boolean
  readonly paceContext: PaceContext
  readonly setIsBlueprintLocked: (newValue: boolean) => void
}

const {Item: FlexItem} = Flex as any

const PaceModalHeading: React.FC<Props> = ({
  coursePace,
  contextName,
  isBlueprintLocked,
  paceContext,
  setIsBlueprintLocked,
  enrolledSection,
}) => {
  const renderPaceInfo = () => {
    if (['Section', 'Course'].includes(coursePace.context_type)) {
      return (
        <>
          <Text>{I18n.t('Students')}</Text>
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
      <FlexItem>{renderDetails()}</FlexItem>
      <FlexItem margin="none none auto none">
        <Settings
          isBlueprintLocked={isBlueprintLocked && coursePace.context_type === 'Course'}
          margin="0 0 0 small"
        />
        <BlueprintLock
          newPace={!coursePace.id}
          contextIsCoursePace={coursePace.context_type === 'Course'}
          setIsBlueprintLocked={setIsBlueprintLocked}
          bannerSelector=".pace-redesign-inner-modal"
        />
      </FlexItem>
    </Flex>
  )
}
export default PaceModalHeading
