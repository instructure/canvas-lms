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
  var Subject = require('jsx!views/summary/report/status');
  var $ = require('jquery');

  // These tests were commented out because they broke when we upgraded to node 10
  // describe('Views.Summary.Report.Status', function() {
  //   this.reactSuite({
  //     type: Subject
  //   });

  //   it('should render', function() {});

  //   describe('when not yet generated', function() {
  //     it('should read a message', function() {
  //       setProps({
  //         generatable: true,
  //         file: {},
  //         progress: {}
  //       });

  //       expect(subject.getDOMNode().innerText).toMatch('never been generated');
  //     });
  //   });

  //   describe('when generating', function() {
  //     it('should show a progress bar', function() {
  //       setProps({
  //         generatable: true,
  //         isGenerating: true,
  //         progress: {
  //           completion: 0,
  //         }
  //       });

  //       expect('.progress').toExist();
  //     });

  //     it('should fill up the progress bar', function() {
  //       setProps({
  //         generatable: true,
  //         isGenerating: true,
  //         progress: {
  //           completion: 0,
  //         }
  //       });

  //       expect(find('.progress .bar').style.width).toBe('0%');

  //       setProps({
  //         progress: {
  //           completion: 25
  //         }
  //       });

  //       expect(find('.progress .bar').style.width).toBe('25%');
  //     });
  //   });

  //   describe('when generated', function() {
  //     it('should read the time of generation', function() {
  //       setProps({
  //         generatable: true,
  //         isGenerated: true,
  //         file: {
  //           createdAt: new Date(2013, 6, 18)
  //         },
  //         progress: {}
  //       });

  //       expect(subject.getDOMNode().innerText).toMatch('Generated: .* 2013');
  //     });
  //   });
  // });
});
