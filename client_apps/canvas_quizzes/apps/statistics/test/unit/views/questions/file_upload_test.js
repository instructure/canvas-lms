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
  var Subject = require('jsx!views/questions/file_upload');

  describe('Views.Questions.FileUpload', function() {
    this.reactSuite({
      type: Subject
    });

    // These tests were commented out because they broke when we upgraded to node 10
    // it('should render', function() {
    //   expect(subject.isMounted()).toEqual(true);
    // });

    // it('should provide a link to download submissions', function() {
    //   setProps({
    //     quizSubmissionsZipUrl: 'http://localhost:3000/courses/1/quizzes/8/submissions?zip=1'
    //   });

    //   expect('a[href*=zip]').toExist();
    //   expect(find('a[href*=zip]').innerText).toContain('Download All Files');
    // });
  });
});
