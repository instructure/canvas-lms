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
import SubmissionTrayRadioInputGroup from 'jsx/gradezilla/default_gradebook/components/SubmissionTrayRadioInputGroup';

QUnit.module('SubmissionTrayRadioInputGroup', {
  mountComponent (customProps) {
    const props = {
      colors: {
        late: '#FEF7E5',
        missing: '#F99',
        excused: '#E5F3FC'
      },
      latePolicy: { lateSubmissionInterval: 'day' },
      locale: 'en',
      submission: { excused: false, late: false, missing: false, secondsLate: 0 },
      ...customProps
    };
    return mount(<SubmissionTrayRadioInputGroup {...props} />);
  },

  getRadioOption (value) {
    return this.wrapper.find(`input[type="radio"][value="${value}"]`).node;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('initializes with "none" selected if the submission is not late, missing, or excused', function () {
  this.wrapper = this.mountComponent();
  const radio = this.getRadioOption('none');
  strictEqual(radio.checked, true);
});

test('initializes with "Excused" selected if the submission is excused', function () {
  this.wrapper = this.mountComponent({ submission: { excused: true, late: false, missing: false, secondsLate: 0 } });
  const radio = this.getRadioOption('excused');
  strictEqual(radio.checked, true);
});

test('initializes with "Excused" selected if the submission is excused and also late', function () {
  this.wrapper = this.mountComponent({ submission: { excused: true, late: true, missing: false, secondsLate: 0 } });
  const radio = this.getRadioOption('excused');
  strictEqual(radio.checked, true);
});

test('initializes with "Excused" selected if the submission is excused and also missing', function () {
  this.wrapper = this.mountComponent({ submission: { excused: true, late: false, missing: true, secondsLate: 0 } });
  const radio = this.getRadioOption('excused');
  strictEqual(radio.checked, true);
});

test('initializes with "Late" selected if the submission is not excused and is late', function () {
  this.wrapper = this.mountComponent({ submission: { excused: false, late: true, missing: false, secondsLate: 60 } });
  const radio = this.getRadioOption('late');
  strictEqual(radio.checked, true);
});

test('initializes with "Missing" selected if the submission is not excused and is missing', function () {
  this.wrapper = this.mountComponent({ submission: { excused: false, late: false, missing: true, secondsLate: 0 } });
  const radio = this.getRadioOption('missing');
  strictEqual(radio.checked, true);
});

test('handleRadioInputChanged selects the radio option it is passed', function () {
  this.wrapper = this.mountComponent();
  const event = { target: { value: 'late' } };
  this.wrapper.instance().handleRadioInputChanged(event);
  const radio = this.getRadioOption('late');
  strictEqual(radio.checked, true);
});

test('handleRadioInputChanged deselects the previously selected radio option', function () {
  this.wrapper = this.mountComponent();
  const event = { target: { value: 'late' } };
  this.wrapper.instance().handleRadioInputChanged(event);
  const radio = this.getRadioOption('none');
  strictEqual(radio.checked, false);
});
