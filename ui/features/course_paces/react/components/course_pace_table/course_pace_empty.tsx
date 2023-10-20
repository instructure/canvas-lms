// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconArrowEndSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {ResponsiveSizes} from '../../types'
import {actions} from '../../actions/ui'
import PandaShowingPaces from '../../../images/PandaShowingPaces.svg'
import PandaUsingPaces from '../../../images/PandaUsingPaces.svg'

const I18n = useI18nScope('course_paces_empty_state')

interface DispatchProps {
  readonly setSelectedPaceContext: typeof actions.setSelectedPaceContext
}

interface PassedProps {
  readonly responsiveSize: ResponsiveSizes
}

export const CoursePaceEmpty = ({
  setSelectedPaceContext,
  responsiveSize,
}: DispatchProps & PassedProps) => {
  return (
    <View>
      <Flex
        wrap={responsiveSize !== 'small' ? undefined : 'wrap'}
        alignItems="end"
        justifyItems={responsiveSize !== 'small' ? 'start' : 'center'}
        margin="0 0 medium 0"
      >
        <Flex.Item padding="medium 0 0 0" width="100%" maxWidth="362px" shouldShrink={true}>
          <View
            as="div"
            textAlign={responsiveSize !== 'small' ? 'start' : 'center'}
            className="course-paces-panda"
            padding="0 0 medium 0"
          >
            <img src={PandaShowingPaces} alt="" />
          </View>
          <Flex alignItems="start">
            <Flex.Item padding="0 xx-small">
              <Text weight="bold">1.</Text>
            </Flex.Item>
            <Flex.Item>
              <Text as="div" weight="bold">
                {I18n.t('Create a Course Pace')}
              </Text>
              <Text>
                {I18n.t(
                  'Get started by creating a course pace that will serve as the default pace for all sections and students in the course.'
                )}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        {responsiveSize !== 'small' ? (
          <Flex.Item margin="0 large small large">
            <IconArrowEndSolid size="small" />
          </Flex.Item>
        ) : null}

        <Flex.Item padding="medium 0 0 0" width="100%" maxWidth="362px" shouldShrink={true}>
          <View
            as="div"
            textAlign={responsiveSize !== 'small' ? 'start' : 'center'}
            padding="0 0 medium 0"
          >
            <img src={PandaUsingPaces} alt="" />
          </View>
          <Flex alignItems="start">
            <Flex.Item padding="0 xx-small">
              <Text weight="bold">2.</Text>
            </Flex.Item>
            <Flex.Item>
              <Text as="div" weight="bold">
                {I18n.t('Customize Section and Student Paces')}
              </Text>
              <Text>
                {I18n.t(
                  'Next, adjust the paces for individual sections and/or students to further customize based on your needs (this step is optional).'
                )}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      <Button
        data-testid="get-started-button"
        color="primary"
        margin="small 0"
        size="large"
        display={responsiveSize !== 'small' ? 'inline-block' : 'block'}
        onClick={() => {
          setSelectedPaceContext('Course', window.ENV.COURSE_ID)
        }}
      >
        {I18n.t('Get Started')}
      </Button>
      <Text
        data-testid="course-pacing-more-info-link"
        color="secondary"
        as="div"
        dangerouslySetInnerHTML={{
          __html:
            '* ' +
            I18n.t(
              'Please note that once a Course Pace is saved, all due dates for existing assessments and learning materials will be controlled by Course Pacing. Learn more about Course Pacing in the *Course Pacing User Group*.',
              {
                wrappers: [
                  `<a target="_blank" href="https://community.canvaslms.com/t5/Course-Pacing-Feature-Preview/gh-p/course_pacing">$1</a>`,
                ],
              }
            ),
        }}
      />
    </View>
  )
}

export default connect(null, {setSelectedPaceContext: actions.setSelectedPaceContext})(
  CoursePaceEmpty
)
