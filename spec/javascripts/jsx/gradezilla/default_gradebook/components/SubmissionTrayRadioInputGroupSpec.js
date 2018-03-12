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

function mountComponent (customProps) {
  const props = {
    colors: {
      late: '#FEF7E5',
      missing: '#F99',
      excused: '#E5F3FC'
    },
    disabled: false,
    latePolicy: { lateSubmissionInterval: 'day' },
    locale: 'en',
    submission: { excused: false, late: false, missing: false, secondsLate: 0 },
    submissionUpdating: false,
    updateSubmission () {},
    ...customProps
  };

  return mount(<SubmissionTrayRadioInputGroup {...props} />);
}

QUnit.module('SubmissionTrayRadioInputGroup', {
  getRadioOption (value) {
    return this.wrapper.find(`input[type="radio"][value="${value}"]`).node;
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders FormFieldGroup enabled if disabled is false', function () {
  this.wrapper = mountComponent({ disabled: false });
  strictEqual(this.wrapper.find('FormFieldGroup').props().disabled, false);
});

test('renders FormFieldGroup disabled if disabled is true', function () {
  this.wrapper = mountComponent({ disabled: true });
  strictEqual(this.wrapper.find('FormFieldGroup').props().disabled, true);
});

test('renders all SubmissionTrayRadioInputs enabled if disabled is false', function () {
  this.wrapper = mountComponent({ disabled: false });
  const inputDisabledStatus = this.wrapper.find('SubmissionTrayRadioInput').map((input) => input.props().disabled);
  deepEqual(inputDisabledStatus, [false, false, false, false]);
});

test('renders all SubmissionTrayRadioInputs disabled if disabled is false', function () {
  this.wrapper = mountComponent({ disabled: true });
  const inputDisabledStatus = this.wrapper.find('SubmissionTrayRadioInput').map((input) => input.props().disabled);
  deepEqual(inputDisabledStatus, [true, true, true, true]);
});

test('renders with "none" selected if the submission is not late, missing, or excused', function () {
  this.wrapper = mountComponent();
  const radio = this.getRadioOption('none');
  strictEqual(radio.checked, true);
});

test('renders with "Excused" selected if the submission is excused', function () {
  this.wrapper = mountComponent({ submission: { excused: true, late: false, missing: false, secondsLate: 0 } });
  const radio = this.getRadioOption('excused');
  strictEqual(radio.checked, true);
});

test('renders with "Excused" selected if the submission is excused and also late', function () {
  this.wrapper = mountComponent({ submission: { excused: true, late: true, missing: false, secondsLate: 0 } });
  const radio = this.getRadioOption('excused');
  strictEqual(radio.checked, true);
});

test('renders with "Excused" selected if the submission is excused and also missing', function () {
  this.wrapper = mountComponent({ submission: { excused: true, late: false, missing: true, secondsLate: 0 } });
  const radio = this.getRadioOption('excused');
  strictEqual(radio.checked, true);
});

test('renders with "Late" selected if the submission is not excused and is late', function () {
  this.wrapper = mountComponent({ submission: { excused: false, late: true, missing: false, secondsLate: 60 } });
  const radio = this.getRadioOption('late');
  strictEqual(radio.checked, true);
});

test('renders with "Missing" selected if the submission is not excused and is missing', function () {
  this.wrapper = mountComponent({ submission: { excused: false, late: false, missing: true, secondsLate: 0 } });
  const radio = this.getRadioOption('missing');
  strictEqual(radio.checked, true);
});

QUnit.module('SubmissionTrayRadioInputGroup#handleRadioInputChanged', function(suiteHooks) {
  let wrapper
  let updateSubmission

  suiteHooks.beforeEach(function () {
    updateSubmission = sinon.stub()
    wrapper = mountComponent({ updateSubmission })
  })

  suiteHooks.afterEach(function () {
    wrapper.unmount()
  })

  test('calls updateSubmission with the late policy status for the selected radio input', function () {
    const event = { target: { value: 'missing' } }
    wrapper.instance().handleRadioInputChanged(event)
    strictEqual(updateSubmission.callCount, 1)
    deepEqual(updateSubmission.getCall(0).args[0], { latePolicyStatus: 'missing' })
  })

  test('calls updateSubmission with secondsLateOverride set to 0 if the "late" option is selected', function () {
    const event = { target: { value: 'late' } }
    wrapper.instance().handleRadioInputChanged(event)
    strictEqual(updateSubmission.callCount, 1)
    deepEqual(updateSubmission.getCall(0).args[0], { latePolicyStatus: 'late', secondsLateOverride: 0 })
  })

  test('calls updateSubmission with excuse set to true if the "excused" option is selected', function () {
    const event = { target: { value: 'excused' } }
    wrapper.instance().handleRadioInputChanged(event)
    strictEqual(updateSubmission.callCount, 1)
    deepEqual(updateSubmission.getCall(0).args[0], { excuse: true })
  })

  test('does not call updateSubmission if the radio input is already selected', function () {
    const event = { target: { value: 'none' } }
    wrapper.instance().handleRadioInputChanged(event)
    strictEqual(updateSubmission.callCount, 0)
  })

  test('does not queue up an update if there is not an update in flight', function () {
    const event = { target: { value: 'excused' } }
    wrapper.instance().handleRadioInputChanged(event)
    wrapper.setProps({ submissionUpdating: true })
    // if there were any queued updates, they would execute when the submission was done updating
    wrapper.setProps({ submissionUpdating: false })
    strictEqual(updateSubmission.callCount, 1)
  })

  QUnit.module('when a submission update is in flight', function (hooks) {
    hooks.beforeEach(function () {
      wrapper = mountComponent({ updateSubmission, submissionUpdating: true })
    })

    test('does not call updateSubmission', function () {
      const event = { target: { value: 'missing' } }
      wrapper.instance().handleRadioInputChanged(event)
      strictEqual(updateSubmission.callCount, 0)
    })

    test('queues up an update to be executed when the in-flight update is finished', function () {
      const event = { target: { value: 'missing' } }
      wrapper.instance().handleRadioInputChanged(event)
      wrapper.setProps({ submissionUpdating: false })
      strictEqual(updateSubmission.callCount, 1)
    })

    test('queues up the update even it if matches the currently selected value', function () {
      const event = { target: { value: 'none' } }
      wrapper.instance().handleRadioInputChanged(event)
      wrapper.setProps({ submissionUpdating: false })
      strictEqual(updateSubmission.callCount, 1)
    })

    test('only queues up one of multiple updates', function () {
      const firstEvent = { target: { value: 'missing' } }
      wrapper.instance().handleRadioInputChanged(firstEvent)
      const secondEvent = { target: { value: 'excused' } }
      wrapper.instance().handleRadioInputChanged(secondEvent)
      wrapper.setProps({ submissionUpdating: false })
      strictEqual(updateSubmission.callCount, 1)
    })

    test('queues up only the most recent update', function () {
      const firstEvent = { target: { value: 'missing' } }
      wrapper.instance().handleRadioInputChanged(firstEvent)
      const secondEvent = { target: { value: 'excused' } }
      wrapper.instance().handleRadioInputChanged(secondEvent)

      wrapper.setProps({ submissionUpdating: false })
      deepEqual(updateSubmission.getCall(0).args[0], { excuse: true })
    })
  })
})
