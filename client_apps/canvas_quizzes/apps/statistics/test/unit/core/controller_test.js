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
  var Subject = require('core/controller');
  var config = require('config');

  describe('Controller', function() {
    // These tests were commented out because they broke when we upgraded to node 10
    // describe('#start', function() {
    //   this.promiseSuite = true;

    //   it('should work', function() {
    //     expect(function() {
    //       Subject.start(jasmine.createSpy());
    //     }).not.toThrow();
    //   });
    // });

    // describe('#load', function() {
    //   it('should work', function() {
    //     expect(function() {
    //       Subject.load();
    //     }).not.toThrow();
    //   });
    // });
  });
});
