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
import {renderAPComponent} from '@canvas/lti-asset-processor/react/util/renderToElements'
import {
  LtiAssetProcessorCellWithData,
  AssetProcessorHeaderForGrades,
  ZLtiAssetProcessorCellWithDataProps,
} from '../../react/LtiAssetProcessorCellWithData'
import {ZUseCourseAssignmentsAssetReportsParams} from '@canvas/lti-asset-processor/react/hooks/useCourseAssignmentsAssetReports'

const I18n = createI18nScope('gradebooks')

vi.mock('@canvas/lti-asset-processor/react/util/renderToElements', () => ({
  renderAPComponent: vi.fn(),
}))

describe('GradeSummary - Asset Processor functionality', () => {
  let $fixtures

  beforeEach(() => {
    $fixtures = document.createElement('div')
    $fixtures.id = 'fixtures'
    document.body.appendChild($fixtures)

    fakeENV.setup({
      submissions: [],
      FEATURES: {
        lti_asset_processor: true,
      },
      course_id: 'course123',
      student_id: 'student456',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    $fixtures.remove()
  })

  describe('addAssetProcessorToLegacyTable', () => {
    beforeEach(() => {
      renderAPComponent.mockClear()

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

    it('returns early when lti_asset_processor feature flag is disabled', () => {
      ENV.FEATURES.lti_asset_processor = false

      GradeSummary.addAssetProcessorToLegacyTable()

      expect(renderAPComponent).not.toHaveBeenCalled()
    })

    it('returns early when courseId is missing', () => {
      ENV.course_id = null

      GradeSummary.addAssetProcessorToLegacyTable()

      expect(renderAPComponent).not.toHaveBeenCalled()
    })

    it('returns early when studentId is missing', () => {
      ENV.student_id = null

      GradeSummary.addAssetProcessorToLegacyTable()

      expect(renderAPComponent).not.toHaveBeenCalled()
    })

    it('renders header and cell components when feature flag is enabled and IDs are present', () => {
      GradeSummary.addAssetProcessorToLegacyTable()

      expect(renderAPComponent).toHaveBeenCalledTimes(2)
      expect(renderAPComponent).toHaveBeenCalledWith(
        '#asset_processors_header',
        AssetProcessorHeaderForGrades,
        ZUseCourseAssignmentsAssetReportsParams,
        expect.any(Function),
      )
      expect(renderAPComponent).toHaveBeenCalledWith(
        '.asset_processors_cell',
        LtiAssetProcessorCellWithData,
        ZLtiAssetProcessorCellWithDataProps,
        expect.any(Function),
      )
    })

    it('passes courseId, studentId, and gradingPeriodId to header component', () => {
      ENV.current_grading_period_id = 'gp123'

      GradeSummary.addAssetProcessorToLegacyTable()

      const headerCall = renderAPComponent.mock.calls.find(
        call => call[0] === '#asset_processors_header',
      )
      expect(headerCall).toBeDefined()

      const propsGenerator = headerCall[3]
      const props = propsGenerator(document.createElement('div'))

      expect(props).toEqual({
        courseId: 'course123',
        gradingPeriodId: 'gp123',
        studentId: 'student456',
      })
    })

    it('passes assignmentId, courseId, studentId, and gradingPeriodId to cell components', () => {
      ENV.current_grading_period_id = 'gp789'

      GradeSummary.addAssetProcessorToLegacyTable()

      const cellCall = renderAPComponent.mock.calls.find(
        call => call[0] === '.asset_processors_cell',
      )
      expect(cellCall).toBeDefined()

      const propsGenerator = cellCall[3]
      const mockElement = document.createElement('div')
      mockElement.dataset.assignmentId = '999'
      const props = propsGenerator(mockElement)

      expect(props).toEqual({
        assignmentId: '999',
        courseId: 'course123',
        gradingPeriodId: 'gp789',
        studentId: 'student456',
      })
    })
  })
})
