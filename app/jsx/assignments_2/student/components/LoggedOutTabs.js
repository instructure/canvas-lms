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

import React from 'react'
import I18n from 'i18n!assignments_2_logged_out_tabs'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import Text from '@instructure/ui-elements/lib/components/Text'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import {StudentAssignmentShape} from '../assignmentData'
import LoginActionPrompt from './LoginActionPrompt'

LoggedOutTabs.propTypes = {
  assignment: StudentAssignmentShape
}

function LoggedOutTabs(props) {
  return (
    <div>
      <TabList defaultSelectedIndex={0} variant="minimal">
        <TabPanel title={I18n.t('Attempt 1')}>
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <FlexItem>
              <LoginActionPrompt />
            </FlexItem>
          </Flex>
        </TabPanel>

        <TabPanel title={I18n.t('Rubric')}>
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <FlexItem>
              <Text>{`TODO: Input Rubric Content Here... ${props.assignment.title}`}</Text>
            </FlexItem>
          </Flex>
        </TabPanel>
      </TabList>
    </div>
  )
}

export default React.memo(LoggedOutTabs)
