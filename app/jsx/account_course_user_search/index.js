/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import ReactTabs from 'react-tabs'
import permissionFilter from 'jsx/shared/helpers/permissionFilter'
import CoursesStore from './CoursesStore'
import TermsStore from './TermsStore'
import AccountsTreeStore from './AccountsTreeStore'
import UsersStore from './UsersStore'

const { Tab, Tabs, TabList, TabPanel } = ReactTabs
const { string, bool, shape } = PropTypes

const stores = [CoursesStore, TermsStore, AccountsTreeStore, UsersStore]

  class AccountCourseUserSearch extends React.Component {
    static propTypes = {
      accountId: string.isRequired,
      permissions: shape({
        theme_editor: bool.isRequired,
        analytics: bool.isRequired
      }).isRequired
    }

    componentWillMount () {
      stores.forEach((s) => {
        s.reset({ accountId: this.props.accountId });
      });
    }

    render () {
      const { timezones, permissions, store } = this.props

      const tabList = store.getState().tabList;
      const tabs = permissionFilter(tabList.tabs, permissions);

      const headers = tabs.map((tab, index) => {
        return (
          <Tab key={index}>
            <a href={tabList.basePath + tab.path} title={tab.title}>{tab.title}</a>
          </Tab>
        );
      });

      const panels = tabs.map((tab, index) => {
        const Pane = tab.pane;
        return (
          <TabPanel key={index}>
            <Pane {...this.props} />
          </TabPanel>
        );
      });

      return (
        <Tabs selectedIndex={tabList.selected}>
          <TabList>
            {headers}
          </TabList>
          {panels}
        </Tabs>
      );
    }
  }

export default AccountCourseUserSearch
