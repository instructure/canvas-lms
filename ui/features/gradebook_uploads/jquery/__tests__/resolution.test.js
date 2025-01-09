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
import gradebook_uploads from '../index'
import * as waitForProcessing from '../wait_for_processing'

// Mock jQuery UI and SlickGrid
jest.mock('jquery-ui', () => {
  const $ = require('jquery')
  $.widget = jest.fn()
  $.ui = {
    mouse: {
      _mouseInit: jest.fn(),
      _mouseDestroy: jest.fn(),
    },
    sortable: jest.fn(),
  }
  return $
})

jest.mock('slickgrid', () => {
  const Grid = jest.fn().mockImplementation(function ($container, data, columns, options) {
    this.init = jest.fn()
    this.setData = jest.fn()
    this.render = jest.fn()
    this.setCellCssStyles = jest.fn()
  })
  Grid.prototype.init = jest.fn()
  Grid.prototype.setData = jest.fn()
  Grid.prototype.render = jest.fn()
  Grid.prototype.setCellCssStyles = jest.fn()
  global.Slick = {Grid}
  return {}
})

jest.mock('slickgrid/slick.editors', () => {
  global.Slick = global.Slick || {}
  global.Slick.Editors = {}
  return {}
})

jest.mock('../wait_for_processing')

describe('gradebook_uploads#handleThingsNeedingToBeResolved', () => {
  let defaultUploadedGradebook

  beforeEach(() => {
    document.body.innerHTML = `
      <form id='gradebook_importer_resolution_section'>
        <select name='assignment_-1'>
          <option>73</option>
        </select>
      </form>
      <div id='gradebook_grid'>
        <div id='gradebook_grid_header'></div>
      </div>
      <div id='no_changes_detected' style='display:none;'></div>
      <div id='assignments_without_changes_alert' style='display:none;'></div>
      <form id='gradebook_grid_form' style='display:none;'></form>
    `

    defaultUploadedGradebook = {
      assignments: [],
      custom_columns: [],
      missing_objects: {
        assignments: [],
        students: [],
      },
      original_submissions: [],
      students: [
        {
          id: '1',
          last_name_first: 'Efron, Zac',
          name: 'Zac Efron',
          previous_id: '1',
          submissions: [],
        },
      ],
      warning_messages: {
        prevented_grading_ungradeable_submission: false,
        prevented_new_assignment_creation_in_closed_period: false,
      },
    }
  })

  afterEach(() => {
    document.body.innerHTML = ''
    jest.resetAllMocks()
  })

  it.skip('recognizes that there are no changed assignments when the grades are the same', async () => {
    const uploadedGradebook = {
      ...defaultUploadedGradebook,
      assignments: [
        {
          id: '1',
          title: 'Assignment 1',
          grading_type: 'points',
          points_possible: 10,
          previous_id: '1',
        },
      ],
      original_submissions: [
        {
          assignment_id: '1',
          grade: '10',
          gradeable: true,
          original_grade: '10',
          user_id: '1',
        },
      ],
      students: [
        {
          id: '1',
          last_name_first: 'Efron, Zac',
          name: 'Zac Efron',
          previous_id: '1',
          submissions: [
            {
              assignment_id: '1',
              grade: '10',
              gradeable: true,
              original_grade: '10',
            },
          ],
        },
      ],
    }
    waitForProcessing.waitForProcessing.mockResolvedValue(uploadedGradebook)

    await gradebook_uploads.handleThingsNeedingToBeResolved()
    const $noChangesElement = $('#no_changes_detected')
    expect($noChangesElement).toHaveLength(1)
    expect($noChangesElement.css('display')).not.toBe('none')
  })

  it.skip('recognizes that there are changed assignments when original grade was ungraded', async () => {
    const uploadedGradebook = {
      ...defaultUploadedGradebook,
      assignments: [
        {grading_type: null, id: '-1', points_possible: 10, previous_id: null, title: 'imported'},
      ],
      original_submissions: [{assignment_id: '73', gradeable: true, score: '0.0', user_id: '1'}],
      students: [
        {
          id: '1',
          last_name_first: 'Efron, Zac',
          name: 'Zac Efron',
          previous_id: '1',
          submissions: [
            {assignment_id: '-1', grade: '0.0', gradeable: true, original_grade: '0.0'},
          ],
        },
      ],
    }
    waitForProcessing.waitForProcessing.mockResolvedValue(uploadedGradebook)

    await gradebook_uploads.handleThingsNeedingToBeResolved()
    $('#gradebook_importer_resolution_section').submit()
    const noChangesElement = document.getElementById('no_changes_detected')
    expect(noChangesElement.style.display).toBe('none')
  })
})
