require([ 'react' ], function(React) {
  window.React = React;

// Creates a DOM element that ReactSuite tests will use tmount the subject
// in. Although jasmine_react does that automatically on the start of each
// ReactSuite, we will prepare it before-hand and expose it to jasmine.fixture
// if you need to access directly.
require([ 'jasmine_react', 'canvas_packages/react-router', ], function(ReactSuite, ReactRouter) {
  var Route = ReactRouter.Route;

  console.log("")

  var exports = function(suite, type, initialProps) {
    var routes = [
        Route({ name: "app", path: "/", handler: type })
    ];

    var Sink = React.createClass({
      render: function() { return React.DOM.div({}); }
    });

    suite.beforeEach(function() {
      var routeMap = ReactRouter.Routes({
        location: "hash",
        children: routes
      });

      var subject = window.subject = React.renderComponent(routeMap, document.createElement("div"));
    });


    suite.afterEach(function() {
      window.subject = null;
      routeMap = null;
    });

    this.stubRoutes = function(specs) {
      routes = routes.concat(specs.map(function(spec) {
        if (!spec.handler) {
          spec.handler = Sink;
        }

        return Route(spec);
      }));
    };

    return this;
  };

  window.reactRouterSuite = exports;
});

});