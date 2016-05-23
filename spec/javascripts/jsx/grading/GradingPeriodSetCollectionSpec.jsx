define([
  'react',
  'axios',
  'jsx/grading/GradingPeriodSetCollection'
], (React, axios, SetCollection) => {
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
              id: 2,
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
    let collection = this.renderComponent();
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
    }

    success.then(function() {
      const set = collection.state.gradingPeriodSets[1];
      propEqual(set, deserializedSet);
      start();
    });
  });

  asyncTest("has an empty set collection if the AJAX call fails", function() {
    const failure = this.stubAJAXFailure();
    let collection = this.renderComponent();

    failure.catch(function() {
      propEqual(collection.state.gradingPeriodSets, []);
      start();
    });
  });
});
