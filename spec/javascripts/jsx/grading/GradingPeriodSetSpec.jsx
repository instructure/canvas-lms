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

  const assertDisabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    ok($el, "expect element to exist");
    equal($el.getAttribute('aria-disabled'), 'true');
  };

  const assertEnabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    ok($el, "expect element to exist");
    notEqual($el.getAttribute('aria-disabled'), 'true');
  };

  const urls = {
    batchUpdateURL: "api/v1/accounts/1/grading_period_sets",
    deleteGradingPeriodURL:  "api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D",
    gradingPeriodSetsURL: "api/v1/accounts/1/grading_period_sets"
  };

  const allPermissions = {
    read:   true,
    create: true,
    update: true,
    delete: true
  };

  const examplePeriods = [
    {
      id: "1",
      title: "We did it! We did it! We did it! #dora #boots",
      startDate: new Date("2015-01-01T20:11:00+00:00"),
      endDate: new Date("2015-03-01T00:00:00+00:00"),
      closeDate: new Date("2015-03-01T00:00:00+00:00")
    },{
      id: "3",
      title: "Como estas?",
      startDate: new Date("2014-11-01T20:11:00+00:00"),
      endDate: new Date("2014-11-11T00:00:00+00:00"),
      closeDate: new Date("2014-11-11T00:00:00+00:00")
    },{
      id: "2",
      title: "Swiper no swiping!",
      startDate: new Date("2015-04-01T20:11:00+00:00"),
      endDate: new Date("2015-05-01T00:00:00+00:00"),
      closeDate: new Date("2015-05-01T00:00:00+00:00")
    }
  ];

  const examplePeriod = {
    id: "4",
    title: "Example Period",
    startDate: new Date("2015-03-02T20:11:00+00:00"),
    endDate: new Date("2015-03-03T00:00:00+00:00"),
    closeDate: new Date("2015-03-03T00:00:00+00:00")
  };

  const props = {
    set: {
      id: "1",
      title: "Example Set",
    },
    terms: [],
    onEdit: function(){},
    onDelete: function(){},
    onPeriodsChange: function(){},
    onToggleBody: function(){},
    gradingPeriods: examplePeriods,
    expanded: true,
    actionsDisabled: false,
    readOnly: false,
    urls: urls,
    permissions: allPermissions,
    terms: []
  };

  module("GradingPeriodSet", {
    renderComponent(opts = {}) {
      let attrs = _.extend({}, props, opts);
      attrs.onDelete = this.stub();
      attrs.onEdit = this.stub();
      const element = React.createElement(GradingPeriodSet, attrs);
      return ReactDOM.render(element, wrapper);
    },

    stubDeleteSuccess() {
      const successPromise = new Promise(resolve => resolve());
      this.stub(axios, "delete").returns(successPromise);
      return successPromise;
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("renders without set body when the 'expanded' property is false", function() {
    let set = this.renderComponent({ expanded: false });
    notOk(!!set.refs.setBody);
  });

  test("renders with set body when the 'expanded' property is true", function() {
    let set = this.renderComponent({ expanded: true });
    ok(set.refs.setBody);
  });

  test("expands the set body when the toggle is clicked", function() {
    let spy = sinon.spy();
    let set = this.renderComponent({ onToggleBody: spy });
    Simulate.click(set.refs.toggleSetBody);
    ok(spy.calledOnce);
  });

  test("disables action buttons when 'actionsDisabled' is true", function() {
    let set = this.renderComponent({actionsDisabled: true});
    assertDisabled(set.refs.editButton);
    assertDisabled(set.refs.deleteButton);
  });

  test("disables the 'add grading period' button when 'actionsDisabled' is true", function() {
    let set = this.renderComponent({actionsDisabled: true});
    assertDisabled(set.refs.addPeriodButton);
  });

  test("disables grading period action buttons when 'actionsDisabled' is true", function() {
    let set = this.renderComponent({actionsDisabled: true});
    ok(set.refs["show-grading-period-2"].props.actionsDisabled);
    ok(set.refs["show-grading-period-3"].props.actionsDisabled);
  });

  test("sorts grading periods by start date, ascending", function() {
    let set = this.renderComponent();
    const periods = set.refs.gradingPeriodList.props.children;
    const startDates = _.map(periods, period => period.props.period.startDate);
    ok((startDates[0] < startDates[1]) && (startDates[1] < startDates[2]));
  });

  test("calls the onEdit prop when the 'edit grading period set' button is clicked", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs.editButton));
    ok(set.props.onEdit.calledOnce);
    equal(set.props.onEdit.args[0][0], set.props.set);
  });

  test("does not delete the set if the user cancels the delete confirmation", function() {
    this.stub(axios, "delete");
    this.stub(window, "confirm", () => false);
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs.deleteButton));
    ok(set.props.onDelete.notCalled);
  });

  asyncTest("deletes the set if the user confirms deletion", function() {
    let deletePromise = this.stubDeleteSuccess();
    this.stub(window, "confirm", () => true);
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs.deleteButton));
    deletePromise.then(function() {
      ok(set.props.onDelete.calledOnce);
      start();
    });
  });

  module("GradingPeriodSet 'Edit Grading Period'", {
    renderComponent(opts = {}) {
      let attrs = _.extend({}, props, opts);
      const element = React.createElement(GradingPeriodSet, attrs);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("renders the 'GradingPeriodForm' when 'edit grading period' is clicked", function() {
    let set = this.renderComponent();
    notOk(!!set.refs.editPeriodForm);
    Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
    ok(set.refs.editPeriodForm);
  });

  test("disables all grading period actions while open", function() {
    let set = this.renderComponent();
    notOk(!!set.refs.editPeriodForm);
    Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
    assertDisabled(set.refs.addPeriodButton);
    ok(set.refs["show-grading-period-2"].props.actionsDisabled);
    ok(set.refs["show-grading-period-3"].props.actionsDisabled);
  });

  test("disables set toggling while open", function() {
    let spy = sinon.spy();
    let set = this.renderComponent({ onToggleBody: spy });
    Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
    Simulate.click(set.refs.toggleSetBody);
    notOk(spy.called);
  });

  test("'onCancel' removes the 'edit grading period' form", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
    set.refs.editPeriodForm.props.onCancel();
    notOk(!!set.refs.editPeriodForm);
  });

  test("'onCancel' focuses on the 'edit grading period' button", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
    set.refs.editPeriodForm.props.onCancel();
    equal(document.activeElement, ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
  });

  test("'onCancel' re-enables all grading period actions", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
    set.refs.editPeriodForm.props.onCancel();
    assertEnabled(set.refs.addPeriodButton);
    notOk(set.refs["show-grading-period-1"].props.actionsDisabled);
    notOk(set.refs["show-grading-period-2"].props.actionsDisabled);
    notOk(set.refs["show-grading-period-3"].props.actionsDisabled);
  });

  test("'onCancel' re-enables set toggling", function() {
    let spy = sinon.spy();
    let set = this.renderComponent({ onToggleBody: spy });
    Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
    set.refs.editPeriodForm.props.onCancel();
    Simulate.click(set.refs.toggleSetBody);
    ok(spy.calledOnce);
  });

  module("GradingPeriodSet 'Edit Grading Period - onSave'", {
    renderComponent(opts = {}) {
      let attrs = _.extend({}, props, opts);
      const element = React.createElement(GradingPeriodSet, attrs);
      let component = ReactDOM.render(element, wrapper);
      Simulate.click(ReactDOM.findDOMNode(component.refs["show-grading-period-1"].refs.editButton));
      return component;
    },

    callOnSave(component) {
      return component.refs.editPeriodForm.props.onSave(examplePeriods[0]);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("updates the given grading period in the set", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      equal(set.refs.gradingPeriodList.children.length, 3);
      start();
    });
  });

  asyncTest("ensures sorted grading periods", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      let periods = set.refs.gradingPeriodList.props.children;
      let periodIds = _.map(periods, period => period.props.period.id);
      propEqual(periodIds, ["3", "1", "2"]);
      start();
    });
  });

  asyncTest("disables the 'edit period form'", function() {
    let success = new Promise(() => {});
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      assertDisabled(set.refs.addPeriodButton);
      start();
    });
  });

  asyncTest("calls the onPeriodsChange prop upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let spy = sinon.spy();
    let set = this.renderComponent({onPeriodsChange: spy});
    this.callOnSave(set);
    requestAnimationFrame(() => {
      let sortedPeriods = _.sortBy(examplePeriods, "startDate");
      ok(spy.calledOnce);
      ok(spy.calledWith(props.set.id, sortedPeriods));
      start();
    });
  });

  asyncTest("removes the 'edit period form' upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      notOk(!!set.refs.editPeriodForm);
      start();
    });
  });

  asyncTest("focuses on the grading period 'edit button' upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      equal(document.activeElement, ReactDOM.findDOMNode(set.refs["show-grading-period-1"].refs.editButton));
      start();
    });
  });

  asyncTest("re-enables all grading period actions upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      assertEnabled(set.refs.addPeriodButton);
      notOk(set.refs["show-grading-period-1"].props.actionsDisabled);
      notOk(set.refs["show-grading-period-2"].props.actionsDisabled);
      notOk(set.refs["show-grading-period-3"].props.actionsDisabled);
      start();
    });
  });

  asyncTest("re-enables set toggling upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let spy = sinon.spy();
    let set = this.renderComponent({ onToggleBody: spy });
    this.callOnSave(set);
    requestAnimationFrame(() => {
      Simulate.click(set.refs.toggleSetBody);
      ok(spy.calledOnce);
      start();
    });
  });

  module("GradingPeriodSet 'Edit Grading Period - validations'", {
    stubUpdate() {
      let failure = new Promise(_, reject => { throw("FAIL") });
      this.stub(gradingPeriodsApi, "batchUpdate").returns(failure);
    },

    renderComponent() {
      const element = React.createElement(GradingPeriodSet, props);
      let component = ReactDOM.render(element, wrapper);
      Simulate.click(ReactDOM.findDOMNode(component.refs["show-grading-period-1"].refs.editButton));
      return component;
    },

    callOnSave(component, period) {
      return component.refs.editPeriodForm.props.onSave(period);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('does not save a grading period without a title', function() {
    let period = {
      id: "1",
      title: "",
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

  test('does not save a grading period with a title of spaces only', function() {
    let period = {
      id: "1",
      title: "    ",
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

  test('does not save a grading period without a valid startDate', function() {
    let period = {
      title: "Period without Start Date",
      startDate: undefined,
      endDate: new Date("2015-03-03T00:00:00+00:00"),
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  test('does not save a grading period without a valid endDate', function() {
    let period = {
      title: "Period without End Date",
      startDate: new Date("2015-03-02T20:11:00+00:00"),
      endDate: null,
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  test('does not save a grading period without a valid closeDate', function() {
    let period = {
      title: "Period without End Date",
      startDate: new Date("2015-03-02T20:11:00+00:00"),
      endDate: new Date("2015-03-03T00:00:00+00:00"),
      closeDate: null
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  test('does not save a grading period with overlapping startDate', function() {
    let period = {
      title: "Period with Overlapping Start Date",
      startDate: new Date("2015-04-30T20:11:00+00:00"),
      endDate: new Date("2015-05-30T00:00:00+00:00"),
      closeDate: new Date("2015-05-30T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  test('does not save a grading period with overlapping endDate', function() {
    let period = {
      title: "Period with Overlapping End Date",
      startDate: new Date("2014-12-30T20:11:00+00:00"),
      endDate: new Date("2015-01-30T00:00:00+00:00"),
      closeDate: new Date("2015-01-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  test('does not save a grading period with endDate before startDate', function() {
    let period = {
      title: "Overlapping Period",
      startDate: new Date("2015-03-03T00:00:00+00:00"),
      endDate: new Date("2015-03-02T20:11:00+00:00"),
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  test('does not save a grading period with closeDate before endDate', function() {
    let period = {
      title: "Overlapping Period",
      startDate: new Date("2015-03-01T00:00:00+00:00"),
      endDate: new Date("2015-03-02T20:11:00+00:00"),
      closeDate: new Date("2015-03-02T20:10:59+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.editPeriodForm, "form is still visible");
  });

  module("GradingPeriodSet 'Add Grading Period'", {
    renderComponent(permissions = allPermissions, readOnly = false) {
      let updatedProps = _.extend({}, props, {
        permissions: _.extend({}, allPermissions, permissions),
        readOnly: readOnly
      });
      const element = React.createElement(GradingPeriodSet, updatedProps);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("shows the 'add grading period' button when 'create' is permitted", function() {
    let set = this.renderComponent();
    ok(set.refs.addPeriodButton);
  });

  test("does not show the 'add grading period' button when 'create' is not permitted", function() {
    let set = this.renderComponent({ create: false });
    notOk(!!set.refs.addPeriodButton);
  });

  test("does not show the 'add grading period' button when 'read only'", function() {
    let set = this.renderComponent({ create: true }, true);
    notOk(!!set.refs.addPeriodButton);
  });

  test("renders the 'GradingPeriodForm' when 'add grading period' is clicked", function() {
    let set = this.renderComponent();
    notOk(!!set.refs.newPeriodForm);
    Simulate.click(ReactDOM.findDOMNode(set.refs.addPeriodButton));
    ok(set.refs.newPeriodForm);
  });

  test("disables all grading period actions while open", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs.addPeriodButton));
    ok(set.refs["show-grading-period-1"].props.actionsDisabled);
    ok(set.refs["show-grading-period-2"].props.actionsDisabled);
    ok(set.refs["show-grading-period-3"].props.actionsDisabled);
  });

  test("'onCancel' removes the 'new period form'", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs.addPeriodButton));
    set.refs.newPeriodForm.props.onCancel();
    notOk(!!set.refs.newPeriodForm);
  });

  test("'onCancel' focuses on the 'add grading period' button", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs.addPeriodButton));
    set.refs.newPeriodForm.props.onCancel();
    equal(document.activeElement, ReactDOM.findDOMNode(set.refs.addPeriodButton));
  });

  test("'onCancel' re-enables all grading period actions", function() {
    let set = this.renderComponent();
    Simulate.click(ReactDOM.findDOMNode(set.refs.addPeriodButton));
    set.refs.newPeriodForm.props.onCancel();
    assertEnabled(set.refs.addPeriodButton);
    notOk(set.refs["show-grading-period-1"].props.actionsDisabled);
    notOk(set.refs["show-grading-period-2"].props.actionsDisabled);
    notOk(set.refs["show-grading-period-3"].props.actionsDisabled);
  });

  module("GradingPeriodSet 'Remove Grading Period'", {
    renderComponent() {
      const element = React.createElement(GradingPeriodSet, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('removeGradingPeriod removes the grading period with the given id', function() {
    let set = this.renderComponent();
    set.removeGradingPeriod("1");
    const periodIDs = _.pluck(set.state.gradingPeriods, "id");
    propEqual(periodIDs, ["3", "2"]);
  });

  module("GradingPeriodSet 'New Grading Period - onSave'", {
    renderComponent(opts = {}) {
      const element = React.createElement(GradingPeriodSet, _.defaults(opts, props));
      let component = ReactDOM.render(element, wrapper);
      Simulate.click(ReactDOM.findDOMNode(component.refs.addPeriodButton));
      return component;
    },

    callOnSave(component) {
      return component.refs.newPeriodForm.props.onSave(examplePeriod);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("adds the given grading period to the set", function() {
    let allPeriods = examplePeriods.concat([examplePeriod]);
    let success = new Promise(resolve => resolve(allPeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      equal(set.refs.gradingPeriodList.props.children.length, 4);
      start();
    });
  });

  asyncTest("ensures sorted grading periods", function() {
    let allPeriods = examplePeriods.concat([examplePeriod]);
    let success = new Promise(resolve => resolve(allPeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      let periods = set.refs.gradingPeriodList.props.children;
      let periodIds = _.map(periods, period => period.props.period.id);
      propEqual(periodIds, ["3", "1", "4", "2"]);
      start();
    });
  });

  asyncTest("disables the 'new period form'", function() {
    let success = new Promise(() => {});
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      ok(set.refs.newPeriodForm.props.disabled);
      start();
    });
  });

  asyncTest("calls the onPeriodsChange prop upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let spy = sinon.spy();
    let set = this.renderComponent({onPeriodsChange: spy});
    this.callOnSave(set);
    requestAnimationFrame(() => {
      let sortedPeriods = _.sortBy(examplePeriods, "startDate");
      ok(spy.calledOnce);
      ok(spy.calledWith(props.set.id, sortedPeriods));
      start();
    });
  });

  asyncTest("removes the 'new period form' upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      notOk(!!set.refs.newPeriodForm);
      start();
    });
  });

  asyncTest("re-enables all grading period actions upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      assertEnabled(set.refs.addPeriodButton);
      notOk(set.refs["show-grading-period-1"].props.actionsDisabled);
      notOk(set.refs["show-grading-period-2"].props.actionsDisabled);
      notOk(set.refs["show-grading-period-3"].props.actionsDisabled);
      start();
    });
  });

  module("GradingPeriodSet 'New Grading Period - validations'", {
    stubUpdate() {
      let failure = new Promise(_, reject => { throw("FAIL") });
      this.stub(gradingPeriodsApi, "batchUpdate").returns(failure);
    },

    renderComponent() {
      const element = React.createElement(GradingPeriodSet, props);
      let component = ReactDOM.render(element, wrapper);
      Simulate.click(ReactDOM.findDOMNode(component.refs.addPeriodButton));
      return component;
    },

    callOnSave(component, period) {
      return component.refs.newPeriodForm.props.onSave(period);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('does not save a grading period without a title', function() {
    let period = {
      title: "",
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

  test('does not save a grading period without a valid startDate', function() {
    let period = {
      title: "Period without Start Date",
      startDate: undefined,
      endDate: new Date("2015-03-03T00:00:00+00:00"),
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.newPeriodForm, "form is still visible");
  });

  test('does not save a grading period without a valid endDate', function() {
    let period = {
      title: "Period without End Date",
      startDate: new Date("2015-03-02T20:11:00+00:00"),
      endDate: null,
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.newPeriodForm, "form is still visible");
  });

  test('does not save a grading period with overlapping startDate', function() {
    let period = {
      title: "Period with Overlapping Start Date",
      startDate: new Date("2015-04-30T20:11:00+00:00"),
      endDate: new Date("2015-05-30T00:00:00+00:00"),
      closeDate: new Date("2015-05-30T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.newPeriodForm, "form is still visible");
  });

  test('does not save a grading period with overlapping endDate', function() {
    let period = {
      title: "Period with Overlapping End Date",
      startDate: new Date("2014-12-30T20:11:00+00:00"),
      endDate: new Date("2015-01-30T00:00:00+00:00"),
      closeDate: new Date("2015-01-30T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.newPeriodForm, "form is still visible");
  });

  test('does not save a grading period with endDate before startDate', function() {
    let period = {
      title: "Overlapping Period",
      startDate: new Date("2015-03-03T00:00:00+00:00"),
      endDate: new Date("2015-03-02T20:11:00+00:00"),
      closeDate: new Date("2015-03-03T00:00:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.newPeriodForm, "form is still visible");
  });
});
