/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var secondsToTime = require('util/seconds_to_time')

  describe('Util.secondsToTime', function() {
    describe('#toReadableString', function() {
      var subject = secondsToTime.toReadableString

      it('24 => 24 seconds', function() {
        expect(subject(24)).toEqual('24 seconds')
      })

      it('84 => one minute and 24 seconds', function() {
        expect(subject(84)).toEqual('1 minute and 24 seconds')
      })

      it('144 => 2 minutes and 24 seconds', function() {
        expect(subject(144)).toEqual('2 minutes and 24 seconds')
      })

      it('3684 => one hour and one minute', function() {
        expect(subject(3684)).toEqual('1 hour and 1 minute')
      })
    })
  })
})
