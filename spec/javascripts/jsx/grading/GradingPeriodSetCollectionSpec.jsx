define([
  'react',
  'underscore',
  'axios',
  'jsx/grading/GradingPeriodSetCollection'
], (React, _, axios, SetCollection) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  module("GradingPeriodSetCollection", {
    renderComponent() {
      const props = {
        urls: {
          gradingPeriodSetsURL: "api/v1/accounts/1/grading_period_sets",
          enrollmentTermsURL: "api/v1/accounts/1/terms",
          gradingPeriodsUpdateURL: "api/v1/accounts/1/grading_period_sets"
        },
        readOnly: false
      };

      const element = React.createElement(SetCollection, props);
      return React.render(element, wrapper);
    },

    setsResponse() {
      return {
        data: {
          grading_period_sets: [
            {
              id: "1",
              title: "Macarena",
              grading_periods: [],
              permissions: { read: true, create: true, update: true, delete: true }
            },
            {
              id: "2",
              title: "Mambo Numero Cinco",
              grading_periods: [
                { id: 9, title: "Febrero", start_date: "2014-06-08T15:44:25Z", end_date: "2014-07-08T15:44:25Z" },
                { id: 11, title: "Marzo", start_date: "2014-08-08T15:44:25Z", end_date: "2014-09-08T15:44:25Z" }
              ],
              permissions: { read: true, create: true, update: true, delete: true }
            }
          ]
        }
      };
    },

    deserializedSets() {
      return [
        {
          id: "1",
          title: "Macarena",
          gradingPeriods: [],
          permissions: { read: true, create: true, update: true, delete: true }
        },
        {
          id: "2",
          title: "Mambo Numero Cinco",
          gradingPeriods: [
            {
              id: "9",
              title: "Febrero",
              startDate: new Date("2014-06-08T15:44:25Z"),
              endDate: new Date("2014-07-08T15:44:25Z")
            },
            {
              id: "11",
              title: "Marzo",
              startDate: new Date("2014-08-08T15:44:25Z"),
              endDate: new Date("2014-09-08T15:44:25Z")
            }
          ],
          permissions: { read: true, create: true, update: true, delete: true }
        }
      ];
    },

    termsResponse() {
      return {
        data: {
          enrollment_terms: [
            {
              id: 1,
              name: "Fall 2013 - Art",
              start_at: "2013-06-03T02:57:42Z",
              end_at: "2013-12-03T02:57:53Z",
              created_at: "2015-10-27T16:51:41Z",
              grading_period_group_id: 2
            },
            {
              id: 3,
              name: null,
              start_at: "2014-01-03T02:58:36Z",
              end_at: "2014-03-03T02:58:42Z",
              created_at: "2013-06-02T17:29:19Z",
              grading_period_group_id: 2
            },
            {
              id: 4,
              name: null,
              start_at: null,
              end_at: null,
              created_at: "2014-05-02T17:29:19Z",
              grading_period_group_id: 1
            }
          ]
        }
      };
    },

    deserializedTerms() {
      return [
        {
          id: 1,
          name: "Fall 2013 - Art",
          startAt: new Date("2013-06-03T02:57:42Z"),
          endAt: new Date("2013-12-03T02:57:53Z"),
          createdAt: new Date("2015-10-27T16:51:41Z"),
          gradingPeriodGroupId: 2,
          displayName: "Fall 2013 - Art"
        },
        {
          id: 3,
          name: null,
          startAt: new Date("2014-01-03T02:58:36Z"),
          endAt: new Date("2014-03-03T02:58:42Z"),
          createdAt: new Date("2013-06-02T17:29:19Z"),
          gradingPeriodGroupId: 2,
          displayName: "Term starting Jan 3, 2014"
        },
        {
          id: 4,
          name: null,
          startAt: null,
          endAt: null,
          createdAt: new Date("2014-05-02T17:29:19Z"),
          gradingPeriodGroupId: 1,
          displayName: "Term created May 2, 2014"
        }
      ];
    },

    stubAJAXSuccess(opts={ type: "sets" }) {
      const response = opts.type === "sets" ? this.setsResponse() : this.termsResponse();
      const successPromise = new Promise(resolve => resolve(response));
      this.stub(axios, "get").returns(successPromise);
      return successPromise;
    },

    stubAJAXFailure() {
      const failurePromise = new Promise((_, reject) => {
        reject();
      });

      this.stub(axios, "get").returns(failurePromise);
      return failurePromise;
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });

  asyncTest("deserializes sets and grading periods if the AJAX call is successful", function() {
    const success = this.stubAJAXSuccess();
    const deserializedSet = this.deserializedSets()[1];
    let collection = this.renderComponent();

    success.then(function() {
      const set = collection.state.sets[1];
      propEqual(set, deserializedSet);
      start();
    });
  });

  asyncTest("has an empty set collection if the AJAX call fails", function() {
    const failure = this.stubAJAXFailure();
    let collection = this.renderComponent();

    failure.catch(function() {
      propEqual(collection.state.sets, []);
      start();
    });
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
    const success = this.stubAJAXSuccess();
    let collection = this.renderComponent();

    success.then(function() {
      collection.changeSearchText("ma");
      let filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(filteredIDs, ["1", "2"]);

      collection.changeSearchText("rz");
      filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(filteredIDs, ["2"]);

      collection.changeSearchText("Mac");
      filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(filteredIDs, ["1"]);

      collection.changeSearchText("dora the explorer");
      filteredIDs = _.pluck(collection.getVisibleSets(), "id");
      propEqual(collection.getVisibleSets(), []);
      start();
    });
  });

  asyncTest("deserializes enrollment terms if the AJAX call is successful", function() {
    const success = this.stubAJAXSuccess({ type: "terms" });
    const deserializedTerm = this.deserializedTerms()[0];
    let collection = this.renderComponent();

    success.then(function() {
      const term = collection.state.enrollmentTerms[0];
      propEqual(term, deserializedTerm);
      start();
    });
  });

  asyncTest("uses the name, start date (if no name), or creation date (if no start) for the display name", function() {
    const success = this.stubAJAXSuccess({ type: "terms" });
    const expectedNames = _.pluck(this.deserializedTerms(), "displayName");
    let collection = this.renderComponent();

    success.then(function() {
      const names = _.pluck(collection.state.enrollmentTerms, "displayName");
      propEqual(names, expectedNames);
      start();
    });
  });

  test("filterSetsByActiveTerm returns all the sets if 'All Terms' is selected", function() {
    const ALL_TERMS_ID = 0;
    const sets = this.deserializedSets();
    const terms = this.deserializedTerms();
    const selectedTermID = ALL_TERMS_ID;
    let collection = this.renderComponent();
    const filteredSets = collection.filterSetsByActiveTerm(sets, terms, selectedTermID);
    propEqual(filteredSets, sets);
  });

  test("filterSetsByActiveTerm filters to only show the set that the selected term belongs to", function() {
    const sets = this.deserializedSets();
    const terms = this.deserializedTerms();
    let selectedTermID = 3;
    let collection = this.renderComponent();
    let filteredSets = collection.filterSetsByActiveTerm(sets, terms, selectedTermID);
    let expectedSets = _.where(sets, { id: "2" });
    propEqual(filteredSets, expectedSets);

    selectedTermID = 4;
    filteredSets = collection.filterSetsByActiveTerm(sets, terms, selectedTermID);
    expectedSets = _.where(sets, { id: "1" });
    propEqual(filteredSets, expectedSets);
  });
});
