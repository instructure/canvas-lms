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

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

interface DispatchProps {
  readonly setSelectedPaceContext: typeof actions.setSelectedPaceContext
}

interface PassedProps {
  readonly responsiveSize: ResponsiveSizes
}

export const CoursePaceEmpty: React.FC<DispatchProps & PassedProps> = ({
  setSelectedPaceContext,
  responsiveSize,
}) => {
  return (
    <View>
      <Flex
        wrap={responsiveSize == 'large' ? undefined : 'wrap'}
        alignItems="end"
        justifyItems={responsiveSize == 'large' ? 'start' : 'center'}
        margin="0 0 medium 0"
      >
        <FlexItem padding="medium 0 0 0" width="100%" maxWidth="362px" shouldShrink={true}>
          <View
            as="div"
            textAlign={responsiveSize == 'large' ? 'start' : 'center'}
            className="course-paces-panda"
            padding="0 0 medium 0"
          >
            <img src={PandaShowingPaces} alt="" />
          </View>
          <Flex alignItems="start">
            <FlexItem padding="0 xx-small">
              <Text weight="bold">1.</Text>
            </FlexItem>
            <FlexItem>
              <Text as="div" weight="bold">
                {I18n.t('Create a Default Course Pace')}
              </Text>
              <Text>
                {I18n.t(
                  'Get started with configuring the course material due dates for the overall course'
                )}
              </Text>
            </FlexItem>
          </Flex>
        </FlexItem>

        {responsiveSize == 'large' ? (
          <FlexItem margin="0 large small large">
            <IconArrowEndSolid size="small" />
          </FlexItem>
        ) : null}

        <FlexItem padding="medium 0 0 0" width="100%" maxWidth="362px" shouldShrink={true}>
          <View
            as="div"
            textAlign={responsiveSize == 'large' ? 'start' : 'center'}
            padding="0 0 medium 0"
          >
            <img src={PandaUsingPaces} alt="" />
          </View>
          <Flex alignItems="start">
            <FlexItem padding="0 xx-small">
              <Text weight="bold">2.</Text>
            </FlexItem>
            <FlexItem>
              <Text as="div" weight="bold">
                {I18n.t('Customize Sections and Individual Student Paces')}
              </Text>
              <Text>
                {I18n.t(
                  'Then adjust Sections and Students pacing individually for a personalized schedule'
                )}
              </Text>
            </FlexItem>
          </Flex>
        </FlexItem>
      </Flex>
      <Button
        color="primary"
        margin="small 0"
        size="large"
        display={responsiveSize == 'large' ? 'inline-block' : 'block'}
        onClick={() => {
          setSelectedPaceContext('Course', window.ENV.COURSE_ID)
        }}
      >
        {I18n.t('Get Started')}
      </Button>
      <Text
        color="secondary"
        as="div"
        dangerouslySetInnerHTML={{
          __html:
            '*' +
            I18n.t(
              'Please note once a Course Pace is set up, all existing assignment,' +
                ' quizzes, discussions due dates will be controlled by Course Pacing. ' +
                'You can read more details in the *Course Pacing User Group*.',
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
