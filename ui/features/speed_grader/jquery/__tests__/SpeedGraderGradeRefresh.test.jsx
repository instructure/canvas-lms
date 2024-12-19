/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import fakeENV from '@canvas/test-utils/fakeENV'
import SpeedGrader from '../speed_grader'

describe('SpeedGrader Grade Refresh', () => {
  const requiredDOMFixtures = `
    <div id="hide-assignment-grades-tray"></div>
    <div id="post-assignment-grades-tray"></div>
    <div id="speed_grader_assessment_audit_tray_mount_point"></div>
    <span id="speed_grader_post_grades_menu_mount_point"></span>
    <span id="speed_grader_settings_mount_point"></span>
    <div id="speed_grader_rubric_assessment_tray_wrapper"><div>
    <div id="speed_grader_assessment_audit_button_mount_point"></div>
    <div id="speed_grader_submission_comments_download_mount_point"></div>
    <div id="speed_grader_hidden_submission_pill_mount_point"></div>
    <div id="grades-loading-spinner"></div>
    <div id="grading"></div>
  `

  let fixtures

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.innerHTML = requiredDOMFixtures
    document.body.appendChild(fixtures)

    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false,
    })

    SpeedGrader.EG.currentStudent = {
      id: '1',
      submission: {
        id: '1',
        user_id: '1',
        assignment_id: '17',
        submission_history: [],
      },
    }

    window.jsonData = {
      anonymizableId: 'id',
      anonymizableUserId: 'user_id',
      isAnonymous: true,
      studentMap: {
        1: SpeedGrader.EG.currentStudent,
      },
    }

    window.isAnonymous = window.jsonData.isAnonymous

    jest.spyOn(SpeedGrader.EG, 'domReady').mockImplementation(() => {})
    jest.spyOn(SpeedGrader.EG, 'showGrade').mockImplementation(() => {})
    jest.spyOn(SpeedGrader.EG, 'setOrUpdateSubmission').mockImplementation(() => {})
    jest.spyOn(SpeedGrader.EG, 'updateSelectMenuStatus').mockImplementation(() => {})
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
    jest.resetAllMocks()
  })

  describe('#refreshGrades', () => {
    let ajaxSpy
    let ajaxPromise

    beforeEach(() => {
      ajaxPromise = new Promise(resolve => {
        ajaxSpy = jest.spyOn($, 'getJSON').mockImplementation((url, params, callback) => {
          const newSubmission = {
            id: '1',
            user_id: '1',
            assignment_id: '17',
            grade: '95',
          }
          callback(newSubmission)
        })
      })
    })

    it('fetches and updates submission data', async () => {
      const callbackSpy = jest.fn()
      SpeedGrader.EG.refreshGrades(callbackSpy)
      await new Promise(resolve => setTimeout(resolve, 0))

      expect(callbackSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          id: '1',
          user_id: '1',
          assignment_id: '17',
          grade: '95',
        }),
      )
    })

    it('retries fetching when the retry callback returns true', async () => {
      let retryCount = 0
      SpeedGrader.EG.refreshGrades(
        () => {},
        () => {
          retryCount++
          return retryCount < 2
        },
      )
      await new Promise(resolve => setTimeout(resolve, 0))

      expect(retryCount).toBe(2)
    })

    it('stops retrying when the retry callback returns false', async () => {
      let retryCount = 0
      SpeedGrader.EG.refreshGrades(
        () => {},
        () => {
          retryCount++
          return false
        },
      )
      await new Promise(resolve => setTimeout(resolve, 0))

      expect(retryCount).toBe(1)
    })
  })
})
