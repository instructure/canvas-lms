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

import { uploadFile, completeUpload } from 'jsx/shared/upload_file'

QUnit.module('Upload File');

test('uploadFile posts form data instead of json if necessary', () => {
  const preflightResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      data: {
        upload_url: 'http://uploadUrl'
      }
    }));
  });

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.onCall(0).returns(preflightResponse);
  postStub.onCall(1).resolves({ data: {} });
  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = {
    name: 'fake',
    'attachment[context_code]': 'course_1'
  };
  const file = sinon.stub();

  return uploadFile(url, data, file, fakeAjaxLib).then(() => {
    ok(postStub.calledWith(url, 'name=fake&attachment%5Bcontext_code%5D=course_1&no_redirect=true'),
       'posted url encoded form data');
  });
});

test('uploadFile requests no_redirect in preflight even if not specified', () => {
  const preflightResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      data: {
        upload_url: 'http://uploadUrl'
      }
    }));
  });

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.onCall(0).returns(preflightResponse);
  postStub.onCall(1).resolves({ data: {} });
  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = { name: 'fake' };
  const file = sinon.stub();

  return uploadFile(url, data, file, fakeAjaxLib).then(() => {
    ok(postStub.calledWith(url, { name: "fake", no_redirect: true }),
       'posted with no_redirect: true');
  });
});

test('uploadFile threads through in direct to S3 case', () => {
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
  postStub.onCall(1).resolves({ data: {} });
  getStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = { name: 'fake' };
  const file = sinon.stub();

  return uploadFile(url, data, file, fakeAjaxLib).then(() => {
    ok(getStub.calledWith(successUrl), 'made request to success url');
  });
});

test('uploadFile threads through in inst-fs case', () => {
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
  getStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = { name: 'fake' };
  const file = sinon.stub();

  return uploadFile(url, data, file, fakeAjaxLib).then(() => {
    ok(getStub.calledWith(successUrl), 'made request to success url');
  });
});

test('uploadFile threads through in local-storage case', () => {
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
  getStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const url = `/api/v1/courses/1/files`;
  const data = { name: 'fake' };
  const file = sinon.stub();

  return uploadFile(url, data, file, fakeAjaxLib).then((response) => {
    equal(response.id, 1, 'passed response through');
  });
});

test('completeUpload upacks embedded "attachments" wrapper if any', () => {
  const upload_url = 'http://uploadUrl';
  const preflightResponse = {
    attachments: [{ upload_url }]
  };

  const postStub = sinon.stub();
  postStub.resolves({ data: {} });
  const fakeAjaxLib = { post: postStub };

  const file = sinon.stub();

  return completeUpload(preflightResponse, file, { ajaxLib: fakeAjaxLib }).then(() => {
    ok(postStub.calledWith(upload_url, sinon.match.any, sinon.match.any),
       'posted correct upload_url');
  });
});

test('completeUpload wires up progress callback if any', () => {
  const postStub = sinon.stub();
  postStub.resolves({ data: {} });
  const fakeAjaxLib = { post: postStub };

  const preflightResponse = { upload_url: 'http://uploadUrl' };
  const file = sinon.stub();
  const options = {
    ajaxLib: fakeAjaxLib,
    onProgress: sinon.spy()
  };

  return completeUpload(preflightResponse, file, options).then(() => {
    ok(postStub.calledWith(sinon.match.any, sinon.match.any, sinon.match({
      onUploadProgress: options.onProgress
    })), 'posted correct config');
  });
});

test('completeUpload skips GET after inst-fs upload if options.ignoreResult', () => {
  const successUrl = 'http://successUrl';

  const postResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      status: 201,
      data: { location: successUrl }
    }));
  });

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.returns(postResponse);
  getStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const preflightResponse = { upload_url: 'http://uploadUrl' };
  const file = sinon.stub();
  const options = {
    ajaxLib: fakeAjaxLib,
    ignoreResult: true
  };

  return completeUpload(preflightResponse, file, options).then(() => {
    ok(getStub.neverCalledWith(successUrl), 'skipped request to success url');
  });
});

test('completeUpload appends avatar include in GET after upload if options.includeAvatar', () => {
  const successUrl = 'http://successUrl';

  const postResponse = new Promise((resolve) => {
    setTimeout(() => resolve({
      status: 201,
      data: { location: successUrl }
    }));
  });

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.returns(postResponse);
  getStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const preflightResponse = { upload_url: 'http://uploadUrl' };
  const file = sinon.stub();
  const options = {
    ajaxLib: fakeAjaxLib,
    includeAvatar: true
  };

  return completeUpload(preflightResponse, file, options).then(() => {
    ok(getStub.calledWith(`${successUrl}?include=avatar`), 'skipped request to success url');
  });
});

test('completeUpload to S3 posts withCredentials false', () => {
  const successUrl = 'http://successUrl';

  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.resolves({ data: {} });
  getStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const preflightResponse = {
    upload_url: 'http://uploadUrl',
    success_url: successUrl
  };
  const file = sinon.stub();
  const options = { ajaxLib: fakeAjaxLib };

  return completeUpload(preflightResponse, file, options).then(() => {
    ok(postStub.calledWith(sinon.match.any, sinon.match.any, sinon.match({
      withCredentials: false
    })), 'withCredentials is false');
  });
});

test('completeUpload to non-S3 posts withCredentials true', () => {
  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.resolves({ data: {} });
  getStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const preflightResponse = { upload_url: 'http://uploadUrl' };
  const file = sinon.stub();
  const options = { ajaxLib: fakeAjaxLib };

  return completeUpload(preflightResponse, file, options).then(() => {
    ok(postStub.calledWith(sinon.match.any, sinon.match.any, sinon.match({
      withCredentials: true
    })), 'withCredentials is true');
  });
});

test('completeUpload does not add a null file to the upload POST', () => {
  const postStub = sinon.stub();
  postStub.resolves({ data: {} });

  const fakeAjaxLib = {
    post: postStub
  };

  const preflightResponse = { upload_url: 'http://uploadUrl', progress: { workflow_state: 'completed', results: {} } };
  const file = null;
  const options = { ajaxLib: fakeAjaxLib };

  return completeUpload(preflightResponse, file, options).then(() => {
    ok(postStub.calledWith(
      sinon.match.any,
      sinon.match((formData) => !formData.has('file')),
      sinon.match.any
    ), 'no file in formData');
  });
});

test('completeUpload immediately waits on progress if given a progress and no upload_url', () => {
  const results = { id: 1 };
  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.resolves({ data: {} });
  getStub.resolves({ data: { workflow_state: 'completed', results } });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const preflightResponse = { progress: { workflow_state: 'queued', url: 'http://progressUrl' } };
  const file = null;
  const options = { ajaxLib: fakeAjaxLib };

  return completeUpload(preflightResponse, file, options).then((data) => {
    ok(!postStub.called, 'no POST made');
    deepEqual(data, results, 'returned data is from the Progress polling');
  });
});

test('completeUpload waits on progress after upload POST if given both a progress and upload URL', () => {
  const results = { id: 1 };
  const postStub = sinon.stub();
  const getStub = sinon.stub();
  postStub.resolves({ data: {} });
  getStub.resolves({ data: { workflow_state: 'completed', results } });

  const fakeAjaxLib = {
    post: postStub,
    get: getStub
  };

  const preflightResponse = {
    progress: { workflow_state: 'queued', url: 'http://progressUrl' },
    upload_url: 'http://uploadUrl'
  };
  const file = null;
  const options = { ajaxLib: fakeAjaxLib };

  return completeUpload(preflightResponse, file, options).then((data) => {
    ok(postStub.called, 'upload POST still made');
    deepEqual(data, results, 'returned data is from the Progress polling');
  });
});

test('uploadFile differentiates network failures during preflight', () => {
  const fakeAjaxLib = { post: sinon.stub() };
  fakeAjaxLib.post.rejects({ message: 'Network Error' }); // preflight attempt
  return uploadFile('http://preflightUrl', {}, sinon.stub(), fakeAjaxLib)
    .then(() => ok(false, 'preflight should fail'))
    .catch(({ message }) => ok(message.match(/failed to initiate the upload/), 'correct error message'));
});

test('uploadFile differentiates network failures during POST to upload_url', () => {
  const fakeAjaxLib = { post: sinon.stub() };
  fakeAjaxLib.post.onCall(0).resolves({ data: { upload_url: 'http://uploadUrl' } }); // preflight
  fakeAjaxLib.post.onCall(1).rejects({ message: 'Network Error' }); // upload attempt
  return uploadFile('http://preflightUrl', {}, sinon.stub(), fakeAjaxLib)
    .then(() => ok(false, 'upload should fail'))
    .catch(({ message }) => ok(message.match(/service may be down/), 'correct error message'));
});

test('uploadFile differentiates network failures after upload', () => {
  const fakeAjaxLib = { post: sinon.stub(), get: sinon.stub() };
  fakeAjaxLib.post.onCall(0).resolves({ data: {
    upload_url: 'http://uploadUrl',
    success_url: 'http://successUrl'
  }}); // preflight
  fakeAjaxLib.post.onCall(1).resolves({ data: {} }); // upload
  fakeAjaxLib.get.rejects({ message: 'Network Error' }); // success url attempt
  return uploadFile('http://preflightUrl', {}, sinon.stub(), fakeAjaxLib)
    .then(() => ok(false, 'finalization should fail'))
    .catch(({ message }) => ok(message.match(/failed to complete the upload/), 'correct error message'));
});
