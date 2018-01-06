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
import $ from 'jquery';
import JQuerySelectorCache from 'jsx/shared/helpers/JQuerySelectorCache';

QUnit.module('JQuerySelectorCache', function (hooks) {
  let selectorCache;
  let fixtures;

  hooks.beforeEach(function () {
    fixtures = document.getElementById('fixtures');
    fixtures.innerHTML = '<div id="foo">testing!</div>';
    selectorCache = new JQuerySelectorCache();
  });

  hooks.afterEach(function () {
    fixtures.innerHTML = '';
  });

  QUnit.module('#get', function () {
    test('returns a jquery selector', function () {
      const response = selectorCache.get('#foo');
      strictEqual(response instanceof $, true);
    });

    test('returns the selector for the given element', function () {
      const response = selectorCache.get('#foo');
      strictEqual(response.text(), 'testing!');
    });

    test('returns a valid selector even if the element does not exist', function () {
      const response = selectorCache.get('#does_not_exist');
      strictEqual(response.length, 0);
    });

    test('reuses the cached value on subsequent requests', function () {
      const first = selectorCache.get('#foo');
      const second = selectorCache.get('#foo');
      strictEqual(first, second);
    });
  });

  QUnit.module('#set', function () {
    test('caches the value that subsequent `get` calls will use', function () {
      selectorCache.set('#foo');
      sinon.stub(selectorCache, 'set');
      selectorCache.get('#foo');
      // we verify the `get` call uses the cached value
      // by asserting that `set` is not called
      strictEqual(selectorCache.set.callCount, 0);
    });

    test('stores the appropriate selector for the given value', function () {
      selectorCache.set('#foo');
      const value = selectorCache.get('#foo');
      strictEqual(value.text(), 'testing!');
    });
  });
});
