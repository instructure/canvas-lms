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
  var Subject = require('collections/quiz_reports');
  describe('Collections.QuizReports', function() {
    it('should parse properly', function() {
      var fixture = require('json!fixtures/quiz_reports.json');
      var subject = new Subject();
      subject.add(fixture, { parse: true });

      expect(subject.length).toBe(2);
      expect(subject.first().get('id')).toBe('200');
      expect(subject.first().get('reportType')).toBe('student_analysis');
    });
  });
});