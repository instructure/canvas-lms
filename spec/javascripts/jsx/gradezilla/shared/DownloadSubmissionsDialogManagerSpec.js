/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

define([
  'jsx/gradezilla/shared/DownloadSubmissionsDialogManager',
  'INST',
  'submission_download'
], (DownloadSubmissionsDialogManager, INST) => {
  QUnit.module('DownloadSubmissionsDialogManager#constructor');

  test('constructs download url from given assignment data and url template', () => {
    const manager = new DownloadSubmissionsDialogManager({
      id: 'the_id'
    }, 'the_{{ assignment_id }}_url');

    strictEqual(manager.downloadUrl, 'the_the_id_url');
  });

  QUnit.module('DownloadSubmissionsDialogManager#isDialogEnabled');

  test('returns true when submssion type includes online_upload and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_upload'],
        has_submitted_submissions: true
      },
      'the_url'
    );
    strictEqual(manager.isDialogEnabled(), true);
  });

  test('returns true when submssion type includes online_text_entry and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_text_entry'],
        has_submitted_submissions: true
      },
      'the_url'
    );
    strictEqual(manager.isDialogEnabled(), true);
  });

  test('returns true when submssion type includes online_url and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_url'],
        has_submitted_submissions: true
      },
      'the_url'
    );
    strictEqual(manager.isDialogEnabled(), true);
  });

  test('returns false when submssion type does not include a valid submission type and there is a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['foo'],
        has_submitted_submissions: true
      },
      'the_url'
    );
    strictEqual(manager.isDialogEnabled(), false);
  });

  test('returns false when submssion type does includes a valid submission type and there is not a submitted submission', () => {
    const manager = new DownloadSubmissionsDialogManager(
      {
        submission_types: ['online_url'],
        has_submitted_submissions: false
      },
      '/foo/bar'
    );
    strictEqual(manager.isDialogEnabled(), false);
  });

  QUnit.module('DownloadSubmissionsDialogManager#showDialog');

  test('calls submissions downloading callback and opens downloadSubmissions dialog', function () {
    sandbox.stub(INST, 'downloadSubmissions');
    const submissionsDownloading = sinon.stub();
    const manager = new DownloadSubmissionsDialogManager(
      {
        id: 'the_id',
        submission_types: ['online_upload'],
        has_submitted_submissions: true
      },
      'the_{{ assignment_id }}_url',
      submissionsDownloading
    );
    manager.showDialog();

    ok(submissionsDownloading.calledWith('the_id'));
    ok(INST.downloadSubmissions.calledWith('the_the_id_url'));
  });
});
