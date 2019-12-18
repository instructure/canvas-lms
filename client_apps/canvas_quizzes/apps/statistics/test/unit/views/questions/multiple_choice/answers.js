/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
  var Subject = require('jsx!views/questions/multiple_choice/answers');
  var answerSetFixture = [
      { id: 'a1', text: 'red', responses: 4, correct: true, ratio: 100, user_ids: [1, 2, 3, 4], user_names: ['One', 'Two', 'Three', 'Four']},
      { id: 'a2', text: 'green', responses: 0, ratio: 0 },
      { id: 'a3', text: 'blue', responess: 0, ratio: 0 }];

  describe('Views.Questions.MultipleChoice.Answers', function() {
    this.reactSuite({
      type: Subject
    });

    it('renders the correct CSS for correct answer', function() {
      setProps({
        answerSets: answerSetFixture,
      });
      expect('.answer-drilldown detail-section').toExist();
      expect(find('.correct').innerText).toMatch('red');

      click(find('.correct'));
      expect(find('.correct').innerText).toContain('Three');
    });
  });
});


