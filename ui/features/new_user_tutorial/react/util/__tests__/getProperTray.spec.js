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

import getProperTray from '../getProperTray'

import HomeTray from '../../trays/HomeTray'
import ModulesTray from '../../trays/ModulesTray'
import PagesTray from '../../trays/PagesTray'
import AssignmentsTray from '../../trays/AssignmentsTray'
import QuizzesTray from '../../trays/QuizzesTray'
import SettingsTray from '../../trays/SettingsTray'
import FilesTray from '../../trays/FilesTray'
import PeopleTray from '../../trays/PeopleTray'
import AnnouncementsTray from '../../trays/AnnouncementsTray'
import GradesTray from '../../trays/GradesTray'
import DiscussionsTray from '../../trays/DiscussionsTray'
import SyllabusTray from '../../trays/SyllabusTray'
import CollaborationsTray from '../../trays/CollaborationsTray'
import ImportTray from '../../trays/ImportTray'
import ConferencesTray from '../../trays/ConferencesTray'

describe('getProperTray test', () => {
  test('if no match is in the path argument returns the HomeTray', () => {
    const trayObj = getProperTray('/courses/3')
    expect(trayObj.component).toBe(HomeTray)
    expect(trayObj.label).toBe('Home Tutorial Tray')
  })

  test('if modules is in the path argument returns the ModulesTray', () => {
    const trayObj = getProperTray('/courses/3/modules/')
    expect(trayObj.component).toBe(ModulesTray)
    expect(trayObj.label).toBe('Modules Tutorial Tray')
  })

  test('if pages is in the path argument returns the PagesTray', () => {
    const trayObj = getProperTray('/courses/3/pages/')
    expect(trayObj.component).toBe(PagesTray)
    expect(trayObj.label).toBe('Pages Tutorial Tray')
  })

  test('if assignments is in the path argument returns the AssignmentsTray', () => {
    const trayObj = getProperTray('/courses/3/assignments/')
    expect(trayObj.component).toBe(AssignmentsTray)
    expect(trayObj.label).toBe('Assignments Tutorial Tray')
  })

  test('if quizzes is in the path argument returns the QuizzesTray', () => {
    const trayObj = getProperTray('/courses/3/quizzes/')
    expect(trayObj.component).toBe(QuizzesTray)
    expect(trayObj.label).toBe('Quizzes Tutorial Tray')
  })

  test('if settings is in the path argument returns the SettingsTray', () => {
    const trayObj = getProperTray('/courses/3/settings/')
    expect(trayObj.component).toBe(SettingsTray)
    expect(trayObj.label).toBe('Settings Tutorial Tray')
  })

  test('if files is in the path argument returns the FilesTray', () => {
    const trayObj = getProperTray('/courses/3/files/')
    expect(trayObj.component).toBe(FilesTray)
    expect(trayObj.label).toBe('Files Tutorial Tray')
  })

  test('if users is in the path argument returns the PeopleTray', () => {
    const trayObj = getProperTray('/courses/3/users/')
    expect(trayObj.component).toBe(PeopleTray)
    expect(trayObj.label).toBe('People Tutorial Tray')
  })

  test('if announcements is in the path argument returns the AnnouncementsTray', () => {
    const trayObj = getProperTray('/courses/3/announcements/')
    expect(trayObj.component).toBe(AnnouncementsTray)
    expect(trayObj.label).toBe('Announcements Tutorial Tray')
  })

  test('if gradebook is in the path argument returns the GradesTray', () => {
    const trayObj = getProperTray('/courses/3/gradebook/')
    expect(trayObj.component).toBe(GradesTray)
    expect(trayObj.label).toBe('Gradebook Tutorial Tray')
  })

  test('if discussion_topics is in the path argument returns the DiscussionsTray', () => {
    const trayObj = getProperTray('/courses/3/discussion_topics/')
    expect(trayObj.component).toBe(DiscussionsTray)
    expect(trayObj.label).toBe('Discussions Tutorial Tray')
  })

  test('if syllabus is in the path argument returns the SyllabusTray', () => {
    const trayObj = getProperTray('/courses/3/assignments/syllabus/')
    expect(trayObj.component).toBe(SyllabusTray)
    expect(trayObj.label).toBe('Syllabus Tutorial Tray')
  })

  test('if lti_collaborations is in the path argument returns the CollaborationsTray', () => {
    const trayObj = getProperTray('/courses/3/lti_collaborations/')
    expect(trayObj.component).toBe(CollaborationsTray)
    expect(trayObj.label).toBe('Collaborations Tutorial Tray')
  })

  test('if collaborations is in the path argument returns the CollaborationsTray', () => {
    const trayObj = getProperTray('/courses/3/collaborations/')
    expect(trayObj.component).toBe(CollaborationsTray)
    expect(trayObj.label).toBe('Collaborations Tutorial Tray')
  })

  test('if content_migrations is in the path argument returns the ImportTray', () => {
    const trayObj = getProperTray('/courses/3/content_migrations/')
    expect(trayObj.component).toBe(ImportTray)
    expect(trayObj.label).toBe('Import Tutorial Tray')
  })

  test('if conferences is in the path argument returns the ConferencesTray', () => {
    const trayObj = getProperTray('/courses/3/conferences/')
    expect(trayObj.component).toBe(ConferencesTray)
    expect(trayObj.label).toBe('Conferences Tutorial Tray')
  })
})
