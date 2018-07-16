/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'underscore',
  'axios',
  'jsx/grading/GradingPeriodSet',
  'compiled/api/gradingPeriodsApi'
], (React, ReactDOM, {Simulate}, _, axios, GradingPeriodSet, gradingPeriodsApi) => {
  const wrapper = document.getElementById('fixtures');

  function assertDisabled (component) {
    ok(component, 'expect element to exist');
    equal(component.props.disabled, true);
  }

  function assertEnabled (component) {
    ok(component, 'expect element to exist');
    equal(component.props.disabled, false);
  }

  const urls = {
    batchUpdateURL: 'api/v1/accounts/1/grading_period_sets',
    deleteGradingPeriodURL: 'api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D',
    gradingPeriodSetsURL: 'api/v1/accounts/1/grading_period_sets'
  };

  const allPermissions = {
    read: true,
    create: true,
    update: true,
    delete: true
  };

  const examplePeriods = [
    {
      id: '1',
      title: 'We did it! We did it! We did it! #dora #boots',
      weight: 33,
      startDate: new Date('2015-01-01T20:11:00+00:00'),
      endDate: new Date('2015-03-01T00:00:00+00:00'),
      closeDate: new Date('2015-03-01T00:00:00+00:00')
    }, {
      id: '3',
      title: 'Como estas?',
      weight: 25.75,
      startDate: new Date('2014-11-01T20:11:00+00:00'),
      endDate: new Date('2014-11-11T00:00:00+00:00'),
      closeDate: new Date('2014-11-11T00:00:00+00:00')
    }, {
      id: '2',
      title: 'Swiper no swiping!',
      weight: 0,
      startDate: new Date('2015-04-01T20:11:00+00:00'),
      endDate: new Date('2015-05-01T00:00:00+00:00'),
      closeDate: new Date('2015-05-01T00:00:00+00:00')
    }
  ];

  const examplePeriod = {
    id: '4',
    title: 'Example Period',
    weight: 25,
    startDate: new Date('2015-03-02T20:11:00+00:00'),
    endDate: new Date('2015-03-03T00:00:00+00:00'),
    closeDate: new Date('2015-03-03T00:00:00+00:00')
  };

  const props = {
    set: {
      id: '1',
      title: 'Example Set',
      weighted: true,
      displayTotalsForAllGradingPeriods: false
    },
    terms: [],
    onEdit () {},
    onDelete () {},
    onPeriodsChange () {},
    onToggleBody () {},
    gradingPeriods: examplePeriods,
    expanded: true,
    actionsDisabled: false,
    readOnly: false,
    urls,
    permissions: allPermissions
  };

  QUnit.module('GradingPeriodSet', {
    renderComponent (opts = {}) {
      const attrs = _.extend({}, props, opts);
      attrs.onDelete = sinon.stub();
      attrs.onEdit = sinon.stub();
      let component;
      attrs.ref = (ref) => { component = ref };
      ReactDOM.render(React.createElement(GradingPeriodSet, attrs), wrapper);
      return component;
    },

    stubDeleteSuccess () {
      const successPromise = Promise.resolve();
      sandbox.stub(axios, 'delete').returns(successPromise);
      return successPromise;
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('renders without set body when the "expanded" property is false', function () {
    const set = this.renderComponent({ expanded: false });
    notOk(!!set.refs.setBody);
  });

  test('renders with set body when the "expanded" property is true', function () {
    const set = this.renderComponent({ expanded: true });
    ok(set.refs.setBody);
  });

  test('expands the set body when the toggle is clicked', function () {
    const spy = sinon.spy();
    const set = this.renderComponent({ onToggleBody: spy });
    Simulate.click(set.refs.toggleSetBody);
    ok(spy.calledOnce);
  });

  test('disables action buttons when "actionsDisabled" is true', function () {
    const set = this.renderComponent({ actionsDisabled: true });
    assertDisabled(set.refs.editButton);
    assertDisabled(set.refs.deleteButton);
  });

  test('disables the "add grading period" button when "actionsDisabled" is true', function () {
    const set = this.renderComponent({ actionsDisabled: true });
    assertDisabled(set.refs.addPeriodButton);
  });

  test('disables grading period action buttons when "actionsDisabled" is true', function () {
    const set = this.renderComponent({ actionsDisabled: true });
    ok(set.refs['show-grading-period-2'].props.actionsDisabled);
    ok(set.refs['show-grading-period-3'].props.actionsDisabled);
  });

  test('sorts grading periods by start date, ascending', function () {
    const set = this.renderComponent();
    const periods = set.refs.gradingPeriodList.props.children;
    const startDates = _.map(periods, period => period.props.period.startDate);
    ok((startDates[0] < startDates[1]) && (startDates[1] < startDates[2]));
  });

  test('calls the onEdit prop when the "edit grading period set" button is clicked', function () {
    const set = this.renderComponent();
    set.refs.editButton.handleClick(new MouseEvent('click'));
    ok(set.props.onEdit.calledOnce);
    equal(set.props.onEdit.args[0][0], set.props.set);
  });

  test('does not delete the set if the user cancels the delete confirmation', function () {
    sandbox.stub(axios, 'delete');
    sandbox.stub(window, 'confirm').returns(false);
    const set = this.renderComponent();
    set.refs.deleteButton.handleClick(new MouseEvent('click'));
    ok(set.props.onDelete.notCalled);
  });

  test('deletes the set if the user confirms deletion', function () {
    const deletePromise = this.stubDeleteSuccess();
    sandbox.stub(window, 'confirm').returns(true);
    const set = this.renderComponent();
    set.refs.deleteButton.handleClick(new MouseEvent('click'));
    return deletePromise.then(() => {
      ok(set.props.onDelete.calledOnce);
    });
  });

  QUnit.module('GradingPeriodSet "Edit Grading Period"', {
    renderComponent (opts = {}) {
      const attrs = _.extend({}, props, opts);
      let component;
      attrs.ref = (ref) => { component = ref };
      ReactDOM.render(React.createElement(GradingPeriodSet, attrs), wrapper);
      return component;
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('renders the "GradingPeriodForm" when "edit grading period" is clicked', function () {
    const set = this.renderComponent();
    notOk(!!set.refs.editPeriodForm);
    set.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
    ok(set.refs.editPeriodForm);
  });

  test('disables all grading period actions while open', function () {
    const set = this.renderComponent();
    notOk(!!set.refs.editPeriodForm);
    set.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
    assertDisabled(set.refs.addPeriodButton);
    ok(set.refs['show-grading-period-2'].props.actionsDisabled);
    ok(set.refs['show-grading-period-3'].props.actionsDisabled);
  });

  test('disables set toggling while open', function () {
    const spy = sinon.spy();
    const set = this.renderComponent({ onToggleBody: spy });
    set.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
    Simulate.click(set.refs.toggleSetBody);
    notOk(spy.called);
  });

  test('"onCancel" removes the "edit grading period" form', function () {
    const set = this.renderComponent();
    set.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
    set.refs.editPeriodForm.props.onCancel();
    notOk(!!set.refs.editPeriodForm);
  });

  test('"onCancel" focuses on the "edit grading period" button', function () {
    const set = this.renderComponent();
    set.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
    set.refs.editPeriodForm.props.onCancel();
    ok(set.refs['show-grading-period-1'].refs.editButton.focused);
  });

  test('"onCancel" re-enables all grading period actions', function () {
    const set = this.renderComponent();
    set.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
    set.refs.editPeriodForm.props.onCancel();
    assertEnabled(set.refs.addPeriodButton);
    notOk(set.refs['show-grading-period-1'].props.actionsDisabled);
    notOk(set.refs['show-grading-period-2'].props.actionsDisabled);
    notOk(set.refs['show-grading-period-3'].props.actionsDisabled);
  });

  test('"onCancel" re-enables set toggling', function () {
    const spy = sinon.spy();
    const set = this.renderComponent({ onToggleBody: spy });
    set.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
    set.refs.editPeriodForm.props.onCancel();
    Simulate.click(set.refs.toggleSetBody);
    ok(spy.calledOnce);
  });

  QUnit.module('GradingPeriodSet "Edit Grading Period - onSave"', {
    renderComponent (opts = {}) {
      const attrs = _.extend({}, props, opts);
      let component;
      attrs.ref = (ref) => { component = ref };
      ReactDOM.render(React.createElement(GradingPeriodSet, attrs), wrapper);
      component.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
      return component;
    },

    callOnSave (component) {
      return component.refs.editPeriodForm.props.onSave(examplePeriods[0]);
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('updates the given grading period in the set', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      equal(set.refs.gradingPeriodList.children.length, 3);
    });
  });

  test('ensures sorted grading periods', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      const periods = set.refs.gradingPeriodList.props.children;
      const periodIds = _.map(periods, period => period.props.period.id);
      propEqual(periodIds, ['3', '1', '2']);
    });
  });

  test('disables the "edit period form"', function () {
    const success = new Promise(() => {});
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    assertDisabled(set.refs.addPeriodButton);
  });

  test('calls the onPeriodsChange prop upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const spy = sinon.spy();
    const set = this.renderComponent({onPeriodsChange: spy});
    this.callOnSave(set);
    return success.then(() => {
      const sortedPeriods = _.sortBy(examplePeriods, 'startDate');
      ok(spy.calledOnce);
      ok(spy.calledWith(props.set.id, sortedPeriods));
    });
  });

  test('removes the "edit period form" upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      notOk(!!set.refs.editPeriodForm);
    });
  });

  test('focuses on the grading period "edit button" upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      ok(set.refs['show-grading-period-1'].refs.editButton.focused);
    });
  });

  test('re-enables all grading period actions upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      assertEnabled(set.refs.addPeriodButton);
      notOk(set.refs['show-grading-period-1'].props.actionsDisabled);
      notOk(set.refs['show-grading-period-2'].props.actionsDisabled);
      notOk(set.refs['show-grading-period-3'].props.actionsDisabled);
    });
  });

  test('re-enables set toggling upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const spy = sinon.spy();
    const set = this.renderComponent({ onToggleBody: spy });
    this.callOnSave(set);
    return success.then(() => {
      Simulate.click(set.refs.toggleSetBody);
      ok(spy.calledOnce);
    });
  });

  QUnit.module('GradingPeriodSet "Edit Grading Period - validations"', {
    stubUpdate () {
      const failure = Promise.reject(new Error('FAIL'));
      sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(failure);
    },

    renderComponent () {
      let component;
      const updatedProps = { ...props, ref (ref) { component = ref } };
      ReactDOM.render(React.createElement(GradingPeriodSet, updatedProps), wrapper);
      component.refs['show-grading-period-1'].refs.editButton.handleClick(new MouseEvent('click'));
      return component;
    },

    callOnSave (component, period) {
      return component.refs.editPeriodForm.props.onSave(period);
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('does not save a grading period without a title', function () {
    const period = {
      id: '1',
      title: '',
      startDate: new Date('2015-03-02T20:11:00+00:00'),
      endDate: new Date('2015-03-03T00:00:00+00:00'),
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with a title of spaces only', function () {
    const period = {
      id: '1',
      title: '    ',
      startDate: new Date('2015-03-02T20:11:00+00:00'),
      endDate: new Date('2015-03-03T00:00:00+00:00'),
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with a negative weight', function() {
    let period = {
      id: "1",
      title: "Some valid title",
      weight: -50,
      startDate: new Date("2015-03-02T20:11:00+00:00"),
      endDate: new Date("2015-03-03T00:00:00+00:00"),
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  test('does not save a grading period without a valid startDate', function () {
    const period = {
      title: 'Period without Start Date',
      startDate: undefined,
      endDate: new Date('2015-03-03T00:00:00+00:00'),
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period without a valid endDate', function () {
    const period = {
      title: 'Period without End Date',
      startDate: new Date('2015-03-02T20:11:00+00:00'),
      endDate: null,
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period without a valid closeDate', function () {
    const period = {
      title: 'Period without End Date',
      startDate: new Date('2015-03-02T20:11:00+00:00'),
      endDate: new Date('2015-03-03T00:00:00+00:00'),
      closeDate: null
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with overlapping startDate', function () {
    const period = {
      title: 'Period with Overlapping Start Date',
      startDate: new Date('2015-04-30T20:11:00+00:00'),
      endDate: new Date('2015-05-30T00:00:00+00:00'),
      closeDate: new Date('2015-05-30T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with overlapping endDate', function () {
    const period = {
      title: 'Period with Overlapping End Date',
      startDate: new Date('2014-12-30T20:11:00+00:00'),
      endDate: new Date('2015-01-30T00:00:00+00:00'),
      closeDate: new Date('2015-01-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with endDate before startDate', function () {
    const period = {
      title: 'Overlapping Period',
      startDate: new Date('2015-03-03T00:00:00+00:00'),
      endDate: new Date('2015-03-02T20:11:00+00:00'),
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with closeDate before endDate', function () {
    const period = {
      title: 'Overlapping Period',
      startDate: new Date('2015-03-01T00:00:00+00:00'),
      endDate: new Date('2015-03-02T20:11:00+00:00'),
      closeDate: new Date('2015-03-02T20:10:59+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.editPeriodForm, 'form is still visible');
  });

  QUnit.module('GradingPeriodSet "Add Grading Period"', {
    renderComponent (permissions = allPermissions, readOnly = false) {
      let component;
      const updatedProps = _.extend({}, props, {
        permissions: _.extend({}, allPermissions, permissions),
        readOnly,
        ref (ref) { component = ref }
      });
      ReactDOM.render(React.createElement(GradingPeriodSet, updatedProps), wrapper);
      return component;
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('shows the "add grading period" button when "create" is permitted', function () {
    const set = this.renderComponent();
    ok(set.refs.addPeriodButton);
  });

  test('does not show the "add grading period" button when "create" is not permitted', function () {
    const set = this.renderComponent({ create: false });
    notOk(!!set.refs.addPeriodButton);
  });

  test('does not show the "add grading period" button when "read only"', function () {
    const set = this.renderComponent({ create: true }, true);
    notOk(!!set.refs.addPeriodButton);
  });

  test('renders the "GradingPeriodForm" when "add grading period" is clicked', function () {
    const set = this.renderComponent();
    notOk(!!set.refs.newPeriodForm);
    set.refs.addPeriodButton.handleClick(new MouseEvent('click'));
    ok(set.refs.newPeriodForm);
  });

  test('disables all grading period actions while open', function () {
    const set = this.renderComponent();
    set.refs.addPeriodButton.handleClick(new MouseEvent('click'));
    ok(set.refs['show-grading-period-1'].props.actionsDisabled);
    ok(set.refs['show-grading-period-2'].props.actionsDisabled);
    ok(set.refs['show-grading-period-3'].props.actionsDisabled);
  });

  test('"onCancel" removes the "new period form"', function () {
    const set = this.renderComponent();
    set.refs.addPeriodButton.handleClick(new MouseEvent('click'));
    set.refs.newPeriodForm.props.onCancel();
    notOk(!!set.refs.newPeriodForm);
  });

  test('"onCancel" focuses on the "add grading period" button', function () {
    const set = this.renderComponent();
    set.refs.addPeriodButton.handleClick(new MouseEvent('click'));
    set.refs.newPeriodForm.props.onCancel();
    ok(set.refs.addPeriodButton.focused);
  });

  test('"onCancel" re-enables all grading period actions', function () {
    const set = this.renderComponent();
    set.refs.addPeriodButton.handleClick(new MouseEvent('click'));
    set.refs.newPeriodForm.props.onCancel();
    assertEnabled(set.refs.addPeriodButton);
    notOk(set.refs['show-grading-period-1'].props.actionsDisabled);
    notOk(set.refs['show-grading-period-2'].props.actionsDisabled);
    notOk(set.refs['show-grading-period-3'].props.actionsDisabled);
  });

  QUnit.module('GradingPeriodSet "Remove Grading Period"', {
    renderComponent () {
      let component;
      const updatedProps = { ...props, ref (ref) { component = ref } };
      ReactDOM.render(React.createElement(GradingPeriodSet, updatedProps), wrapper);
      return component;
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('removeGradingPeriod removes the grading period with the given id', function () {
    const set = this.renderComponent();
    set.removeGradingPeriod('1');
    const periodIDs = _.pluck(set.state.gradingPeriods, 'id');
    propEqual(periodIDs, ['3', '2']);
  });

  QUnit.module('GradingPeriodSet "New Grading Period - onSave"', {
    renderComponent (opts = {}) {
      let component;
      const updatedProps = { ...props, ...opts, ref (ref) { component = ref } };
      ReactDOM.render(React.createElement(GradingPeriodSet, updatedProps), wrapper);
      component.refs.addPeriodButton.handleClick(new MouseEvent('click'));
      return component;
    },

    callOnSave (component) {
      return component.refs.newPeriodForm.props.onSave(examplePeriod);
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('adds the given grading period to the set', function () {
    const allPeriods = examplePeriods.concat([examplePeriod]);
    const success = Promise.resolve(allPeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      equal(set.refs.gradingPeriodList.props.children.length, 4);
    });
  });

  test('ensures sorted grading periods', function () {
    const allPeriods = examplePeriods.concat([examplePeriod]);
    const success = Promise.resolve(allPeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      const periods = set.refs.gradingPeriodList.props.children;
      const periodIds = _.map(periods, period => period.props.period.id);
      propEqual(periodIds, ['3', '1', '4', '2']);
    });
  });

  test('disables the "new period form"', function () {
    const success = new Promise(() => {});
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    ok(set.refs.newPeriodForm.props.disabled);
  });

  test('calls the onPeriodsChange prop upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const spy = sinon.spy();
    const set = this.renderComponent({onPeriodsChange: spy});
    this.callOnSave(set);
    return success.then(() => {
      const sortedPeriods = _.sortBy(examplePeriods, 'startDate');
      ok(spy.calledOnce);
      ok(spy.calledWith(props.set.id, sortedPeriods));
    });
  });

  test('removes the "new period form" upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      notOk(!!set.refs.newPeriodForm);
    });
  });

  test('re-enables all grading period actions upon completion', function () {
    const success = Promise.resolve(examplePeriods);
    sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(success);
    const set = this.renderComponent();
    this.callOnSave(set);
    return success.then(() => {
      assertEnabled(set.refs.addPeriodButton);
      notOk(set.refs['show-grading-period-1'].props.actionsDisabled);
      notOk(set.refs['show-grading-period-2'].props.actionsDisabled);
      notOk(set.refs['show-grading-period-3'].props.actionsDisabled);
    });
  });

  QUnit.module('GradingPeriodSet "New Grading Period - validations"', {
    stubUpdate () {
      const failure = Promise.reject(new Error('FAIL'));
      sandbox.stub(gradingPeriodsApi, 'batchUpdate').returns(failure);
    },

    renderComponent () {
      let component;
      const updatedProps = { ...props, ref (ref) { component = ref } };
      ReactDOM.render(React.createElement(GradingPeriodSet, updatedProps), wrapper);
      component.refs.addPeriodButton.handleClick(new MouseEvent('click'));
      return component;
    },

    callOnSave (component, period) {
      return component.refs.newPeriodForm.props.onSave(period);
    },

    teardown () {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('does not save a grading period without a title', function () {
    const period = {
      title: '',
      startDate: new Date('2015-03-02T20:11:00+00:00'),
      endDate: new Date('2015-03-03T00:00:00+00:00'),
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.newPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with a negative weight', function() {
    let period = {
      id: "1",
      title: "Some valid title",
      weight: -50,
      startDate: new Date("2015-03-02T20:11:00+00:00"),
      endDate: new Date("2015-03-03T00:00:00+00:00"),
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.newPeriodForm, "form is still visible");
  });

  test('does not save a grading period without a valid startDate', function () {
    const period = {
      title: 'Period without Start Date',
      startDate: undefined,
      endDate: new Date('2015-03-03T00:00:00+00:00'),
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.newPeriodForm, 'form is still visible');
  });

  test('does not save a grading period without a valid endDate', function () {
    const period = {
      title: 'Period without End Date',
      startDate: new Date('2015-03-02T20:11:00+00:00'),
      endDate: null,
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.newPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with overlapping startDate', function () {
    const period = {
      title: 'Period with Overlapping Start Date',
      startDate: new Date('2015-04-30T20:11:00+00:00'),
      endDate: new Date('2015-05-30T00:00:00+00:00'),
      closeDate: new Date('2015-05-30T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.newPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with overlapping endDate', function () {
    const period = {
      title: 'Period with Overlapping End Date',
      startDate: new Date('2014-12-30T20:11:00+00:00'),
      endDate: new Date('2015-01-30T00:00:00+00:00'),
      closeDate: new Date('2015-01-30T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.newPeriodForm, 'form is still visible');
  });

  test('does not save a grading period with endDate before startDate', function () {
    const period = {
      title: 'Overlapping Period',
      startDate: new Date('2015-03-03T00:00:00+00:00'),
      endDate: new Date('2015-03-02T20:11:00+00:00'),
      closeDate: new Date('2015-03-03T00:00:00+00:00')
    };
    this.stubUpdate();
    const set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, 'does not call update');
    ok(set.refs.newPeriodForm, 'form is still visible');
  });
});
