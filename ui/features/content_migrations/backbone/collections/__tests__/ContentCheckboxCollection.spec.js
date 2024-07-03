/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import CheckboxCollection from '../ContentCheckboxCollection'
import CheckboxModel from '../../models/ContentCheckbox'

describe('ContentCheckboxCollectionSpec', () => {
  const createCheckboxCollection = function (properties = {}) {
    const models = properties.models || new CheckboxModel({id: 42})
    const options = properties.options || {
      migrationID: 1,
      courseID: 2,
    }
    return new CheckboxCollection(models, options)
  }

  test('url is going to the correct api endpoint', () => {
    const courseID = 10
    const migrationID = 20
    const checkboxCollection = createCheckboxCollection({
      options: {
        migrationID,
        courseID,
      },
    })
    const expectedURL = `/api/v1/courses/${courseID}/content_migrations/${migrationID}/selective_data`
    expect(checkboxCollection.url()).toBe(expectedURL)
  })

  test("contains ContentCheckboxModel's", () => {
    const {model} = createCheckboxCollection()
    // eslint-disable-next-line new-cap
    const modelInstance = new model()
    expect(modelInstance).toBeInstanceOf(CheckboxModel)
  })

  test('has a courseID', () => {
    const collection = createCheckboxCollection({options: {courseID: '23'}})
    expect(Number.isFinite(Number(collection.courseID))).toBeTruthy()
  })

  test('has a migrationID', () => {
    const collection = createCheckboxCollection({options: {migrationID: '13'}})
    expect(Number.isFinite(Number(collection.migrationID))).toBeTruthy()
  })
})
