/** @jsx React.DOM */
define(function(require) {
  var ReactRouter = require('canvas_packages/react-router');
  var AppRoute = require('jsx!../routes/app');
  var EventStreamRoute = require('jsx!../routes/event_stream');
  var QuestionRoute = require('jsx!../routes/question');
  var AnswerMatrixRoute = require('jsx!../routes/answer_matrix');

  var Route = ReactRouter.Route;
  var Routes = ReactRouter.Routes;
  var DefaultRoute = ReactRouter.DefaultRoute;

  return (
    <Routes location="hash">
      <Route name="app" path="/" handler={AppRoute}>
        <DefaultRoute handler={EventStreamRoute} />

        <Route
          addHandlerKey
          name="question"
          path="/questions/:id"
          handler={QuestionRoute} />

        <Route
          addHandlerKey
          name="answer_matrix"
          path="/answer_matrix"
          handler={AnswerMatrixRoute} />
      </Route>
    </Routes>
  );
});