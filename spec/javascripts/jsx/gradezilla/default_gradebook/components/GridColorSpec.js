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

import React from 'react';
import { mount, shallow } from 'enzyme';
import GridColor from 'jsx/gradezilla/default_gradebook/components/GridColor';
import { light, dark } from 'jsx/gradezilla/default_gradebook/constants/colors';

QUnit.module('GridColor');

test('it renders style', function () {
  const wrapper = shallow(<GridColor colors={{}} />);
  strictEqual(wrapper.find('style[type="text/css"]').length, 1);
});

test('it has light blue as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(light.blue));
});

test('it has light purple as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(light.purple));
});

test('it has light green as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(light.green));
});

test('it has light orange as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(light.orange));
});

test('it has light yellow as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(light.yellow));
});

test('it has dark blue as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(dark.blue));
});

test('it has dark purple as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(dark.purple));
});

test('it has dark green as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(dark.green));
});

test('it has dark orange as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(dark.orange));
});

test('it has dark yellow as a default color', function () {
  const wrapper = mount(<GridColor colors={{}} />);
  ok(wrapper.html().includes(dark.yellow));
});

test('rules are for .gradebook-cell and .`statuses`', function () {
  const wrapper = mount(<GridColor colors={{}} statuses={['late']} />);
  equal(wrapper.html(),
    '<style type="text/css">' +
    `.even .gradebook-cell.late { background-color: ${light.blue}; }` +
    `.odd .gradebook-cell.late { background-color: ${dark.blue}; }` +
    '.slick-cell.editable .gradebook-cell.late { background-color: white; }' +
    '</style>'
  );
});

test('multiple state rules are concatenated', function () {
  const wrapper = shallow(<GridColor colors={{}} statuses={['late', 'missing']} />);
  const expected = (
    <style type="text/css">
      {
        `.even .gradebook-cell.late { background-color: ${light.blue}; }` +
        `.odd .gradebook-cell.late { background-color: ${dark.blue}; }` +
        '.slick-cell.editable .gradebook-cell.late { background-color: white; }' +
        `.even .gradebook-cell.missing { background-color: ${light.purple}; }` +
        `.odd .gradebook-cell.missing { background-color: ${dark.purple}; }` +
        '.slick-cell.editable .gradebook-cell.missing { background-color: white; }'
      }
    </style>
  );
  ok(wrapper.equals(expected));
});
