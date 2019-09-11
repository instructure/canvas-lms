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
import {string, shape, node} from 'prop-types'
import View from '@instructure/ui-layout/lib/components/View'
import Button from '@instructure/ui-buttons/lib/components/Button'
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import Text from '@instructure/ui-elements/lib/components/Text'
import {asJson, defaultFetchOptions} from '@instructure/js-utils'

import splitAssetString from 'compiled/str/splitAssetString'

import IconHome from '@instructure/ui-icons/lib/Line/IconHome'
import IconAnnouncement from '@instructure/ui-icons/lib/Line/IconAnnouncement'
import IconAssignment from '@instructure/ui-icons/lib/Line/IconAssignment'
import IconDiscussion from '@instructure/ui-icons/lib/Line/IconDiscussion'
import IconDocument from '@instructure/ui-icons/lib/Line/IconDocument'
import IconGradebook from '@instructure/ui-icons/lib/Line/IconGradebook'
import IconUser from '@instructure/ui-icons/lib/Line/IconUser'
import IconFolder from '@instructure/ui-icons/lib/Line/IconFolder'
import IconOutcomes from '@instructure/ui-icons/lib/Line/IconOutcomes'
import IconQuiz from '@instructure/ui-icons/lib/Line/IconQuiz'
import IconModule from '@instructure/ui-icons/lib/Line/IconModule'
import IconSyllabus from '@instructure/ui-icons/lib/Line/IconSyllabus'
import IconSettings from '@instructure/ui-icons/lib/Line/IconSettings'
import IconVideoCamera from '@instructure/ui-icons/lib/Line/IconVideoCamera'
import IconLti from '@instructure/ui-icons/lib/Line/IconLti'
import IconEmpty from '@instructure/ui-icons/lib/Line/IconEmpty'
import IconCourses from '@instructure/ui-icons/lib/Line/IconCourses'
import IconGroup from '@instructure/ui-icons/lib/Line/IconGroup'
import IconStats from '@instructure/ui-icons/lib/Line/IconStats'
import IconRubric from '@instructure/ui-icons/lib/Line/IconRubric'
import IconBank from '@instructure/ui-icons/lib/Line/IconBank'
import IconEssay from '@instructure/ui-icons/lib/Line/IconEssay'
import IconMaterialsRequired from '@instructure/ui-icons/lib/Line/IconMaterialsRequired'
import IconLock from '@instructure/ui-icons/lib/Line/IconLock'
import IconStandards from '@instructure/ui-icons/lib/Line/IconStandards'
import IconAnnotate from '@instructure/ui-icons/lib/Line/IconAnnotate'
import IconPostToSis from '@instructure/ui-icons/lib/Line/IconPostToSis'
import IconAnalytics from '@instructure/ui-icons/lib/Line/IconAnalytics'
import IconAdmin from '@instructure/ui-icons/lib/Line/IconAdmin'
import IconHourGlass from '@instructure/ui-icons/lib/Line/IconHourGlass'

const icons = {
  home: IconHome,
  announcements: IconAnnouncement,
  assignments: IconAssignment,
  discussions: IconDiscussion,
  pages: IconDocument,
  grades: IconGradebook,
  people: IconGroup,
  files: IconFolder,
  outcomes: IconOutcomes,
  quizzes: IconQuiz,
  modules: IconModule,
  syllabus: IconSyllabus,
  settings: IconSettings,
  profile_settings: IconSettings,
  conferences: IconVideoCamera,
  courses: IconCourses,
  users: IconGroup,
  statistics: IconStats,
  permissions: IconEmpty,
  rubrics: IconRubric,
  grading_standards: IconGradebook,
  question_banks: IconBank,
  faculty_journal: IconEssay,
  terms: IconAnnotate,
  authentication: IconLock,
  brand_configs: IconMaterialsRequired,
  developer_keys: IconStandards,
  notifications: IconAnnouncement,
  profile: IconUser,
  sis_import: IconPostToSis,
  analytics_plugin: IconAnalytics,
  analytics: IconAnalytics,
  admin_tools: IconAdmin,
  plugins: IconLti,
  jobs: IconHourGlass
}

const getIcon = tab => icons[tab.id] || (tab.type === 'external' ? IconLti : IconEmpty)

function ContextTab({tab, active_context_tab}) {
  const Icon = getIcon(tab)
  return (
    <ListItem>
      <View display="block" borderWidth="0 0 small 0" padding="x-small 0">
        <Button icon={Icon} variant="link" href={tab.html_url} fluidWidth>
          {active_context_tab === tab.id ? (
            <Text weight="bold">{tab.label}</Text>
          ) : (
            tab.label
          )}
        </Button>
      </View>
    </ListItem>
  )
}
ContextTab.propTypes = {
  active_context_tab: string,
  tab: shape({
    html_url: string.isRequired,
    label: string.isRequired,
    id: string.isRequired
  }).isRequired
}
ContextTab.defaultProps = {
  active_context_tab: ENV && ENV.active_context_tab
}

const [contextType, contextId] = splitAssetString(ENV.context_asset_string)

export default class MobileContextMenu extends React.Component {
  static propTypes = {
    spinner: node.isRequired,
    contextType: string.isRequired,
    contextId: string.isRequired,
  }

  static defaultProps = {
    contextType,
    contextId
  }

  state = {
    tabs: [],
    tabsHaveLoaded: false
  }

  componentWillMount() {
    this.fetchTabs()
  }

  async fetchTabs() {
    const url = `/api/v1/${encodeURIComponent(this.props.contextType)}/${encodeURIComponent(this.props.contextId)}/tabs`
    const storedTabs = sessionStorage.getItem(url)
    if (storedTabs) {
      this.setState({tabs: JSON.parse(storedTabs), tabsHaveLoaded: true})
    }
    const tabs = await asJson(fetch(url, defaultFetchOptions))
    this.setState({tabs, tabsHaveLoaded: true})
    sessionStorage.setItem(url, JSON.stringify(tabs))
  }

  render() {
    return this.state.tabsHaveLoaded ? (
      <List variant="unstyled">
        {this.state.tabs.map(tab => (
          <ContextTab key={tab.id} tab={tab} />
        ))}
      </List>
    ) : (
      this.props.spinner
    )
  }
}
