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
import {View} from '@instructure/ui-layout'
import {Button} from '@instructure/ui-buttons'
import {List, Text} from '@instructure/ui-elements'
import {asJson, defaultFetchOptions} from '@instructure/js-utils'
import splitAssetString from 'compiled/str/splitAssetString'
import {
  IconHomeLine,
  IconAnnouncementLine,
  IconAssignmentLine,
  IconDiscussionLine,
  IconDocumentLine,
  IconGradebookLine,
  IconUserLine,
  IconFolderLine,
  IconOutcomesLine,
  IconQuizLine,
  IconModuleLine,
  IconSyllabusLine,
  IconSettingsLine,
  IconVideoCameraLine,
  IconLtiLine,
  IconEmptyLine,
  IconCoursesLine,
  IconGroupLine,
  IconStatsLine,
  IconRubricLine,
  IconBankLine,
  IconEssayLine,
  IconMaterialsRequiredLine,
  IconLockLine,
  IconStandardsLine,
  IconAnnotateLine,
  IconPostToSisLine,
  IconAnalyticsLine,
  IconAdminLine,
  IconHourGlassLine
} from '@instructure/ui-icons'

const icons = {
  home: IconHomeLine,
  announcements: IconAnnouncementLine,
  assignments: IconAssignmentLine,
  discussions: IconDiscussionLine,
  pages: IconDocumentLine,
  grades: IconGradebookLine,
  people: IconGroupLine,
  files: IconFolderLine,
  outcomes: IconOutcomesLine,
  quizzes: IconQuizLine,
  modules: IconModuleLine,
  syllabus: IconSyllabusLine,
  settings: IconSettingsLine,
  profile_settings: IconSettingsLine,
  conferences: IconVideoCameraLine,
  courses: IconCoursesLine,
  users: IconGroupLine,
  statistics: IconStatsLine,
  permissions: IconEmptyLine,
  rubrics: IconRubricLine,
  grading_standards: IconGradebookLine,
  question_banks: IconBankLine,
  faculty_journal: IconEssayLine,
  terms: IconAnnotateLine,
  authentication: IconLockLine,
  brand_configs: IconMaterialsRequiredLine,
  developer_keys: IconStandardsLine,
  notifications: IconAnnouncementLine,
  profile: IconUserLine,
  sis_import: IconPostToSisLine,
  analytics_plugin: IconAnalyticsLine,
  analytics: IconAnalyticsLine,
  admin_tools: IconAdminLine,
  plugins: IconLtiLine,
  jobs: IconHourGlassLine
}

const getIcon = tab => icons[tab.id] || (tab.type === 'external' ? IconLtiLine : IconEmptyLine)

function ContextTab({tab, active_context_tab}) {
  const Icon = getIcon(tab)
  return (
    <List.Item>
      <View display="block" borderWidth="0 0 small 0" padding="x-small 0">
        <Button icon={Icon} variant="link" href={tab.html_url} fluidWidth>
          {active_context_tab === tab.id ? <Text weight="bold">{tab.label}</Text> : tab.label}
        </Button>
      </View>
    </List.Item>
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
    contextId: string.isRequired
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
    const url = `/api/v1/${encodeURIComponent(this.props.contextType)}/${encodeURIComponent(
      this.props.contextId
    )}/tabs`
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
