/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import HomeTray from '../trays/HomeTray'
import ModulesTray from '../trays/ModulesTray'
import PagesTray from '../trays/PagesTray'
import AssignmentsTray from '../trays/AssignmentsTray'
import QuizzesTray from '../trays/QuizzesTray'
import SettingsTray from '../trays/SettingsTray'
import FilesTray from '../trays/FilesTray'
import PeopleTray from '../trays/PeopleTray'
import AnnouncementsTray from '../trays/AnnouncementsTray'
import GradesTray from '../trays/GradesTray'
import DiscussionsTray from '../trays/DiscussionsTray'
import SyllabusTray from '../trays/SyllabusTray'
import CollaborationsTray from '../trays/CollaborationsTray'
import ImportTray from '../trays/ImportTray'
import ConferencesTray from '../trays/ConferencesTray'
import OutcomesTray from '../trays/OutcomesTray'
import RubricsTray from '../trays/RubricsTray'
import ZoomTray from '../trays/ZoomTray'
import NewAnalyticsTray from '../trays/NewAnalyticsTray'

const I18n = useI18nScope('new_user_tutorials')

const generateObject = (component, label, pageName) => ({
  component,
  label,
  pageName,
})

const getProperTray = (path = window.location.pathname) => {
  if (path.includes('modules')) {
    return generateObject(ModulesTray, I18n.t('Modules Tutorial Tray'), 'modules')
  } else if (path.includes('pages')) {
    return generateObject(PagesTray, I18n.t('Pages Tutorial Tray'), 'pages')
  } else if (path.includes('syllabus')) {
    // syllabus must come before assignments (courses/#/assignments/syllabus)
    return generateObject(SyllabusTray, I18n.t('Syllabus Tutorial Tray'), 'syllabus')
  } else if (path.includes('assignments')) {
    return generateObject(AssignmentsTray, I18n.t('Assignments Tutorial Tray'), 'assignments')
  } else if (path.includes('quizzes')) {
    return generateObject(QuizzesTray, I18n.t('Quizzes Tutorial Tray'), 'quizzes')
  } else if (path.includes('settings')) {
    return generateObject(SettingsTray, I18n.t('Settings Tutorial Tray'), 'settings')
  } else if (path.includes('files')) {
    return generateObject(FilesTray, I18n.t('Files Tutorial Tray'), 'files')
  } else if (path.includes('users')) {
    return generateObject(PeopleTray, I18n.t('People Tutorial Tray'), 'people')
  } else if (path.includes('announcements')) {
    return generateObject(AnnouncementsTray, I18n.t('Announcements Tutorial Tray'), 'announcements')
  } else if (path.includes('gradebook')) {
    return generateObject(GradesTray, I18n.t('Gradebook Tutorial Tray'), 'grades')
  } else if (path.includes('discussion_topics')) {
    return generateObject(DiscussionsTray, I18n.t('Discussions Tutorial Tray'), 'discussions')
  } else if (path.includes('lti_collaborations') || path.includes('collaborations')) {
    return generateObject(
      CollaborationsTray,
      I18n.t('Collaborations Tutorial Tray'),
      'collaborations'
    )
  } else if (path.includes('content_migrations')) {
    return generateObject(ImportTray, I18n.t('Import Tutorial Tray'), 'collaborations')
  } else if (path.includes('conferences')) {
    return generateObject(ConferencesTray, I18n.t('Conferences Tutorial Tray'), 'conferences')
  } else if (path.includes('outcomes')) {
    return generateObject(OutcomesTray, I18n.t('Outcomes Tutorial Tray'), 'outcomes')
  } else if (path.includes('rubrics')) {
    return generateObject(RubricsTray, I18n.t('Rubrics Tutorial Tray'), 'rubrics')
  }
  if (path.includes('external_tools')) {
    // We are in an LTI App. Check the resource URL
    if (window.ENV.LTI_LAUNCH_RESOURCE_URL === 'https://applications.zoom.us/lti/rich') {
      // Zoom Video Conferencing
      return generateObject(ZoomTray, I18n.t('Zoom Tutorial Tray'), 'zoom')
    }
    if (window.ENV.LTI_LAUNCH_RESOURCE_URL.includes('canvas-analytics')) {
      return generateObject(
        NewAnalyticsTray,
        I18n.t('New Analytics Tutorial Tray'),
        'new-analytics'
      )
    }
    // Return null if we don't have a tutorial tray
    return null
  }
  return generateObject(HomeTray, I18n.t('Home Tutorial Tray'), 'home')
}

export default getProperTray
