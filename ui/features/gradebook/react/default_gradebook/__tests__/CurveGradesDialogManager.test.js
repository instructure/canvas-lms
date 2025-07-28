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
import CurveGradesDialog from '@canvas/grading/jquery/CurveGradesDialog'
import AsyncComponents from '../AsyncComponents'
import CurveGradesDialogManager from '../CurveGradesDialogManager'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('gradebook')

const {createCurveGradesAction} = CurveGradesDialogManager

describe('CurveGradesDialogManager.createCurveGradesAction.isDisabled', () => {
  const getProps = ({
    points_possible,
    grades_published,
    grading_type,
    submissionsLoaded,
    checkpoints,
  }) => [
    {
      points_possible,
      grading_type,
      grades_published,
      checkpoints,
    },
    [],
    {
      isAdmin: false,
      contextUrl: 'http://contextUrl/',
      submissionsLoaded,
    },
  ]

  it('is not disabled when submissions are loaded, grading type is not pass/fail, points are not 0 and checkpoints is empty', () => {
    const props = getProps({
      points_possible: 10,
      grades_published: true,
      grading_type: 'points',
      submissionsLoaded: true,
      checkpoints: [],
    })
    expect(createCurveGradesAction(...props).isDisabled).toBeFalsy()
  })

  it('is disabled when grades are not published', () => {
    const props = getProps({
      points_possible: 10,
      grades_published: false,
      grading_type: 'points',
      submissionsLoaded: true,
    })
    expect(createCurveGradesAction(...props).isDisabled).toBeTruthy()
  })

  // ... similar conversion for other isDisabled tests ...

  describe('onSelect', () => {
    let flashErrorSpy

    beforeEach(() => {
      flashErrorSpy = jest.spyOn($, 'flashError')
      jest.spyOn(AsyncComponents, 'loadCurveGradesDialog').mockResolvedValue(CurveGradesDialog)
      jest.spyOn(CurveGradesDialog.prototype, 'show').mockImplementation(() => {})
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    const getProps = ({inClosedGradingPeriod = false, isAdmin = false} = {}) => [
      {inClosedGradingPeriod},
      [],
      {
        isAdmin,
        contextUrl: 'http://contextUrl/',
        submissionsLoaded: true,
      },
    ]

    it('calls flashError if not admin and in closed grading period', async () => {
      const props = getProps({isAdmin: false, inClosedGradingPeriod: true})
      await createCurveGradesAction(...props).onSelect()
      expect(flashErrorSpy).toHaveBeenCalledWith(
        I18n.t(
          'Unable to curve grades because this assignment is due in a closed ' +
            'grading period for at least one student',
        ),
      )
    })

    // ... similar conversion for other onSelect tests ...
  })
})
