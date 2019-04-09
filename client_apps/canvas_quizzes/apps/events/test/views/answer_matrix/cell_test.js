// /*
//  * Copyright (C) 2014 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */

// define(function(require) {
//   var Subject = require('jsx!views/answer_matrix/cell');
//   var K = require('constants');

//   describe('Views::AnswerMatrix::Cell', function() {
//     this.reactSuite({
//       type: Subject
//     });

//     it('should render', function() {
//       expect(subject.isMounted()).toEqual(true);
//     });

//     describe('when not expanded', function() {
//       beforeEach(function() {
//         setProps({
//           expanded: false,
//           question: { id: '1', questionType: 'multiple_choice_question' }
//         });
//       });

//       it('should show an emblem for an empty answer', function() {
//         setProps({
//           event: { data: [{ quizQuestionId: '1', answer: null }] }
//         });

//         expect('.is-empty').toExist();
//       });

//       it('should show an emblem for an answer', function() {
//         setProps({
//           event: {
//             data: [
//               { quizQuestionId: '1', answer: '123', answered: true }
//             ]
//           },
//         });

//         expect('.is-answered').toExist();
//       });

//       it('should show an emblem for the last answer', function() {
//         setProps({
//           event: {
//             data: [
//               { quizQuestionId: '1', answer: '123', answered: true, last: true }
//             ]
//           },
//         });

//         expect('.is-answered.is-last').toExist();
//       });

//       it('should show nothing for no answer', function() {
//         expect('.ic-AnswerMatrix__Emblem').not.toExist();
//       });
//     });

//     describe('when expanded', function() {
//       beforeEach(function() {
//         setProps({ expanded: true });
//       });

//       it('should encode the answer as JSON', function() {
//         setProps({
//           question: {
//             id: '1',
//             questionType: 'multiple_choice_question'
//           },

//           event: {
//             data: [{ quizQuestionId: '1', answer: '123' }]
//           }
//         });

//         expect(subject.getDOMNode().innerText.trim()).toEqual(JSON.stringify("123", null, 2));
//       });

//       describe('with an essay/textual question', function() {
//         beforeEach(function() {
//           setProps({
//             question: {
//               id: '1',
//               questionType: K.Q_ESSAY
//             }
//           });
//         });

//         it('should not encode the answer as JSON', function() {
//           setProps({
//             event: {
//               data: [{ quizQuestionId: '1', answer: "<p>foo</p>\n\n<p>bar</p>" }]
//             }
//           });

//           expect(subject.getDOMNode().innerText.trim()).
//             toEqual("<p>foo</p>\n\n<p>bar</p>");
//         });

//         it('should truncate a long answer', function() {
//           setProps({
//             shouldTruncate: true,
//             event: {
//               data: [{
//                 quizQuestionId: '1',
//                 answer: "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
//               }]
//             }
//           });

//           expect(subject.getDOMNode().innerText.trim()).
//             toEqual("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwx...");
//         });

//         it('should not truncate a short answer', function() {
//           setProps({
//             shouldTruncate: true,
//             event: {
//               data: [{
//                 quizQuestionId: '1',
//                 answer: "abcdefghijklmnopqrstuvwxyz"
//               }]
//             }
//           });

//           expect(subject.getDOMNode().innerText.trim()).
//             toEqual("abcdefghijklmnopqrstuvwxyz");
//         });
//       });
//     });
//   });
// });
