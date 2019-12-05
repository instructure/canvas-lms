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
  var Subject = require('jsx!views/questions/fill_in_multiple_blanks');
  var answerSetFixture = [
    {
      id: '1',
      text: 'color',
      answers: [
        { id: 'a1', text: 'red', responses: 4, correct: true, ratio: 100, user_ids: [1, 2, 3, 4], user_names: ['One', 'Two', 'Three', 'Four']},
        { id: 'a2', text: 'green', responses: 0, ratio: 0, user_ids: [], user_names: []},
        { id: 'a3', text: 'blue', responess: 0, ratio: 0, user_ids: [], user_names: []},
      ]
    },
    {
      id: '2',
      text: 'size',
      answers: [
        { id: 'b1', text: 'S', responses: 1, ratio: 0, user_ids: [], user_names: [] },
        { id: 'b2', text: 'M', responses: 0, ratio: 0, user_ids: [], user_names: [] },
        { id: 'b3', text: 'L', responses: 3, correct: true, ratio: 75, user_ids: [1, 2, 3], user_names: ['One', 'Two', 'Three'] },
      ]
    }
  ];

  // These tests were commented out because they broke when we upgraded to node 10
  // describe('Views.Questions.FillInMultipleBlanks', function() {
  //   this.reactSuite({
  //     type: Subject
  //   });

  //   it('should render', function() {
  //     expect(subject.isMounted()).toEqual(true);
  //   });
  //   it('renders a tab for each answer set', function() {
  //     setProps({
  //       answerSets: [
  //         { id: '1', text: 'color' },
  //         { id: '2', text: 'size' }
  //       ],
  //     });

  //     expect('.answer-set-tabs button:contains("color")').toExist();
  //     expect('.answer-set-tabs button:contains("size")').toExist();
  //   });

  //   it('activates an answer set by clicking the tab', function() {
  //     setProps({
  //       answerSets: [
  //         { id: '1', text: 'color' },
  //         { id: '2', text: 'size' }
  //       ]
  //     });

  //     expect(find('.answer-set-tabs .active').innerText).toMatch('color');
  //     click('.answer-set-tabs button:contains("size")');
  //     expect(find('.answer-set-tabs .active').innerText).toMatch('size');
  //   });

  //   it('shows answer text per answer set', function() {
  //     setProps({
  //       answerSets: answerSetFixture,
  //     });

  //     expect(find('.answer-set-tabs .active').innerText).toMatch('color');
  //     var answerTextMatches = findAll("th.answer-textfield .answerText");
  //     expect(answerTextMatches[0].innerText).toEqual('red');
  //     expect(answerTextMatches[1].innerText).toEqual('green');
  //     expect(answerTextMatches[2].innerText).toEqual('blue');

  //     click('.answer-set-tabs button:contains("size")');

  //     expect(find('.answer-set-tabs .active').innerText).toMatch('size');
  //     answerTextMatches = findAll("th.answer-textfield .answerText");
  //     expect(answerTextMatches[0].innerText).toEqual('S');
  //     expect(answerTextMatches[1].innerText).toEqual('M');
  //     expect(answerTextMatches[2].innerText).toEqual('L');
  //   });
  // });
});
