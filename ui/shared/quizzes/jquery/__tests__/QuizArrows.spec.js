/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import QuizArrowApplicator from '../quiz_arrows'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('QuizArrowApplicator', () => {
  let arrowApplicator

  beforeEach(() => {
    fakeENV.setup()
    arrowApplicator = new QuizArrowApplicator()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test("applies 'correct' and 'incorrect' arrows when the quiz is not a survey", () => {
    jest.spyOn(arrowApplicator, 'applyCorrectAndIncorrectArrows')
    global.ENV = {IS_SURVEY: false}
    arrowApplicator.applyArrows()
    expect(arrowApplicator.applyCorrectAndIncorrectArrows).toHaveBeenCalledTimes(1)
  })

  test("does not apply 'correct' and 'incorrect' arrows when the quiz is a survey", () => {
    jest.spyOn(arrowApplicator, 'applyCorrectAndIncorrectArrows')
    global.ENV = {IS_SURVEY: true}
    arrowApplicator.applyArrows()
    expect(arrowApplicator.applyCorrectAndIncorrectArrows).not.toHaveBeenCalled()
  })
})
