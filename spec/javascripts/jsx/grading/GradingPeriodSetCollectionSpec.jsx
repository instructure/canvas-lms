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
        URLs: {
          gradingPeriodSetsURL: "api/v1/accounts/1/grading_period_sets"
        }
      };

      const element = React.createElement(SetCollection, props);
      return React.render(element, wrapper);
    },

    successResponse() {
      return {
        data: {
          grading_period_sets: [
            {
              id: "1",
              title: "Macarena",
              grading_periods: []
            },
            {
              id: "2",
              title: "Mambo Numero Cinco",
              grading_periods: [
                { id: 9, title: "Febrero", start_date: "2014-06-08T15:44:25Z", end_date: "2014-07-08T15:44:25Z" },
                { id: 11, title: "Marzo", start_date: "2014-08-08T15:44:25Z", end_date: "2014-09-08T15:44:25Z" }
              ]
            }
          ]
        }
      };
    },

    stubAJAXSuccess() {
      const response = this.successResponse();
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
    const deserializedSet = {
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
      ]
    };

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
    let set = { title: "Set!", gradingPeriods: [{ title: "Grading Period 1" }, { title: "Grading Period 2" }] };
    let collection = this.renderComponent();
    let titles = collection.setAndGradingPeriodTitles(set);
    propEqual(titles, ["Set!", "Grading Period 1", "Grading Period 2"]);
  });

  test("setAndGradingPeriodTitles filters out empty, null, and undefined titles", function() {
    let set = {
      title: null,
      gradingPeriods: [
        { title: "Grading Period 1" },
        {},
        { title: "Grading Period 2" },
        { title: "" }
      ]
    };

    let collection = this.renderComponent();
    let titles = collection.setAndGradingPeriodTitles(set);
    propEqual(titles, ["Grading Period 1", "Grading Period 2"]);
  });

  test("searchTextMatchesTitles returns true if the search text exactly matches one of the titles", function() {
    let titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    collection.changeSearchText("hello world");
    equal(collection.searchTextMatchesTitles(titles), true)
  });

  test("searchTextMatchesTitles returns true if the search text is a substring of one of the titles", function() {
    let titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    collection.changeSearchText("orl");
    equal(collection.searchTextMatchesTitles(titles), true)
  });

  test("searchTextMatchesTitles returns false if the search text is a not a substring of any of the titles", function() {
    let titles = ["hello world", "goodbye friend"];
    let collection = this.renderComponent();
    collection.changeSearchText("olr");
    equal(collection.searchTextMatchesTitles(titles), false)
  });

  asyncTest("filterSetsBySearchText returns sets that match the search text", function() {
    const success = this.stubAJAXSuccess();
    let collection = this.renderComponent();

    success.then(function() {
      collection.changeSearchText("ma");
      let filteredIDs = _.pluck(collection.filterSetsBySearchText(), "id");
      propEqual(filteredIDs, ["1", "2"]);

      collection.changeSearchText("rz");
      filteredIDs = _.pluck(collection.filterSetsBySearchText(), "id");
      propEqual(filteredIDs, ["2"]);

      collection.changeSearchText("Mac");
      filteredIDs = _.pluck(collection.filterSetsBySearchText(), "id");
      propEqual(filteredIDs, ["1"]);

      collection.changeSearchText("dora the explorer");
      filteredIDs = _.pluck(collection.filterSetsBySearchText(), "id");
      propEqual(collection.filterSetsBySearchText(), []);
      start();
    });
  });
});
