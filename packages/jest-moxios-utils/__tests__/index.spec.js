/*
 * Copyright (C) 2018 - present Instructure, Inc.
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


import axios from 'axios';
import moxios from 'moxios';
import {moxiosWait, moxiosRespond} from '../index';

describe('moxiosWait', () => {
  it('rejects if the passed function throws', () => {
    const waitPromise = moxiosWait(() => {
      throw new Error('intentional error for testing');
    });
    return new Promise((resolve, reject) => {
      waitPromise
        .then(() => reject('did not expect waitPromise to resolve'))
        .catch(() => resolve('yay, this is what its supposed to do'))
      ;
    });
  });
});

describe('moxiosRespond', () => {
  beforeEach(() => {
    moxios.install();
  });

  afterEach(() => {
    moxios.uninstall();
  });

  it('throws if the request promise parameter is missing', () => {
    expect(() => moxiosRespond('blah')).toThrow();
  });

  it('merges options into the response', () => {
    const requestPromise = axios.get('http://example.com');
    const responsePromise = moxiosRespond({some: 'data'}, requestPromise, {status: 418, headers: {key: 'value'}});
    return responsePromise.catch((err) => {
      expect(err.response.data).toMatchObject({some: 'data'});
      expect(err.response.headers).toMatchObject({key: 'value'});
      expect(err.response.status).toBe(418);
    });
  });
});
