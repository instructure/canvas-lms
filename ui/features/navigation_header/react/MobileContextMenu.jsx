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

import React, {useState, useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {string, node} from 'prop-types'
import {Text} from '@instructure/ui-text'
import {Grid} from '@instructure/ui-grid'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import useFetchApi from '@canvas/use-fetch-api-hook'
import splitAssetString from '@canvas/util/splitAssetString'
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
  IconHourGlassLine,
  IconOffLine,
} from '@instructure/ui-icons'

import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('MobileNavigation')

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
  jobs: IconHourGlassLine,
}

const getIcon = tab => icons[tab.id] || (tab.type === 'external' ? IconLtiLine : IconEmptyLine)

function srText(tab) {
  if (tab.hidden) return I18n.t('Disabled. Not visible to students.')
  if (tab.unused) return I18n.t('No content. Not visible to students.')
  return ''
}

export default function MobileContextMenu({spinner, contextType, contextId}) {
  const [tabs, setTabs] = useState(null)
  const [defaultContextType, defaultContextId] = splitAssetString(ENV.context_asset_string)

  useFetchApi({
    path: `/api/v1/${encodeURIComponent(contextType || defaultContextType)}/${encodeURIComponent(
      contextId || defaultContextId
    )}/tabs`,
    success: useCallback(r => setTabs(r), []),
  })

  if (tabs === null) return spinner

  const tabsToDisplay = tabs.filter(t => !(t.type === 'external' && t.hidden))

  return (
    <Grid vAlign="middle" rowSpacing="none">
      {tabsToDisplay.map(tab => {
        const Icon = getIcon(tab)
        const isTabOff = tab.hidden || tab.unused
        const isCurrentTab = ENV?.active_context_tab === tab.id
        return (
          <Grid.Row key={tab.id}>
            <Grid.Col width="auto">
              <Link renderIcon={Icon} href={tab.html_url} isWithinText={false}>
                <Text weight={isCurrentTab ? 'bold' : 'normal'}>{tab.label}</Text>
                {isTabOff && <ScreenReaderContent>{'- ' + srText(tab)}</ScreenReaderContent>}
              </Link>
            </Grid.Col>
            <Grid.Col>{isTabOff && <IconOffLine />}</Grid.Col>
          </Grid.Row>
        )
      })}
    </Grid>
  )
}

MobileContextMenu.propTypes = {
  spinner: node.isRequired,
  contextType: string,
  contextId: string,
}
