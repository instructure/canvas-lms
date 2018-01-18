/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

/* eslint-disable qunit/no-setup-teardown */

import $ from 'jquery'
import DialogBaseView from 'compiled/views/DialogBaseView'

QUnit.module('DialogBaseView', {
  setup() {
    $('.ui-dialog').remove()
  },
  teardown() {
    $('.ui-dialog').remove()
  }
})

test('it removes the created dialog upon close when the destroy option is set', () => {
  const dialog = new DialogBaseView({destroy: true})
  equal($('.ui-dialog').length, 1)
  dialog.close()
  equal($('.ui-dialog').length, 0)
})

test('if destroy is not specified as an option it only hides the dialog', () => {
  const dialog = new DialogBaseView({id: 'test_id_314'})
  equal($('.ui-dialog').length, 1)
  dialog.close()
  equal($('.ui-dialog').length, 1)
  equal($('.ui-dialog:visible').length, 0)
})
