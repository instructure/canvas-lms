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

import React from 'react'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import IconUpload from '@instructure/ui-icons/lib/Solid/IconUpload'
import IconComment from '@instructure/ui-icons/lib/Line/IconComment'
import IconRubric from '@instructure/ui-icons/lib/Line/IconRubric'
import Text from '@instructure/ui-elements/lib/components/Text'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import View from '@instructure/ui-layout/lib/components/View'

import {StudentAssignmentShape} from '../assignmentData'

ContentTabs.propTypes = {
  assignment: StudentAssignmentShape
}

function ContentTabs(props) {
  return (
    <div data-test-id="assignment-2-student-content-tabs">
      <TabList defaultSelectedIndex={0} variant="minimal">
        <TabPanel
          title={
            <Flex as="header" alignItems="center" justifyItems="center" direction="column">
              <FlexItem>
                <IconUpload size="small" />
                <View margin="small">
                  <Text>Upload</Text>
                </View>
              </FlexItem>
            </Flex>
          }
        >
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <FlexItem>
              <Text data-test-id="assignment-2-student-content-tabs-test-text">
                `TODO: Input Upload Content Here...`
              </Text>
            </FlexItem>
          </Flex>
        </TabPanel>
        <TabPanel
          title={
            <Flex as="header" alignItems="center" justifyItems="center" direction="column">
              <FlexItem>
                <IconComment size="small" />
                <View margin="small">
                  <Text>Comments</Text>
                </View>
              </FlexItem>
            </Flex>
          }
        >
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <FlexItem>
              <Text>
                {`TODO: Input Comments Content Here... ${props.assignment &&
                  props.assignment.description}`}
              </Text>
            </FlexItem>
          </Flex>
        </TabPanel>
        <TabPanel
          title={
            <Flex as="header" alignItems="center" justifyItems="center" direction="column">
              <FlexItem>
                <IconRubric size="small" />
                <View margin="small">
                  <Text>Rubric</Text>
                </View>
              </FlexItem>
            </Flex>
          }
        >
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
