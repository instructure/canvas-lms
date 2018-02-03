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

import uploadFile from 'jsx/shared/upload_file'

QUnit.module('Upload File');

test('uploadFile threads through in direct to S3 case', assert => {
  const done = assert.async()
  const successUrl = 'http://successUrl';
  const preflightResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      data: {
        upload_params: { fakeKey: 'fakeValue', success_url: successUrl },
        upload_url: 'http://uploadUrl'
      }
    }));
  });

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.onCall(0).returns(preflightResponse);
  postStub.onCall(1).returns(Promise.resolve());
  getStub.returns(Promise.resolve());

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = { name: 'fake' };
  const file = sinon.stub();

  uploadFile(url, data, file, fakeAjaxLib).then(() => {
    ok(getStub.calledWith(successUrl), 'made request to success url');
    done()
  });
});

test('uploadFile threads through in inst-fs case', assert => {
  const done = assert.async()
  const successUrl = 'http://successUrl';
  const preflightResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      data: {
        upload_params: { fakeKey: 'fakeValue' },
        upload_url: 'http://uploadUrl'
      }
    }));
  });

  const postResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      status: 201,
      data: { location: successUrl }
    }));
  });

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.onCall(0).returns(preflightResponse);
  postStub.onCall(1).returns(postResponse);
  getStub.returns(Promise.resolve());

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = { name: 'fake' };
  const file = sinon.stub();

  uploadFile(url, data, file, fakeAjaxLib).then(() => {
    ok(getStub.calledWith(successUrl), 'made request to success url');
    done()
  });
});

test('uploadFile threads through in local-storage case', assert => {
  const done = assert.async()
  const preflightResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      data: {
        upload_params: { fakeKey: 'fakeValue' },
        upload_url: 'http://uploadUrl'
      }
    }));
  });

  const postResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      data: { id: 1 }
    }));
  });

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.onCall(0).returns(preflightResponse);
  postStub.onCall(1).returns(postResponse);
  getStub.returns(Promise.resolve());

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = { name: 'fake' };
  const file = sinon.stub();

  uploadFile(url, data, file, fakeAjaxLib).then((response) => {
    equal(response.data.id, 1, 'passed response through');
    done()
  });
});
