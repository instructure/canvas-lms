define([
  'jsx/course_settings/actions'
], (Actions) => {

  QUnit.module('Course Settings Actions');

  test('calling setModalVisibility produces the proper object', () => {
    let actual = Actions.setModalVisibility(true);
    let expected = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: true
      }
    };

    deepEqual(actual, expected, 'the objects match');

    actual = Actions.setModalVisibility(false);
    expected = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: false
      }
    };
  });

  test('calling gotCourseImage produces the proper object', () => {
    const actual = Actions.gotCourseImage('http://imageUrl');
    const expected = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageUrl: 'http://imageUrl'
      }
    };

    deepEqual(actual, expected, 'the objects match');
  });

  asyncTest('getCourseImage', () => {
    const fakeResponse = {
      data: {
        image: 'http://imageUrl'
      }
    };

    const fakeAjaxLib = {
      get (url) {
        return new Promise((resolve) => {
          setTimeout(() => resolve(fakeResponse), 100);
        });
      }
    };

    const expectedAction = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageUrl: 'http://imageUrl'
      }
    };

    Actions.getCourseImage(1, fakeAjaxLib)((dispatched) => {
      start();
      deepEqual(dispatched, expectedAction, 'the proper action was dispatched');
    });
  });

  test('setCourseImageId creates the proper action', () => {
    const actual = Actions.setCourseImageId('http://imageUrl', 12);
    const expected = {
      type: 'SET_COURSE_IMAGE_ID',
      payload: {
        imageUrl: 'http://imageUrl',
        imageId: 12
      }
    };

    deepEqual(actual, expected, 'the objects match');
  });

  test('prepareSetImage with a imageUrl calls putImageData', () => {
    sinon.spy(Actions, 'putImageData');
    Actions.prepareSetImage('http://imageUrl', 12, 0);
    ok(Actions.putImageData.called, 'putImageData was called');
    Actions.putImageData.restore();
  });

  asyncTest('prepareSetImage without a imageUrl calls the API to get the url', () => {
    const fakeResponse = {
      data: {
        url: 'http://imageUrl'
      }
    };

    const fakeAjaxLib = {
      get (url) {
        return new Promise((resolve) => {
          setTimeout(() => resolve(fakeResponse), 100);
        });
      }
    };

    sinon.spy(Actions, 'putImageData');

    Actions.prepareSetImage(null, 1, 0, fakeAjaxLib)((dispatched) => {
      start();
      ok(Actions.putImageData.called, 'putImageData was called indicating successfully hit API');
      Actions.putImageData.restore();
    });
  });

  asyncTest('uploadFile returns false when image is not valid', () => {
    const fakeDragonDropEvent = {
      dataTransfer: {
        files: [{
          name: 'test file',
          size: 12345,
          type: 'image/tiff'
        }]
      },
      preventDefault: () => {}
    };

    const expectedAction = {
      type: 'REJECTED_UPLOAD',
      payload: {
        rejectedFiletype: 'image/tiff'
      }
    };


    Actions.uploadFile(fakeDragonDropEvent, 1)((dispatched) => {
      start();
      deepEqual(dispatched, expectedAction, 'the REJECTED_UPLOAD action was fired');
    });

  });

  asyncTest('uploadFile dispatches UPLOADING_IMAGE when file type is valid', () => {
    const fakeDragonDropEvent = {
      dataTransfer: {
        files: [{
          name: 'test file',
          size: 12345,
          type: 'image/jpeg'
        }]
      },
      preventDefault: () => {}
    };

    const expectedAction = {
      type: 'UPLOADING_IMAGE'
    };

    Actions.uploadFile(fakeDragonDropEvent, 1)((dispatched) => {
        if (dispatched.type === 'UPLOADING_IMAGE') {
          start();
          deepEqual(dispatched, expectedAction, 'the UPLOADING_IMAGE action was fired');
        }
    });
  });

  asyncTest('uploadFile dispatches prepareSetImage when successful', () => {
    const firstCallPromise = new Promise((resolve) => {
      setTimeout(() => resolve({
        data: {
          upload_params: {fakeKey: 'fakeValue'},
          upload_url: 'http://uploadUrl'
        }
      }));
    });

    const secondCallPromise = new Promise((resolve) => {
      setTimeout(() => resolve({
        data: {
          url: 'http://fileDownloadUrl',
          id: 1
        }
      }));
    })

    const postStub = sinon.stub();
    postStub.onCall(0).returns(firstCallPromise)
    postStub.onCall(1).returns(secondCallPromise);

    const fakeAjaxLib = {
      post: postStub
    };

    const fakeDragonDropEvent = {
      dataTransfer: {
        files: [{
          name: 'test file',
          size: 12345,
          type: 'image/jpeg'
        }]
      },
      preventDefault: () => {}
    };

    sinon.spy(Actions, 'prepareSetImage');

    Actions.uploadFile(fakeDragonDropEvent, 1, fakeAjaxLib)((dispatched) => {
      if (dispatched.type !== 'UPLOADING_IMAGE') {
        start();
        ok(Actions.prepareSetImage.called, 'prepareSetImage was called');
        Actions.prepareSetImage.restore();
      }
    });
  })

});