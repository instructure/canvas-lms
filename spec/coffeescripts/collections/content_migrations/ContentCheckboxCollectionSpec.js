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

import CheckboxCollection from 'compiled/collections/content_migrations/ContentCheckboxCollection'
import CheckboxModel from 'compiled/models/content_migrations/ContentCheckbox'

QUnit.module('ContentCheckboxCollectionSpec')
const createCheckboxCollection = function(properties) {
  if (!properties) {
    properties = {}
  }
  const models = properties.models || new CheckboxModel({id: 42})
  const options = properties.options || {
    migrationID: 1,
    courseID: 2
  }
  return new CheckboxCollection(models, options)
}
test('url is going to the correct api endpoint', () => {
  const courseID = 10
  const migrationID = 20
  const checkboxCollection = createCheckboxCollection({
    options: {
      migrationID,
      courseID
    }
  })
  const endpointURL = `/api/v1/courses/${courseID}/content_migrations/${migrationID}/selective_data`
  equal(checkboxCollection.url(), endpointURL, 'Endpoint url is correct')
})

test("contains ContentCheckboxModel's ", () => {
  const {model} = createCheckboxCollection()
  const modelInstance = new model()
  ok(
    modelInstance instanceof CheckboxModel,
    'Collection contains instances of ContentCheckboxModels'
  )
})

test('has a courseID', () =>
  ok(
    isFinite(Number(createCheckboxCollection({options: {courseID: '23'}}).courseID)),
    'Has a courseID number'
  ))

test('has a migrationID', () =>
  ok(
    isFinite(Number(createCheckboxCollection({options: {migrationID: '13'}}).migrationID)),
    'Has a migrationID number'
  ))
