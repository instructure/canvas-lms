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

import * as Actions from 'jsx/dashboard/ToDoSidebar/actions';
import moxios from 'moxios';
import moment from 'moment-timezone';

QUnit.module('loadItems', {
  setup () {
    moxios.install();
  },
  teardown () {
    moxios.uninstall();
  }
});

test('dispatches ITEMS_LOADING action initially', () => {
  const thunk = Actions.loadInitialItems(moment().startOf('day'));
  const fakeDispatch = sinon.spy();
  thunk(fakeDispatch);
  const expected = {
    type: 'ITEMS_LOADING'
  };
  ok(fakeDispatch.firstCall.calledWith(expected));
});

test('dispatches ITEMS_LOADED with the proper payload on success', (assert) => {
  const done = assert.async();
  const thunk = Actions.loadInitialItems(moment().startOf('day'));
  const fakeDispatch = sinon.spy();
  thunk(fakeDispatch);
  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    request.respondWith({
      status: 200,
      headers: {
        link: '</>; rel="current"'
      },
      response: [{ id: 1 }, { id: 2 }]
    }).then(() => {
      const expected = {
        type: 'ITEMS_LOADED',
        payload: { items: [{ id: 1 }, { id: 2 }], nextUrl: null }
      };
      deepEqual(fakeDispatch.secondCall.args[0], expected);
      done();
    })
  });
});

test('dispatches ITEMS_LOADED with the proper url on success', (assert) => {
  const done = assert.async();
  const thunk = Actions.loadInitialItems(moment().startOf('day'));
  const fakeDispatch = sinon.spy();
  thunk(fakeDispatch);
  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    request.respondWith({
      status: 200,
      headers: {
        link: '</>; rel="next"'
      },
      response: [{ id: 1 }, { id: 2 }]
    }).then(() => {
      const expected = {
        type: 'ITEMS_LOADED',
        payload: { items: [{ id: 1 }, { id: 2 }], nextUrl: '/' }
      };
      deepEqual(fakeDispatch.secondCall.args[0], expected);
      done();
    })
  });
});

test('dispatches ITEMS_LOADED when initial load gets them all', (assert) => {
  const done = assert.async();
  const thunk = Actions.loadInitialItems(moment().startOf('day'));
  const fakeDispatch = sinon.spy();
  thunk(fakeDispatch);
  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    request.respondWith({
      status: 200,
      headers: {
      },
      response: [{ id: 1 }, { id: 2 }]
    }).then(() => {
      const expected = {
        type: 'ITEMS_LOADED',
        payload: { items: [{ id: 1 }, { id: 2 }], nextUrl: null }
      };
      deepEqual(fakeDispatch.secondCall.args[0], expected);
      done();
    })
  });
});


test('dispatches ITEMS_LOADING_FAILED on failure', (assert) => {
  const done = assert.async();
  const thunk = Actions.loadInitialItems(moment().startOf('day'));
  const fakeDispatch = sinon.spy();
  thunk(fakeDispatch);
  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    request.respondWith({
      status: 500,
      response: { error: 'Something terrible' }
    }).then(() => {
      equal(fakeDispatch.secondCall.args[0].type, 'ITEMS_LOADING_FAILED');
      ok(fakeDispatch.secondCall.args[0].error);
      done();
    })
  });
});

QUnit.module('completeItem', {
  setup () {
    moxios.install();
  },
  teardown () {
    moxios.uninstall();
  }
});

test('dispatches ITEM_SAVING initially', () => {
  const thunk = Actions.completeItem('assignment', '1');
  const fakeDispatch = sinon.spy();
  const fakeGetState = () => ({
    items: [{
      plannable_id: '1',
      plannable_type: 'assignment'
    }]
  })
  thunk(fakeDispatch, fakeGetState);
  const expected = {
    type: 'ITEM_SAVING'
  };
  ok(fakeDispatch.firstCall.calledWith(expected));
});

test('sends a PUT request and dispatches ITEM_SAVED on success if the item to complete already has an override', (assert) => {
  const done = assert.async();
  const thunk = Actions.completeItem('assignment', '1');
  const fakeDispatch = sinon.spy();
  const fakeGetState = () => ({
    items: [{
      plannable_id: '1',
      plannable_type: 'assignment',
      planner_override: {
        marked_complete: false
      }
    }]
  })
  thunk(fakeDispatch, fakeGetState);
  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    request.respondWith({
      status: 200,
      response: { marked_complete: true }
    }).then(() => {
      const expected = {
        type: 'ITEM_SAVED',
        payload: {
          marked_complete: true
        }
      }
      equal(request.config.method, 'put');
      deepEqual(fakeDispatch.secondCall.args[0], expected);
      done();
    })
  });
});

test('sends a POST request and dispatches ITEM_SAVED on success if the item to complete does not have an override', (assert) => {
  const done = assert.async();
  const thunk = Actions.completeItem('assignment', '1');
  const fakeDispatch = sinon.spy();
  const fakeGetState = () => ({
    items: [{
      plannable_id: '1',
      plannable_type: 'assignment',
    }]
  })
  thunk(fakeDispatch, fakeGetState);
  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    request.respondWith({
      status: 200,
      response: { marked_complete: true }
    }).then(() => {
      const expected = {
        type: 'ITEM_SAVED',
        payload: {
          marked_complete: true
        }
      }
      equal(request.config.method, 'post');
      deepEqual(fakeDispatch.secondCall.args[0], expected);
      done();
    })
  });
});

test('dispatches ITEM_SAVING_FAILED on failure', (assert) => {
  const done = assert.async();
  const thunk = Actions.completeItem('assignment', '1');
  const fakeDispatch = sinon.spy();
  const fakeGetState = () => ({
    items: [{
      plannable_id: '1',
      plannable_type: 'assignment',
    }]
  })
  thunk(fakeDispatch, fakeGetState);
  moxios.wait(() => {
    const request = moxios.requests.mostRecent();
    request.respondWith({
      status: 500,
      response: { error: 'Something terrible' }
    }).then(() => {
      equal(fakeDispatch.secondCall.args[0].type, 'ITEM_SAVING_FAILED');
      ok(fakeDispatch.secondCall.args[0].error);
      done();
    })
  });
});
