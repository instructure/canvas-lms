/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import {useScope as createI18nScope} from '@canvas/i18n'
import GradeSummary from '../index'

const I18n = createI18nScope('gradebooks')

const mockRender = jest.fn()

jest.mock('react-dom/client', () => ({
  createRoot: jest.fn(() => ({
    render: mockRender,
  })),
}))

describe('GradeSummary - Asset Processor functionality', () => {
  let $fixtures

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)

    fakeENV.setup({
      submissions: [],
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    $fixtures.remove()
  })

  describe('addAssetProcessorToLegacyTable', () => {
    beforeEach(() => {
      mockRender.mockClear()

      $fixtures.innerHTML = `
        <table id="grades_summary">
          <thead>
            <tr>
              <th id="asset_processors_header"></th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="asset_processors_cell" data-assignment-id="123" data-submission-id="456"></td>
            </tr>
            <tr>
              <td class="asset_processors_cell" data-assignment-id="789" data-submission-id="101"></td>
            </tr>
          </tbody>
        </table>
      `
    })

    it('returns early when asset_processors_header element is not found', () => {
      document.getElementById('asset_processors_header').remove()

      GradeSummary.addAssetProcessorToLegacyTable()
      // Should not throw any errors
    })

    it('returns early when no submissions have asset_reports', () => {
      ENV.submissions = [
        {assignment_id: '123', asset_reports: null},
        {assignment_id: '789', asset_reports: undefined},
      ]

      GradeSummary.addAssetProcessorToLegacyTable()

      expect(document.getElementById('asset_processors_header').textContent).toBe('')
      document
        .querySelectorAll('.asset_processors_cell')
        .forEach(cell => expect(cell.children).toHaveLength(0))
    })

    it('sets the header text when submissions with asset_reports exist', () => {
      ENV.submissions = [
        {
          assignment_id: '123',
          asset_reports: [{id: 1, priority: 0}],
          asset_processors: [{id: 1, title: 'Test Processor', tool_id: 1, tool_name: 't1'}],
        },
      ]

      GradeSummary.addAssetProcessorToLegacyTable()

      const assetProcessorCells = document.querySelectorAll('.asset_processors_cell')
      expect(assetProcessorCells).toHaveLength(2)
      expect(mockRender).toHaveBeenCalledTimes(1)
      expect(document.getElementById('asset_processors_header').textContent).toBe(
        I18n.t('Document Processors'),
      )
    })

    it('skips cells without assignment_id or submission_id', () => {
      $fixtures.innerHTML = `
        <table id="grades_summary">
          <thead>
            <tr>
              <th id="asset_processors_header"></th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="asset_processors_cell" data-assignment-id="123"></td>
            </tr>
            <tr>
              <td class="asset_processors_cell" data-submission-id="456"></td>
            </tr>
          </tbody>
        </table>
      `

      ENV.submissions = [
        {
          assignment_id: '123',
          asset_reports: [{id: 1}],
          asset_processors: [],
        },
      ]

      GradeSummary.addAssetProcessorToLegacyTable()

      const incompleteCells = document.querySelectorAll('.asset_processors_cell')
      incompleteCells.forEach(cell => {
        expect(cell.children).toHaveLength(0)
      })
    })
  })
})
