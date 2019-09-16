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

import {Assignment} from '../graphqlData/Assignment'
import {Flex} from '@instructure/ui-layout'
import I18n from 'i18n!assignments_2_logged_out_tabs'
import LoginActionPrompt from './LoginActionPrompt'
import React, {useState} from 'react'
import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-elements'

LoggedOutTabs.propTypes = {
  assignment: Assignment.shape
}

function LoggedOutTabs(props) {
  const {selectedTabIndex, setSelectedTabIndex} = useState(0)

  function handleTabChange(event, {index}) {
    setSelectedTabIndex(index)
  }

  return (
    <div>
      <Tabs onRequestTabChange={handleTabChange} variant="default">
        {/* Always attempt 1, cause there is no submission for logged out users */}
        <Tabs.Panel renderTitle={I18n.t('Attempt 1')} selected={selectedTabIndex === 0}>
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <Flex.Item>
              <LoginActionPrompt />
            </Flex.Item>
          </Flex>
        </Tabs.Panel>

        <Tabs.Panel renderTitle={I18n.t('Rubric')} selected={selectedTabIndex === 1}>
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <Flex.Item>
              <Text>{`TODO: Input Rubric Content Here... ${props.assignment.title}`}</Text>
            </Flex.Item>
          </Flex>
        </Tabs.Panel>
      </Tabs>
    </div>
  )
}

export default React.memo(LoggedOutTabs)
