/*
 * Copyright (C) 2017 Instructure, Inc.
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

import GradebookHistory from 'gradebook-history';
import React from 'react';
import ReactDOM from 'react-dom';
import $ from 'jquery';

const fixtures = document.getElementById('fixtures');
function revertGradeHTML ({grade, excused}) {
  let displayGrade = grade;
  if (excused) {
    displayGrade = 'EX';
  } else if (grade === null) {
    displayGrade = '-';
  }

  return (
    <div>
      <a style={{ display: 'none' }} title="POST" href="someLink" className="update_submission_grade_url" />
      <table>
        <tbody>
          <tr data-assignment-id="140" data-user-id="4">
            <td><a href="#" className="ui-corner-all revert-grade-link" data-grade={displayGrade} /></td>
            <td>
              <span title="Thursday by cletus@example.com" className="current_grade assignment_140_user_4_current_grade">
                {displayGrade}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}

function submissionsResponse ({grade, excused}) {
  const response = JSON.stringify([{
    submission: {
      id: '5',
      grade,
      excused,
      assignment_id: '140',
      user_id: '4',
      graded_at: '2016-03-16T17:40:40Z'
    }
  }]);
  return [200, { 'Content-Type': 'application/json' }, response];
}

QUnit.module('GradebookHistory', {
  setupTest ({grade, excused}) {
    ReactDOM.render(revertGradeHTML({ grade, excused }), fixtures);
    this.stub($, 'screenReaderFlashMessage');
    this.server = sinon.fakeServer.create();
    this.server.respondWith('POST', 'someLink', submissionsResponse({ grade, excused }));
    GradebookHistory.init();
  },

  teardown () {
    this.server.restore();
    fixtures.innerHTML = '';
  }
});

test('flashes a screenreader message when "Revert to this grade" is clicked', function () {
  this.setupTest({ grade: '5', excused: false });
  document.querySelector('.revert-grade-link').click();
  this.server.respond();
  ok($.screenReaderFlashMessage.calledOnce);
});

test('notifies the user of the new grade', function () {
  const grade = '5';
  this.setupTest({ grade, excused: false });
  document.getElementsByClassName('revert-grade-link')[0].click();
  this.server.respond();
  ok($.screenReaderFlashMessage.calledWithExactly(`Updated current grade to ${grade}`));
});

test('notifies the user of new empty grades', function () {
  this.setupTest({ grade: null, excused: false });
  document.getElementsByClassName('revert-grade-link')[0].click();
  this.server.respond();
  ok($.screenReaderFlashMessage.calledWithExactly('Updated current grade to be empty'));
});

test('notifies the user of new excused grades', function () {
  this.setupTest({ grade: null, excused: true });
  document.getElementsByClassName('revert-grade-link')[0].click();
  this.server.respond();
  ok($.screenReaderFlashMessage.calledWithExactly('Updated current grade to EX'));
});
