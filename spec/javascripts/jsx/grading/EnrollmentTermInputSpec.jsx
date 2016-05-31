define([
  'react',
  'underscore',
  'jsx/grading/EnrollmentTermInput'
], (React, _, Input) => {
  const wrapper = document.getElementById('fixtures');
  const Simulate = React.addons.TestUtils.Simulate;

  module('EnrollmentTermInput', {
    renderComponent(opts={}) {
      const defaults = {
        enrollmentTerms: [],
        selected: [],
        setSelectedEnrollmentTermIDs: function(){},
      };
      const props = _.defaults(opts, defaults);
      const element = React.createElement(Input, props);
      return React.render(element, wrapper);
    },

    teardown() {
      React.unmountComponentAtNode(wrapper);
    }
  });
});
