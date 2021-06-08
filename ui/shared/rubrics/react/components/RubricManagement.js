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

/* TODO: Remove when feature flag account_level_mastery_scales is enabled */

import React from 'react'
import ReactDOM from 'react-dom'
import _ from 'lodash'
import PropTypes from 'prop-types'
import I18n from 'i18n!RubricManagement'
import {TabList} from '@instructure/ui-tabs'
import ProficiencyTable from './ProficiencyTable'
import RubricPanel from './RubricPanel'

export default class RubricManagement extends React.Component {
  static propTypes = {
    accountId: PropTypes.string.isRequired
  }

  focusTab = _.memoize(ix => () => {
    ReactDOM.findDOMNode(this.tabList._tabs[ix]).focus()
  })

  render() {
    return (
      <TabList
        ref={tabList => {
          this.tabList = tabList
        }}
        defaultSelectedIndex={0}
      >
        <TabList.Panel title={I18n.t('Account Rubrics')}>
          <RubricPanel />
        </TabList.Panel>
        <TabList.Panel title={I18n.t('Learning Mastery')}>
          <ProficiencyTable focusTab={this.focusTab(1)} accountId={this.props.accountId} />
        </TabList.Panel>
      </TabList>
    )
  }
}
