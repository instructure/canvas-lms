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
  var Subject = require('jsx!views/questions/essay');

  describe('Views.Questions.Essay', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    it('should provide a link to speedgrader', function() {
      setProps({
        speedGraderUrl: 'http://localhost:3000/courses/1/gradebook/speed_grader?assignment_id=10'
      });

      expect('a[href*=speed_grader]').toExist();
      expect(find('a[href*=speed_grader]').innerText).toContain('View in SpeedGrader');
    });

    it('should not render if no link to speedgrader present', () => {
      setProps({
        speedGraderUrl: null
      })
      expect('a').not.toExist()
    })
  });
});
