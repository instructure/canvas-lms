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
import { mount } from 'enzyme';
import AssignmentRowCell from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCell';

QUnit.module('AssignmentRowCell');

test('containerRef prop refers to a child container', function () {
  let container;
  function containerRef (ref) { container = ref }
  const wrapper = mount(<AssignmentRowCell containerRef={containerRef} />);
  ok(wrapper.contains(container), 'component node contains the referenced container node');
});
