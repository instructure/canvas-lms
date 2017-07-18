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

import Fixtures from 'spec/jsx/gradebook-history/Fixtures';
import parseLinkHeader from 'jsx/shared/parseLinkHeader';
import reducer from 'jsx/gradebook-history/reducers/SearchFormReducer';
import {
  FETCH_USERS_BY_NAME_START,
  FETCH_USERS_BY_NAME_SUCCESS,
  FETCH_USERS_BY_NAME_FAILURE,
  FETCH_USERS_NEXT_PAGE_START,
  FETCH_USERS_NEXT_PAGE_SUCCESS,
  FETCH_USERS_NEXT_PAGE_FAILURE
} from 'jsx/gradebook-history/actions/SearchFormActions';

const defaultState = () => (
  {
    options: {
      graders: {
        fetchStatus: null,
        items: [],
        nextPage: null
      },
      students: {
        fetchStatus: null,
        items: [],
        nextPage: null
      }
    },
  }
)

QUnit.module('SearchFormReducer');

test('returns the current state by default', function () {
  const currState = defaultState();
  deepEqual(reducer(currState, {}), currState);
});

test('handles FETCH_USERS_BY_NAME_START for given user type', function () {
  const defaults = defaultState();
  const initialState = {
    ...defaults,
    options: {
      ...defaults.options,
      graders: {
        ...defaults.options.graders,
        fetchStatus: null
      }
    }
  };
  const newState = {
    ...initialState,
    options: {
      ...initialState.options,
      graders: {
        ...initialState.options.graders,
        fetchStatus: 'started'
      }
    }
  };
  const action = {
    type: FETCH_USERS_BY_NAME_START,
    payload: {
      userType: 'graders'
    }
  };

  deepEqual(reducer(initialState, action), newState);
});

test('handles FETCH_USERS_BY_NAME_SUCCESS for given user type', function () {
  const payload = {
    userType: 'graders',
    data: Fixtures.userArray(),
    link: '<http://fake.url/3?&page=first>; rel="current",<http://fake.url/3?&page=bookmark:asdf>; rel="next"'
  };
  const initialState = defaultState();
  const newState = {
    ...initialState,
    options: {
      ...initialState.options,
      graders: {
        fetchStatus: 'success',
        items: payload.data,
        nextPage: parseLinkHeader(payload.link).next
      }
    }
  };
  const action = {
    type: FETCH_USERS_BY_NAME_SUCCESS,
    payload
  };

  deepEqual(reducer(initialState, action), newState);
});

test('handles FETCH_USERS_BY_NAME_FAILURE for given user type', function () {
  const defaults = defaultState();
  const initialState = {
    ...defaults,
    options: {
      ...defaults.options,
      students: {
        fetchStatus: 'started',
        items: Fixtures.userArray(),
        nextPage: null
      }
    }
  };
  const newState = {
    ...initialState,
    options: {
      ...initialState.options,
      students: {
        fetchStatus: 'failure',
        items: [],
        nextPage: null
      }
    }
  };
  const action = {
    type: FETCH_USERS_BY_NAME_FAILURE,
    payload: { userType: 'students' }
  };

  deepEqual(reducer(initialState, action), newState);
});

test('handles FETCH_USERS_NEXT_PAGE_START for given user type', function () {
  const defaults = defaultState();
  const initialState = {
    ...defaults,
    options: {
      ...defaults.options,
      students: {
        fetchStatus: null,
        items: Fixtures.userArray(),
        nextPage: 'https://fake.url'
      }
    }
  };
  const newState = {
    ...initialState,
    options: {
      ...initialState.options,
      students: {
        ...initialState.options.students,
        fetchStatus: 'started',
        nextPage: null
      }
    }
  };
  const action = {
    type: FETCH_USERS_NEXT_PAGE_START,
    payload: { userType: 'students' }
  };

  deepEqual(reducer(initialState, action), newState);
});

test('handles FETCH_USERS_NEXT_PAGE_SUCCESS for given user type', function () {
  const defaults = defaultState();
  const payload = {
    userType: 'graders',
    data: Fixtures.userArray(),
    link: '<http://fake.url/3?&page=first>; rel="current",<http://fake.url/3?&page=bookmark:asdf>; rel="next"'
  };
  const initialState = {
    ...defaults,
    options: {
      ...defaults.options,
      graders: {
        fetchStatus: 'started',
        items: Fixtures.userArray(),
        nextPage: null
      }
    }
  };
  const newState = {
    ...initialState,
    options: {
      ...initialState.options,
      graders: {
        ...initialState.options.graders,
        fetchStatus: 'success',
        items: initialState.options.graders.items.concat(payload.data),
        nextPage: parseLinkHeader(payload.link).next
      }
    }
  };
  const action = {
    type: FETCH_USERS_NEXT_PAGE_SUCCESS,
    payload
  };

  deepEqual(reducer(initialState, action), newState);
});

test('handles FETCH_USERS_NEXT_PAGE_FAILURE for given user type', function () {
  const defaults = defaultState();
  const initialState = {
    ...defaults,
    options: {
      ...defaults.options,
      students: {
        fetchStatus: 'started',
        items: Fixtures.userArray(),
        nextPage: 'https://fake.url'
      }
    }
  };
  const newState = {
    ...initialState,
    options: {
      ...initialState.options,
      students: {
        ...initialState.options.students,
        fetchStatus: 'failure',
        nextPage: null
      }
    }
  };
  const action = {
    type: FETCH_USERS_NEXT_PAGE_FAILURE,
    payload: { userType: 'students' }
  };

  deepEqual(reducer(initialState, action), newState);
});
