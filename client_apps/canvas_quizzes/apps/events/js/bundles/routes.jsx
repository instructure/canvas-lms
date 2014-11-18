/** @jsx React.DOM */
define(function(require) {
  var ReactRouter = require('canvas_packages/react-router');
  var AppRoute = require('jsx!../routes/app');
  var EventsRoute = require('jsx!../routes/events');
  var QuestionRoute = require('jsx!../routes/question');

  var Route = ReactRouter.Route;
  var Routes = ReactRouter.Routes;
  var DefaultRoute = ReactRouter.DefaultRoute;

  return (
    <Routes location="hash">
      <Route name="app" path="/" handler={AppRoute}>
        <DefaultRoute handler={EventsRoute} />
        <Route name="question" addHandlerKey path="/questions/:id" handler={QuestionRoute} />
      </Route>
    </Routes>
  );
});