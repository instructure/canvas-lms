/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute test and/or modify test under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that test will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import sinon from 'sinon'

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper.js'

QUnit.module('Gradebook > DataLoader', () => {
  let dataLoader

  QUnit.module('#loadCustomColumnData()', hooks => {
    hooks.beforeEach(() => {
      dataLoader = createGradebook({context_id: '1201'}).dataLoader

      sinon
        .stub(dataLoader.customColumnsDataLoader, 'loadCustomColumnsData')
        .returns(Promise.resolve(null))
    })

    test('loads the custom column data using the custom columns data loader', () => {
      dataLoader.loadCustomColumnData('2401')
      strictEqual(dataLoader.customColumnsDataLoader.loadCustomColumnsData.callCount, 1)
    })

    test('includes the given custom column ids when loading custom column data', () => {
      dataLoader.loadCustomColumnData('2401')
      const [columnIds] = dataLoader.customColumnsDataLoader.loadCustomColumnsData.lastCall.args
      deepEqual(columnIds, ['2401'])
    })
  })
})
