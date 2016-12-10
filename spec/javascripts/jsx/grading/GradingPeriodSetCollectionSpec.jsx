define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'underscore',
  'jquery',
  'jsx/grading/GradingPeriodSetCollection',
  'compiled/api/gradingPeriodSetsApi',
  'compiled/api/enrollmentTermsApi'
], (React, ReactDOM, {Simulate}, _, $, SetCollection, setsApi, termsApi) => {
  const wrapper = document.getElementById('fixtures');

  const assertDisabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    equal($el.getAttribute('aria-disabled'), 'true');
  };

  const assertEnabled = function(component) {
    let $el = ReactDOM.findDOMNode(component);
    notEqual($el.getAttribute('aria-disabled'), 'true');
  };

  const assertCollapsed = function(component, setId) {
    let message = "set with id: " + setId + " is 'collapsed'";
    equal(component.refs["show-grading-period-set-" + setId].props.expanded, false, message);
  };

  const assertExpanded = function(component, setId) {
    let message = "set with id: " + setId + " is 'expanded'";
    equal(component.refs["show-grading-period-set-" + setId].props.expanded, true, message);
  };

  const exampleSet = {
    id: "1",
    title: "Fall 2015",
    gradingPeriods: [
      {
        id: "1",
        title: "Q1",
        startDate: new Date("2015-09-01T12:00:00Z"),
        endDate: new Date("2015-10-31T12:00:00Z")
      },{
        id: "2",
        title: "Q2",
        startDate: new Date("2015-11-01T12:00:00Z"),
        endDate: new Date("2015-12-31T12:00:00Z")
      }
    ],
    permissions: { read: true, create: true, update: true, delete: true },
    createdAt: new Date("2015-08-27T16:51:41Z")
  };

  const exampleSets = [
    exampleSet,
    {
      id: "2",
      title: "Spring 2016",
      gradingPeriods: [],
      permissions: { read: true, create: true, update: true, delete: true },
      createdAt: new Date("2015-06-27T16:51:41Z")
    }
  ];

  const exampleTerms = [
    {
      id: "1",
      name: "Fall 2013 - Art",
      startAt: new Date("2013-06-03T02:57:42Z"),
      endAt: new Date("2013-12-03T02:57:53Z"),
      createdAt: new Date("2015-10-27T16:51:41Z"),
      gradingPeriodGroupId: "2",
      displayName: "Fall 2013 - Art"
    },{
      id: "3",
      name: null,
      startAt: new Date("2014-01-03T02:58:36Z"),
      endAt: new Date("2014-03-03T02:58:42Z"),
      createdAt: new Date("2013-06-02T17:29:19Z"),
      gradingPeriodGroupId: "22",
      displayName: "Term starting Jan 3, 2014"
    },{
      id: "4",
      name: null,
      startAt: null,
      endAt: null,
      createdAt: new Date("2014-05-02T17:29:19Z"),
      gradingPeriodGroupId: "1",
      displayName: "Term created May 2, 2014"
    }
  ];

  const props = {
    urls: {
      gradingPeriodSetsURL: "api/v1/accounts/1/grading_period_sets",
      enrollmentTermsURL: "api/v1/accounts/1/terms",
      deleteGradingPeriodURL:  "api/v1/accounts/1/grading_periods/%7B%7B%20id%20%7D%7D",
      gradingPeriodsUpdateURL: "api/v1/accounts/1/grading_periods/batch_update"
    },
    readOnly: false,
  };

  module("GradingPeriodSetCollection - API Data Load", {
    renderComponent() {
      const element = React.createElement(SetCollection, props);
      return ReactDOM.render(element, wrapper);
    },

    stubTermsSuccess() {
      const termsSuccess = new Promise(resolve => resolve(exampleTerms));
      this.stub(termsApi, 'list').returns(termsSuccess);
      return termsSuccess;
    },

    stubSetsSuccess() {
      const setsSuccess = new Promise(resolve => resolve(exampleSets));
      this.stub(setsApi, 'list').returns(setsSuccess);
      return setsSuccess;
    },

    stubSetsFailure() {
      const setsFailure = new Promise((_, reject) => reject("FAIL"));
      this.stub(setsApi, 'list').returns(setsFailure);
      return setsFailure;
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("loads enrollment terms", function() {
    let terms = this.stubTermsSuccess();
    let sets = this.stubSetsSuccess();
    let collection = this.renderComponent();

    Promise.all([terms, sets]).then(function() {
      propEqual(_.pluck(collection.state.enrollmentTerms, "id"), _.pluck(exampleTerms, "id"));
      start();
    });
  });

  asyncTest("loads grading period sets", function() {
    let terms = this.stubTermsSuccess();
    let sets = this.stubSetsSuccess();
    let collection = this.renderComponent();

    Promise.all([terms, sets]).then(function() {
      propEqual(_.pluck(collection.state.sets, "id"), _.pluck(exampleSets, "id"));
      start();
    });
  });

  asyncTest("has an empty set collection if sets failed to load", function() {
    let terms = this.stubTermsSuccess();
    let sets = this.stubSetsFailure();
    let collection = this.renderComponent();

    Promise.all([terms, sets]).catch(function() {
      propEqual(collection.state.sets, []);
      start();
    });
  });

  module("GradingPeriodSetCollection", {
    setup() {
      const setsSuccess = new Promise(resolve => resolve(exampleSets));
      const termsSuccess = new Promise(resolve => resolve(exampleTerms));
      this.sets = this.stub(setsApi, 'list').returns(setsSuccess);
      this.terms = this.stub(termsApi, 'list').returns(termsSuccess);
    },

    renderComponent() {
      const element = React.createElement(SetCollection, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("uses the name, start date (if no name), or creation date (if no start) for the display name", function() {
    let collection = this.renderComponent();
    const expectedNames = ["Fall 2013 - Art", "Term starting Jan 3, 2014", "Term created May 2, 2014"];

    Promise.all([this.terms, this.sets]).then(function() {
      const actualNames = _.pluck(collection.state.enrollmentTerms, "displayName");
      propEqual(expectedNames, actualNames);
      start();
    });
  });

  asyncTest("initially renders each set as 'collapsed'", function() {
    let collection = this.renderComponent();
    Promise.all([this.terms, this.sets]).then(function() {
      assertCollapsed(collection, "1");
      assertCollapsed(collection, "2");
      start();
    });
  });

  asyncTest("each set's 'onToggleBody' property will toggle its 'expanded' state", function() {
    let collection = this.renderComponent();
    Promise.all([this.terms, this.sets]).then(function() {
      collection.refs["show-grading-period-set-1"].props.onToggleBody();
      assertExpanded(collection, "1");
      assertCollapsed(collection, "2");
      collection.refs["show-grading-period-set-2"].props.onToggleBody();
      assertExpanded(collection, "1");
      assertExpanded(collection, "2");
      collection.refs["show-grading-period-set-1"].props.onToggleBody();
      assertCollapsed(collection, "1");
      assertExpanded(collection, "2");
      start();
    });
  });

  test("doesn't show the new set form on initial load", function() {
    let collection = this.renderComponent();
    notOk(collection.refs.newSetForm);
  });

  test("has the add new set button enabled on initial load", function() {
    let collection = this.renderComponent();
    assertEnabled(collection.refs.addSetFormButton);
  });

  test("disables the add new set button after it is clicked", function() {
    let collection = this.renderComponent();
    let addSetFormButton = ReactDOM.findDOMNode(collection.refs.addSetFormButton);
    Simulate.click(addSetFormButton);
    assertDisabled(collection.refs.addSetFormButton);
  });

  test("shows the new set form when the add new set button is clicked", function() {
    let collection = this.renderComponent();
    let addSetFormButton = ReactDOM.findDOMNode(collection.refs.addSetFormButton);
    Simulate.click(addSetFormButton);
    ok(collection.refs.newSetForm);
  });

  test("closes the new set form when closeNewSetForm is called", function() {
    let collection = this.renderComponent();
    collection.closeNewSetForm();
    notOk(collection.refs.newSetForm);
  });

  module("GradingPeriodSetCollection - Search", {
    setup() {
      const setsSuccess = new Promise(resolve => resolve(exampleSets));
      const termsSuccess = new Promise(resolve => resolve(exampleTerms));
      this.sets = this.stub(setsApi, 'list').returns(setsSuccess);
      this.terms = this.stub(termsApi, 'list').returns(termsSuccess);
    },

    renderComponent() {
      const element = React.createElement(SetCollection, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("setAndGradingPeriodTitles returns an array of set and grading period title names", function() {
    const set = { title: "Set!", gradingPeriods: [{ title: "Grading Period 1" }, { title: "Grading Period 2" }] };
    let collection = this.renderComponent();
    const titles = collection.setAndGradingPeriodTitles(set);
    propEqual(titles, ["Set!", "Grading Period 1", "Grading Period 2"]);
  });

  test("setAndGradingPeriodTitles filters out empty, null, and undefined titles", function() {
    const set = {
      title: null,
      gradingPeriods: [
        { title: "Grading Period 1" },
        {},
        { title: "Grading Period 2" },
        { title: "" }
      ]
    };

    let collection = this.renderComponent();
    const titles = collection.setAndGradingPeriodTitles(set);
    propEqual(titles, ["Grading Period 1", "Grading Period 2"]);
  });

  test("changeSearchText calls setState if the new search text differs from the old search text", function() {
    const titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    const setStateSpy = this.spy(collection, "setState");
    collection.changeSearchText("hello world");
    collection.changeSearchText("goodbye world");
    ok(setStateSpy.calledTwice)
  });

  test("changeSearchText does not call setState if the new search text equals the old search text", function() {
    const titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    const setStateSpy = this.spy(collection, "setState");
    collection.changeSearchText("hello world");
    collection.changeSearchText("hello world");
    ok(setStateSpy.calledOnce)
  });

  test("searchTextMatchesTitles returns true if the search text exactly matches one of the titles", function() {
    const titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    collection.changeSearchText("hello world");
    equal(collection.searchTextMatchesTitles(titles), true)
  });

  test("searchTextMatchesTitles returns true if the search text exactly matches one of the titles", function() {
    const titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    collection.changeSearchText("hello world");
    equal(collection.searchTextMatchesTitles(titles), true)
  });

  test("searchTextMatchesTitles returns true if the search text is a substring of one of the titles", function() {
    const titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    collection.changeSearchText("orl");
    equal(collection.searchTextMatchesTitles(titles), true)
  });

  test("searchTextMatchesTitles returns false if the search text is a not a substring of any of the titles", function() {
    const titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    collection.changeSearchText("olr");
    equal(collection.searchTextMatchesTitles(titles), false)
  });

  asyncTest("getVisibleSets returns sets that match the search text", function() {
    let collection = this.renderComponent();

    Promise.all([this.terms, this.sets]).then(function() {
      collection.changeSearchText("201");
      let filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(filteredIDs, ["1", "2"]);

      collection.changeSearchText("pring");
      filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(filteredIDs, ["2"]);

      collection.changeSearchText("Fal");
      filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(filteredIDs, ["1"]);

      collection.changeSearchText("does not match");
      filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(collection.getVisibleSets(), []);
      start();
    });
  });

  asyncTest("announces number of search results for screen readers", function() {
    let collection = this.renderComponent();

    Promise.all([this.terms, this.sets]).then(function() {
      sinon.spy($, "screenReaderFlashMessageExclusive");
      collection.changeSearchText("201");
      collection.getVisibleSets();
      ok($.screenReaderFlashMessageExclusive.calledWith(I18n.t({
          one: "1 set of grading periods found.",
          other: "%{count} sets of grading periods found.",
          zero: "No matching sets of grading periods found."
        }, {count: 2}
      )));

      collection.changeSearchText("");
      collection.getVisibleSets();
      ok($.screenReaderFlashMessageExclusive.calledWith(I18n.t("Showing all sets of grading periods.")));

      $.screenReaderFlashMessageExclusive.restore();

      start();
    });
  });

  asyncTest("preserves each set's 'expanded' state", function() {
    let collection = this.renderComponent();

    Promise.all([this.terms, this.sets]).then(function() {
      collection.refs["show-grading-period-set-1"].props.onToggleBody();

      collection.changeSearchText("201");
      assertExpanded(collection, "1");
      assertCollapsed(collection, "2");

      // clear all sets from search results
      collection.changeSearchText("does not match");

      collection.changeSearchText("201");
      assertExpanded(collection, "1");
      assertCollapsed(collection, "2");
      start();
    });
  });

  asyncTest("deserializes enrollment terms if the AJAX call is successful", function() {
    const deserializedTerm = exampleTerms[0];
    let collection = this.renderComponent();

    Promise.all([this.terms, this.sets]).then(function() {
      const term = collection.state.enrollmentTerms[0];
      propEqual(term, deserializedTerm);
      start();
    });
  });

  asyncTest("uses the name, start date (if no name), or creation date (if no start) for the display name", function() {
    const expectedNames = _.pluck(exampleTerms, "displayName");
    let collection = this.renderComponent();

    Promise.all([this.terms, this.sets]).then(function() {
      const names = _.pluck(collection.state.enrollmentTerms, "displayName");
      propEqual(names, expectedNames);
      start();
    });
  });

  test("filterSetsBySelectedTerm returns all the sets if 'All Terms' is selected", function() {
    const ALL_TERMS_ID = "0";
    const selectedTermID = ALL_TERMS_ID;
    let collection = this.renderComponent();
    const filteredSets = collection.filterSetsBySelectedTerm(exampleSets, exampleTerms, selectedTermID);
    propEqual(filteredSets, exampleSets);
  });

  test("filterSetsBySelectedTerm filters to only show the set that the selected term belongs to", function() {
    let selectedTermID = "1";
    let collection = this.renderComponent();
    let filteredSets = collection.filterSetsBySelectedTerm(exampleSets, exampleTerms, selectedTermID);
    let expectedSets = _.where(exampleSets, { id: "2" });
    propEqual(filteredSets, expectedSets);

    selectedTermID = "4";
    filteredSets = collection.filterSetsBySelectedTerm(exampleSets, exampleTerms, selectedTermID);
    expectedSets = _.where(exampleSets, { id: "1" });
    propEqual(filteredSets, expectedSets);
  });

  module("GradingPeriodSetCollection - Add Set", {
    setup() {
      const setsSuccess = new Promise(resolve => resolve([]));
      const termsSuccess = new Promise(resolve => resolve(exampleTerms));
      this.sets = this.stub(setsApi, 'list').returns(setsSuccess);
      this.terms = this.stub(termsApi, 'list').returns(termsSuccess);
    },

    renderComponent() {
      const element = React.createElement(SetCollection, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("addGradingPeriodSet adds the set to the collection", function() {
    let collection = this.renderComponent();

    Promise.all([this.sets, this.terms]).then(function() {
      collection.addGradingPeriodSet(exampleSet);
      ok(collection.refs["show-grading-period-set-1"], "the grading period set is visible");
      const setIDs = _.pluck(collection.state.sets, "id");
      propEqual(setIDs, ["1"]);
      start();
    });
  });

  asyncTest("addGradingPeriodSet renders the new set expanded", function() {
    let collection = this.renderComponent();

    Promise.all([this.sets, this.terms]).then(function() {
      collection.addGradingPeriodSet(exampleSet);
      assertExpanded(collection, "1");
      start();
    });
  });

  module("GradingPeriodSetCollection - Delete Set", {
    setup() {
      const setsSuccess = new Promise(resolve => resolve(exampleSets));
      const termsSuccess = new Promise(resolve => resolve(exampleTerms));
      this.sets = this.stub(setsApi, 'list').returns(setsSuccess);
      this.terms = this.stub(termsApi, 'list').returns(termsSuccess);
    },

    renderComponent() {
      const element = React.createElement(SetCollection, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("removeGradingPeriodSet removes the set from the collection", function() {
    let collection = this.renderComponent();

    Promise.all([this.sets, this.terms]).then(function() {
      collection.removeGradingPeriodSet("1");
      const setIDs = _.pluck(collection.state.sets, "id");
      propEqual(setIDs, ["2"]);
      start();
    });
  });

  asyncTest("removeGradingPeriodSet focuses on the set above the one deleted, if one exists", function() {
    let collection = this.renderComponent();

    Promise.all([this.sets, this.terms]).then(function() {
      collection.removeGradingPeriodSet("2");
      equal(document.activeElement.textContent, "Fall 2015");
      start();
    });
  });

  asyncTest("removeGradingPeriodSet focuses on the '+ Set of Grading Periods' button" +
  " after deletion if there are no sets above the one that was deleted", function() {
    let collection = this.renderComponent();

    Promise.all([this.sets, this.terms]).then(function() {
      collection.removeGradingPeriodSet("1");
      const activeElementText = document.activeElement.textContent;
      ok(activeElementText.includes("Set of Grading Periods"));
      start();
    });
  });

  module("GradingPeriodSetCollection - Update Set Periods", {
    setup() {
      const setsSuccess = new Promise(resolve => resolve(exampleSets));
      const termsSuccess = new Promise(resolve => resolve(exampleTerms));
      this.sets = this.stub(setsApi, 'list').returns(setsSuccess);
      this.terms = this.stub(termsApi, 'list').returns(termsSuccess);
    },

    renderComponent() {
      const element = React.createElement(SetCollection, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("updateSetPeriods updates the grading periods on the given set", function() {
    let collection = this.renderComponent();

    Promise.all([this.sets, this.terms]).then(function() {
      collection.updateSetPeriods("1", []);
      const set = _.findWhere(collection.state.sets, {id: "1"});
      propEqual(set.gradingPeriods, []);
      start();
    });
  });

  module("GradingPeriodSetCollection 'Edit Grading Period Set'", {
    setup() {
      const setsSuccess = new Promise(resolve => resolve(exampleSets));
      const termsSuccess = new Promise(resolve => resolve(exampleTerms));
      this.sets = this.stub(setsApi, 'list').returns(setsSuccess);
      this.terms = this.stub(termsApi, 'list').returns(termsSuccess);
    },

    renderComponent() {
      const element = React.createElement(SetCollection, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("renders the 'edit grading period set' when 'edit grading period set' is clicked", function() {
    let set = this.renderComponent();
    Promise.all([this.sets, this.terms]).then(function() {
      notOk(!!set.refs["edit-grading-period-set-1"], "the edit grading period set form is not visible");
      Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-set-1"].refs.editButton));
      ok(set.refs["edit-grading-period-set-1"], "the edit form is visible");
      start();
    });
  });

  asyncTest("disables other 'grading period set' actions while open", function() {
    let set = this.renderComponent();
    Promise.all([this.sets, this.terms]).then(function() {
      Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-set-1"].refs.editButton));
      assertDisabled(set.refs.addSetFormButton);
      ok(set.refs["show-grading-period-set-2"].props.actionsDisabled);
      start();
    });
  });

  asyncTest("'onCancel' removes the 'edit grading period set' form", function() {
    let set = this.renderComponent();
    Promise.all([this.sets, this.terms]).then(function() {
      Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-set-1"].refs.editButton));
      set.refs["edit-grading-period-set-1"].props.onCancel();
      notOk(!!set.refs["edit-grading-period-set-1"]);
      start();
    });
  });

  asyncTest("'onCancel' focuses on the 'edit grading period set' button", function() {
    let set = this.renderComponent();
    Promise.all([this.sets, this.terms]).then(function() {
      Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-set-1"].refs.editButton));
      set.refs["edit-grading-period-set-1"].props.onCancel();
      equal(document.activeElement, ReactDOM.findDOMNode(set.refs["show-grading-period-set-1"].refs.editButton));
      start();
    });
  });

  asyncTest("'onCancel' re-enables all grading period set actions", function() {
    let set = this.renderComponent();
    Promise.all([this.sets, this.terms]).then(function() {
      Simulate.click(ReactDOM.findDOMNode(set.refs["show-grading-period-set-1"].refs.editButton));
      set.refs["edit-grading-period-set-1"].props.onCancel();
      assertEnabled(set.refs.addSetFormButton);
      notOk(set.refs["show-grading-period-set-2"].props.actionsDisabled);
      start();
    });
  });

  module("GradingPeriodSetCollection 'Edit Grading Period Set - onSave'", {
    setup() {
      this.stub(setsApi, 'list').returns(new Promise(() => {}));
      this.stub(termsApi, 'list').returns(new Promise(() => {}));
    },

    renderComponent() {
      const element = React.createElement(SetCollection, props);
      let component = ReactDOM.render(element, wrapper);
      component.onTermsLoaded(exampleTerms);
      component.onSetsLoaded(exampleSets);
      Simulate.click(ReactDOM.findDOMNode(component.refs["show-grading-period-set-1"].refs.editButton));
      return component;
    },

    callOnSave(collection) {
      Simulate.click(ReactDOM.findDOMNode(collection.refs["edit-grading-period-set-1"].refs.saveButton));
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("removes the 'edit grading period set' form", function() {
    let updatedSet = _.extend({}, exampleSet, {title: "Updated Title"});
    let success = new Promise(resolve => resolve(updatedSet));
    this.stub(setsApi, "update").returns(success);
    let collection = this.renderComponent();
    this.callOnSave(collection);
    requestAnimationFrame(function() {
      ok(collection.refs["show-grading-period-set-1"]);
      notOk(!!collection.refs["edit-grading-period-set-1"]);
      start();
    });
  });

  asyncTest("updates the given grading period set", function() {
    let updatedSet = _.extend({}, exampleSet, {title: "Updated Title"});
    let success = new Promise(resolve => resolve(updatedSet));
    this.stub(setsApi, "update").returns(success);
    let collection = this.renderComponent();
    this.callOnSave(collection);
    requestAnimationFrame(() => {
      let setComponent = collection.refs["show-grading-period-set-1"];
      equal(setComponent.props.set.title, "Updated Title");
      start();
    });
  });

  asyncTest("re-enables all grading period set actions", function() {
    let updatedSet = _.extend({}, exampleSet, {title: "Updated Title"});
    let success = new Promise(resolve => resolve(updatedSet));
    this.stub(setsApi, "update").returns(success);
    let collection = this.renderComponent();
    this.callOnSave(collection);
    requestAnimationFrame(() => {
      assertEnabled(collection.refs.addSetFormButton);
      notOk(collection.refs["show-grading-period-set-1"].props.actionsDisabled);
      notOk(collection.refs["show-grading-period-set-2"].props.actionsDisabled);
      start();
    });
  });

  asyncTest("preserves the 'edit grading period set' form upon failure", function() {
    let updatedSet = _.extend({}, exampleSet, {title: "Updated Title"});
    let failure = new Promise(_, reject => reject("FAIL"));
    this.stub(setsApi, "update").returns(failure);
    let collection = this.renderComponent();
    this.callOnSave(collection);
    requestAnimationFrame(() => {
      ok(collection.refs["edit-grading-period-set-1"]);
      notOk(!!collection.refs["show-grading-period-set-1"]);
      start();
    });
  });

  asyncTest("termsBelongingToActiveSets only includes terms that belong to active (non-deleted) sets", function() {
    let collection = this.renderComponent();

    requestAnimationFrame(() => {
      const expectedTerms = _.map(exampleTerms, term => term);
      expectedTerms.splice(1, 1);
      expectedTerms.splice(2, 1);
      propEqual(collection.termsBelongingToActiveSets(), expectedTerms);
      start();
    });
  });

  asyncTest("termsNotBelongingToActiveSets only includes terms that do not belong to active (non-deleted) sets", function() {
    let collection = this.renderComponent();

    requestAnimationFrame(() => {
      const expectedTerms = _.map(exampleTerms, term => term);
      expectedTerms.splice(0, 1);
      expectedTerms.splice(1, 1);
      propEqual(collection.termsNotBelongingToActiveSets(), expectedTerms);
      start();
    });
  });
});
