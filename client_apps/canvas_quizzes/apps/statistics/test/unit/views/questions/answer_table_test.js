/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
  var Subject = require('jsx!views/questions/answer_table');
  var $ = require('jquery');
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var d3 = require('d3');

  // These tests were commented out because they broke when we upgraded to node 10
  // describe('Views.Questions.AnswerTable', function() {
  //   this.reactSuite({
  //     type: Subject
  //   });

  //   it('should render', function() {
  //     expect(subject.isMounted()).toEqual(true);
  //   });

  //   it('should show the right number of answer bars', function() {
  //     var rect;

  //     setProps({
  //       answers: [
  //         { id: '1', correct: true, responses: 4, ratio: 4/6.0 },
  //         { id: '2', correct: false, responses: 2, ratio: 2/6.0 },
  //       ]
  //     });

  //     expect(findAll('div.bar').length).toBe(2);
  //   });
  // });
});
