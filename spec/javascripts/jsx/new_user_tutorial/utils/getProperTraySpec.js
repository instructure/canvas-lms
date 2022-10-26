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

import getProperTray from 'ui/features/new_user_tutorial/react/util/getProperTray'

import HomeTray from 'ui/features/new_user_tutorial/react/trays/HomeTray'
import ModulesTray from 'ui/features/new_user_tutorial/react/trays/ModulesTray'
import PagesTray from 'ui/features/new_user_tutorial/react/trays/PagesTray'
import AssignmentsTray from 'ui/features/new_user_tutorial/react/trays/AssignmentsTray'
import QuizzesTray from 'ui/features/new_user_tutorial/react/trays/QuizzesTray'
import SettingsTray from 'ui/features/new_user_tutorial/react/trays/SettingsTray'
import FilesTray from 'ui/features/new_user_tutorial/react/trays/FilesTray'
import PeopleTray from 'ui/features/new_user_tutorial/react/trays/PeopleTray'
import AnnouncementsTray from 'ui/features/new_user_tutorial/react/trays/AnnouncementsTray'
import GradesTray from 'ui/features/new_user_tutorial/react/trays/GradesTray'
import DiscussionsTray from 'ui/features/new_user_tutorial/react/trays/DiscussionsTray'
import SyllabusTray from 'ui/features/new_user_tutorial/react/trays/SyllabusTray'
import CollaborationsTray from 'ui/features/new_user_tutorial/react/trays/CollaborationsTray'
import ImportTray from 'ui/features/new_user_tutorial/react/trays/ImportTray'
import ConferencesTray from 'ui/features/new_user_tutorial/react/trays/ConferencesTray'

QUnit.module('getProperTray test')

test('if no match is in the path argument returns the HomeTray', () => {
  const trayObj = getProperTray('/courses/3')
  equal(trayObj.component, HomeTray, 'component matches')
  equal(trayObj.label, 'Home Tutorial Tray', 'label matches')
})

test('if modules is in the path argument returns the ModulesTray', () => {
  const trayObj = getProperTray('/courses/3/modules/')
  equal(trayObj.component, ModulesTray, 'component matches')

  equal(trayObj.label, 'Modules Tutorial Tray', 'label matches')
})

test('if pages is in the path argument returns the PagesTray', () => {
  const trayObj = getProperTray('/courses/3/pages/')
  equal(trayObj.component, PagesTray, 'component matches')

  equal(trayObj.label, 'Pages Tutorial Tray', 'label matches')
})

test('if assignments is in the path argument returns the AssignmentsTray', () => {
  const trayObj = getProperTray('/courses/3/assignments/')
  equal(trayObj.component, AssignmentsTray, 'component matches')

  equal(trayObj.label, 'Assignments Tutorial Tray', 'label matches')
})

test('if quizzes is in the path argument returns the QuizzesTray', () => {
  const trayObj = getProperTray('/courses/3/quizzes/')
  equal(trayObj.component, QuizzesTray, 'component matches')

  equal(trayObj.label, 'Quizzes Tutorial Tray', 'label matches')
})

test('if settings is in the path argument returns the SettingsTray', () => {
  const trayObj = getProperTray('/courses/3/settings/')
  equal(trayObj.component, SettingsTray, 'component matches')

  equal(trayObj.label, 'Settings Tutorial Tray', 'label matches')
})

test('if files is in the path argument returns the FilesTray', () => {
  const trayObj = getProperTray('/courses/3/files/')
  equal(trayObj.component, FilesTray, 'component matches')

  equal(trayObj.label, 'Files Tutorial Tray', 'label matches')
})

test('if users is in the path argument returns the PeopleTray', () => {
  const trayObj = getProperTray('/courses/3/users/')
  equal(trayObj.component, PeopleTray, 'component matches')

  equal(trayObj.label, 'People Tutorial Tray', 'label matches')
})

test('if announcements is in the path argument returns the AnnouncementsTray', () => {
  const trayObj = getProperTray('/courses/3/announcements/')
  equal(trayObj.component, AnnouncementsTray, 'component matches')

  equal(trayObj.label, 'Announcements Tutorial Tray', 'label matches')
})

test('if gradebook is in the path argument returns the GradesTray', () => {
  const trayObj = getProperTray('/courses/3/gradebook/')
  equal(trayObj.component, GradesTray, 'component matches')

  equal(trayObj.label, 'Gradebook Tutorial Tray', 'label matches')
})

test('if discussion_topics is in the path argument returns the DiscussionsTray', () => {
  const trayObj = getProperTray('/courses/3/discussion_topics/')
  equal(trayObj.component, DiscussionsTray, 'component matches')

  equal(trayObj.label, 'Discussions Tutorial Tray', 'label matches')
})

test('if syllabus is in the path argument returns the SyllabusTray', () => {
  const trayObj = getProperTray('/courses/3/assignments/syllabus/')
  equal(trayObj.component, SyllabusTray, 'component matches')

  equal(trayObj.label, 'Syllabus Tutorial Tray', 'label matches')
})

test('if lti_collaborations is in the path argument returns the CollaborationsTray', () => {
  const trayObj = getProperTray('/courses/3/lti_collaborations/')
  equal(trayObj.component, CollaborationsTray, 'component matches')

  equal(trayObj.label, 'Collaborations Tutorial Tray', 'label matches')
})

test('if collaborations is in the path argument returns the CollaborationsTray', () => {
  const trayObj = getProperTray('/courses/3/collaborations/')
  equal(trayObj.component, CollaborationsTray, 'component matches')

  equal(trayObj.label, 'Collaborations Tutorial Tray', 'label matches')
})

test('if content_migrations is in the path argument returns the ImportTray', () => {
  const trayObj = getProperTray('/courses/3/content_migrations/')
  equal(trayObj.component, ImportTray, 'component matches')

  equal(trayObj.label, 'Import Tutorial Tray', 'label matches')
})

test('if conferences is in the path argument returns the ConferencesTray', () => {
  const trayObj = getProperTray('/courses/3/conferences/')
  equal(trayObj.component, ConferencesTray, 'component matches')

  equal(trayObj.label, 'Conferences Tutorial Tray', 'label matches')
})
