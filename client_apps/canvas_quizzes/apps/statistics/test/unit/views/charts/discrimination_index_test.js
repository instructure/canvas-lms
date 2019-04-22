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
  var Subject = require('jsx!views/charts/discrimination_index');
  var K = require('constants');

  // These tests were commented out because they broke when we upgraded to node 10
  // describe('Views.Charts.DiscriminationIndex', function() {
  //   this.reactSuite({
  //     type: Subject
  //   });

  //   it('should render', function() {
  //     expect(subject.isMounted()).toEqual(true);
  //   });

  //   it('goes positive when the DI is above the threshold', function() {
  //     setProps({
  //       discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD + 0.1
  //     });

  //     expect(find('.index').className).toMatch('positive');
  //   });

  //   it('shows a "+" sign when positive', function() {
  //     setProps({
  //       discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD + 0.1
  //     });

  //     expect(find('.sign').innerText).toEqual('+');
  //   });

  //   it('goes negative when <= the threshold', function() {
  //     setProps({
  //       discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD
  //     });

  //     expect(find('.index').className).toMatch('negative');
  //   });

  //   it('shows a "+" sign when below the threshold and above 0', function() {
  //     setProps({
  //       discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD - 0.1
  //     });

  //     expect(find('.sign').innerText).toEqual('+');
  //   });

  //   it('shows a "-" sign when below 0', function(){
  //     setProps({
  //       discriminationIndex: -0.1
  //     });

  //     expect(find('.sign').innerText).toEqual('-');
  //   });
  // });
});
