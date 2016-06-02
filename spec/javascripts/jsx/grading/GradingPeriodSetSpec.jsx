define([
  'react',
  'underscore',
  'jsx/grading/GradingPeriodSet',
  'compiled/api/gradingPeriodsApi'
], (React, _, GradingPeriodSet, gradingPeriodsApi) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  const urls = {
    batchUpdateUrl: "api/v1/accounts/1/grading_period_sets"
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
      endDate: new Date("2015-03-01T00:00:00+00:00")
    },
    {
      id: "3",
      title: "Como estas?",
      startDate: new Date("2014-11-01T20:11:00+00:00"),
      endDate: new Date("2014-11-11T00:00:00+00:00")
    },
    {
      id: "2",
      title: "Swiper no swiping!",
      startDate: new Date("2015-04-01T20:11:00+00:00"),
      endDate: new Date("2015-05-01T00:00:00+00:00")
    }
  ];

  const examplePeriod = {
    id: "4",
    title: "Example Period",
    startDate: new Date("2015-03-02T20:11:00+00:00"),
    endDate: new Date("2015-03-03T00:00:00+00:00")
  };

  const props = {
    set: {
      id: "1",
      title: "Dora the Explorer Grading Period Set",
    },
    gradingPeriods: examplePeriods,
    readOnly: false,
    urls: urls,
    permissions: allPermissions
  };

  module("GradingPeriodSet", {
    renderComponent() {
      const element = React.createElement(GradingPeriodSet, props);
      return React.render(element, wrapper);
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  test("initially renders as 'collapsed', showing the set body", function() {
    let set = this.renderComponent();
    notOk(set.refs.setBody);
  });

  test("expands the set body when the toggle is clicked", function() {
    let set = this.renderComponent();
    Simulate.click(set.refs.toggleSetBody);
    ok(set.refs.setBody);
  });

  test("re-collapses the set body when the toggle is clicked twice", function() {
    let set = this.renderComponent();
    Simulate.click(set.refs.toggleSetBody);
    Simulate.click(set.refs.toggleSetBody);
    notOk(set.refs.setBody);
  });

  test("sorts grading periods by start date, ascending", function() {
    let set = this.renderComponent();
    Simulate.click(set.refs.toggleSetBody);
    const periods = set.refs.gradingPeriodList.props.children;
    const startDates = _.map(periods, period => period.props.period.startDate);
    ok((startDates[0] < startDates[1]) && (startDates[1] < startDates[2]));
  });

  module("GradingPeriodSet 'Add Grading Period'", {
    renderComponent(permissions = allPermissions, readOnly = false) {
      let set = {
        set: { id: "1", title: "Example Set" },
        gradingPeriods: [],
        urls: urls,
        permissions: _.defaults(permissions, allPermissions),
        readOnly: readOnly
      };
      const element = React.createElement(GradingPeriodSet, set);
      let component = React.render(element, wrapper);
      Simulate.click(component.refs.toggleSetBody);
      return component;
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  test("shows the 'add grading period' button when 'create' is permitted", function() {
    let set = this.renderComponent();
    ok(set.refs.addPeriodButton);
  });

  test("does not show the 'add grading period' button when 'create' is not permitted", function() {
    let set = this.renderComponent({ create: false });
    notOk(set.refs.addPeriodButton);
  });

  test("does not show the 'add grading period' button when 'read only'", function() {
    let set = this.renderComponent({ create: true }, true);
    notOk(set.refs.addPeriodButton);
  });

  test("renders the 'GradingPeriodForm' when 'add grading period' is clicked", function() {
    let set = this.renderComponent();
    notOk(set.refs.newPeriodForm);
    Simulate.click(set.refs.addPeriodButton);
    ok(set.refs.newPeriodForm);
  });

  test("'onCancel' removes the 'new period form'", function() {
    let set = this.renderComponent();
    Simulate.click(set.refs.addPeriodButton);
    set.refs.newPeriodForm.props.onCancel();
    notOk(set.refs.newPeriodForm);
  });

  test("'onCancel' focuses on the 'add grading period' button", function() {
    let set = this.renderComponent();
    Simulate.click(set.refs.addPeriodButton);
    set.refs.newPeriodForm.props.onCancel();
    equal(set.refs.addPeriodButton.getDOMNode(), document.activeElement);
  });

  module("GradingPeriodSet 'New Grading Period - onSave'", {
    renderComponent() {
      let set = {
        set: { id: "1", title: "Example Set" },
        gradingPeriods: [],
        urls: urls,
        readOnly: false,
        permissions: allPermissions
      };
      const element = React.createElement(GradingPeriodSet, set);
      let component = React.render(element, wrapper);
      Simulate.click(component.refs.toggleSetBody);
      Simulate.click(component.refs.addPeriodButton);
      return component;
    },

    callOnSave(component) {
      return component.refs.newPeriodForm.props.onSave(examplePeriod);
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
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

  asyncTest("removes the 'new period form' upon completion", function() {
    let success = new Promise(resolve => resolve(examplePeriods));
    this.stub(gradingPeriodsApi, "batchUpdate").returns(success);
    let set = this.renderComponent();
    this.callOnSave(set);
    requestAnimationFrame(() => {
      notOk(set.refs.newPeriodForm);
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
      let component = React.render(element, wrapper);
      Simulate.click(component.refs.toggleSetBody);
      Simulate.click(component.refs.addPeriodButton);
      return component;
    },

    callOnSave(component, period) {
      return component.refs.newPeriodForm.props.onSave(period);
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  test('does not save a grading period without a title', function() {
    let period = {
      title: "",
      startDate: new Date("2015-03-02T20:11:00+00:00"),
      endDate: new Date("2015-03-03T00:00:00+00:00")
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
      endDate: new Date("2015-03-03T00:00:00+00:00")
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
      endDate: null
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
      endDate: new Date("2015-05-30T00:00:00+00:00")
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
      endDate: new Date("2015-01-30T00:00:00+00:00")
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
      endDate: new Date("2015-03-02T20:11:00+00:00")
    };
    let update = this.stubUpdate();
    let set = this.renderComponent();
    this.callOnSave(set, period);
    notOk(gradingPeriodsApi.batchUpdate.called, "does not call update");
    ok(set.refs.newPeriodForm, "form is still visible");
  });
});
