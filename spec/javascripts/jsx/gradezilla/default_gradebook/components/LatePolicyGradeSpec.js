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
import LatePolicyGrade from 'jsx/gradezilla/default_gradebook/components/LatePolicyGrade';

QUnit.module('LatePolicyGrade', function (hooks) {
  let wrapper;

  hooks.afterEach(function () {
    wrapper.unmount();
  });

  function mountComponent (props = {}) {
    const defaultProps = {
      submission: {
        grade: '70%',
        pointsDeducted: 3
      }
    };
    wrapper = mount(<LatePolicyGrade {...defaultProps} {...props} />);
  }

  test('includes the late penalty as a negative value', function () {
    mountComponent();
    ok(wrapper.find('#late-penalty-value').text().includes('-3'));
  });

  test('includes the final grade', function () {
    mountComponent();
    ok(wrapper.find('#final-grade-value').text().includes('70%'));
  });

  test('rounds the final grade when a decimal value', function () {
    mountComponent({ submission: { grade: '7.345', pointsDeducted: 3 } });
    ok(wrapper.find('#final-grade-value').text().includes('7.35'));
  });

  test('rounds the final grade when a decimal percentage', function () {
    mountComponent({ submission: { grade: '73.456%', pointsDeducted: 3 } });
    ok(wrapper.find('#final-grade-value').text().includes('73.46%'));
  });

  test('includes the final grade without formatting when not a number', function () {
    mountComponent({ submission: { grade: 'C+', pointsDeducted: 3 } });
    ok(wrapper.find('#final-grade-value').text().includes('C+'));
  });
});
