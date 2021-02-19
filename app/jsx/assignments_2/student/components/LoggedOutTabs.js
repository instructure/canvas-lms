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
import {bool} from 'prop-types'
import {Flex} from '@instructure/ui-layout'
import I18n from 'i18n!assignments_2_logged_out_tabs'
import LoginActionPrompt from './LoginActionPrompt'
import React, {useState} from 'react'
import RubricTab from './RubricTab'
import {Tabs} from '@instructure/ui-tabs'

LoggedOutTabs.propTypes = {
  assignment: Assignment.shape.isRequired,
  nonAcceptedEnrollment: bool
}

export default function LoggedOutTabs(props) {
  const [selectedTabIndex, setSelectedTabIndex] = useState(0)

  return (
    <div>
      <Tabs onRequestTabChange={(event, {index}) => setSelectedTabIndex(index)} variant="default">
        {/* Always attempt 1, cause there is no submission for logged out users */}
        <Tabs.Panel renderTitle={I18n.t('Attempt 1')} selected={selectedTabIndex === 0}>
          <Flex as="header" alignItems="center" justifyItems="center" direction="column">
            <Flex.Item>
              <LoginActionPrompt nonAcceptedEnrollment={props.nonAcceptedEnrollment} />
            </Flex.Item>
          </Flex>
        </Tabs.Panel>

        {props.assignment.rubric && (
          <Tabs.Panel
            key="rubrics-tab"
            renderTitle={I18n.t('Rubric')}
            selected={selectedTabIndex === 2}
          >
            <RubricTab rubric={props.assignment.rubric} />
          </Tabs.Panel>
        )}
      </Tabs>
    </div>
  )
}
