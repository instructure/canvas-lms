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

import moment_formats from 'moment_formats'
import I18nStubber from 'helpers/I18nStubber'

QUnit.module('Moment formats', {
  setup () {
    I18nStubber.pushFrame()
    I18nStubber.setLocale('test')
    I18nStubber.stub('test', {
      'date.formats.medium': '%b %-d, %Y',
      'time.formats.tiny': '%l:%M%P',
      'time.formats.tiny_on_the_hour': '%l%P'
    })
  },
  teardown () {
    I18nStubber.popFrame()
  }
})

test('formatsForLocale include formats matching datepicker', () => {
  const formats = moment_formats.formatsForLocale()
  ok(formats.indexOf('%b %-d, %Y %l:%M%P') !== -1)
  ok(formats.indexOf('%b %-d, %Y %l%P') !== -1)
})
