require(['old_version_of_react_used_by_canvas_quizzes_client_apps'], (React) => {
  window.React = React;

// Creates a DOM element that ReactSuite tests will use tmount the subject
// in. Although jasmine_react does that automatically on the start of each
// ReactSuite, we will prepare it before-hand and expose it to jasmine.fixture
// if you need to access directly.
  require(['jasmine_react', 'old_version_of_react-router_used_by_canvas_quizzes_client_apps'], (ReactSuite, ReactRouter) => {
    const Route = ReactRouter.Route;

    console.log('')

    const exports = function (suite, type, initialProps) {
      let routes = [
        Route({ name: 'app', path: '/', handler: type })
      ];

      const Sink = React.createClass({
        render () { return React.DOM.div({}); }
      });

      suite.beforeEach(() => {
        const routeMap = ReactRouter.Routes({
          location: 'hash',
          children: routes
        });

        const subject = window.subject = React.renderComponent(routeMap, document.createElement('div'));
      });


      suite.afterEach(() => {
        window.subject = null;
        routeMap = null;
      });

      this.stubRoutes = function (specs) {
        routes = routes.concat(specs.map((spec) => {
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
