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

import GridEvent from 'jsx/gradezilla/default_gradebook/GradebookGrid/GridSupport/GridEvent';

QUnit.module('GridEvent', function (hooks) {
  hooks.beforeEach(function () {
    this.supportEvent = new GridEvent();
    this.spyValues = [];
  });

  QUnit.module('#trigger');

  test('executes all subscribed handlers in order of subscription', function () {
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(1) });
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(2) });
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(3) });
    this.supportEvent.trigger();
    deepEqual(this.spyValues, [1, 2, 3]);
  });

  test('includes the given event with each trigger', function () {
    const exampleEvent = new Event('example');
    this.supportEvent.subscribe((event, _datum) => { this.spyValues.push(event) });
    this.supportEvent.subscribe((event, _datum) => { this.spyValues.push(event) });
    this.supportEvent.subscribe((event, _datum) => { this.spyValues.push(event) });
    this.supportEvent.trigger(exampleEvent);
    deepEqual(this.spyValues, [exampleEvent, exampleEvent, exampleEvent]);
  });

  test('includes optional data with each trigger', function () {
    this.supportEvent.subscribe((_event, datum) => { this.spyValues.push(datum) });
    this.supportEvent.subscribe((_event, datum) => { this.spyValues.push(datum) });
    this.supportEvent.subscribe((_event, datum) => { this.spyValues.push(datum) });
    this.supportEvent.trigger(null, 'example datum');
    deepEqual(this.spyValues, ['example datum', 'example datum', 'example datum']);
  });

  test('does not call subsequent handlers after any one returns false', function () {
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(1) });
    this.supportEvent.subscribe((_event, _datum) => {
      this.spyValues.push(2);
      return false;
    });
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(3) });
    this.supportEvent.trigger();
    deepEqual(this.spyValues, [1, 2]);
  });

  test('does not call unsubscribed handlers', function () {
    const handler = (_event, _datum) => { this.spyValues.push(2) };
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(1) });
    this.supportEvent.subscribe(handler);
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(3) });
    this.supportEvent.unsubscribe(handler);
    this.supportEvent.trigger();
    deepEqual(this.spyValues, [1, 3]);
  });

  test('does not subscribe the same handler multiple times', function () {
    const handler = (_event, _datum) => { this.spyValues.push(2) };
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(1) });
    this.supportEvent.subscribe(handler);
    this.supportEvent.subscribe((_event, _datum) => { this.spyValues.push(3) });
    this.supportEvent.subscribe(handler);
    this.supportEvent.trigger();
    deepEqual(this.spyValues, [1, 2, 3]);
  });
});
