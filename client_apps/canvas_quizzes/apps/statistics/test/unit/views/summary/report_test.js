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
  var Subject = require('jsx!views/summary/report');
  var $ = require('jquery');

  // These tests were commented out because they broke when we upgraded to node 10
  // describe('Views.Summary.Report', function() {
  //   this.reactSuite({
  //     type: Subject
  //   });

  //   it('should render', function() {});
  //   it('should be a button if it can be generated', function() {
  //     setProps({ isGenerated: false });

  //     expect('button.generate-report').toExist();
  //   });

  //   it('should be an anchor if it can be downloaded', function() {
  //     setProps({
  //       isGenerated: true,
  //       file: {
  //         createdAt: new Date(),
  //         url: 'http://foobar.com/'
  //       }
  //     });

  //     expect('a.download-report').toExist();
  //     expect(find('a.download-report').href).toBe('http://foobar.com/');
  //   });

  //   it('should emit quizReports:generate', function() {
  //     setProps({
  //       generatable: true,
  //       reportType: 'student_analysis'
  //     });

  //     expect(function() {
  //       click('button.generate-report');
  //     }).toSendAction({
  //       action: 'quizReports:generate',
  //       args: 'student_analysis'
  //     });
  //   });

  //   it('should mount a Status inside a tooltip', function() {
  //     var $node, $target;

  //     setProps({
  //       generatable: true,
  //       file: {
  //         url: 'http://something.com',
  //         createdAt: '04/04/2014'
  //       }
  //     });

  //     expect($('.qtip .quiz-report-status')[0]).toExist();
  //   });
  // });
});
