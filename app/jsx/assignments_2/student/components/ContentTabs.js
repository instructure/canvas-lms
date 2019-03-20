/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import ClosedDiscussionSVG from '../SVG/ClosedDiscussions.svg'
import ContentUploadTab from './ContentUploadTab'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '../../shared/LoadingIndicator'
import React, {lazy, Suspense} from 'react'
import {StudentAssignmentShape} from '../assignmentData'
import SVGWithTextPlaceholder from '../../shared/SVGWithTextPlaceholder'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import Text from '@instructure/ui-elements/lib/components/Text'

const Comments = lazy(() =>
  import('./Comments').then(result => (result.default ? result : {default: result}))
)

ContentTabs.propTypes = {
  assignment: StudentAssignmentShape
}

function ContentTabs(props) {
  return (
    <div data-testid="assignment-2-student-content-tabs">
      <TabList defaultSelectedIndex={0} variant="minimal">
        <TabPanel title={I18n.t('Upload')}>
          <ContentUploadTab />
        </TabPanel>
        <TabPanel title={I18n.t('Comments')}>
          {!props.assignment.muted ? (
            <Suspense fallback={<LoadingIndicator />}>
              <Comments assignment={props.assignment} />
            </Suspense>
          ) : (
            <SVGWithTextPlaceholder
              text={I18n.t(
                'You may not see all comments right now because the assignment is currently being graded.'
              )}
              url={ClosedDiscussionSVG}
            />
          )}
        </TabPanel>
        <TabPanel title={I18n.t('Rubric')}>
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <FlexItem>
              <Text>`TODO: Input Rubric Content Here...`</Text>
            </FlexItem>
          </Flex>
        </TabPanel>
      </TabList>
    </div>
  )
}

export default React.memo(ContentTabs)
