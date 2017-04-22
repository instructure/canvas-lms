/** @jsx React.DOM */
define(function(require) {
  var ReactRouter = require('old_version_of_react-router_used_by_canvas_quizzes_client_apps');
  var AppRoute = require('jsx!../routes/app');
  var EventStreamRoute = require('jsx!../routes/event_stream');
  var QuestionRoute = require('jsx!../routes/question');
  var AnswerMatrixRoute = require('jsx!../routes/answer_matrix');

  var Route = ReactRouter.Route;
  var Routes = ReactRouter.Routes;
  var DefaultRoute = ReactRouter.DefaultRoute;
  var NotFoundRoute = ReactRouter.NotFoundRoute;

  var currentPath = window.location.pathname
    , re = new RegExp('\(.*\/log)')
    , matches = re.exec(currentPath)
    , baseUrl = "";

  if(matches) {
    baseUrl = matches[0];
  }

  return (
    <Routes location="history">
      <Route name="app" path={baseUrl +'/?'} handler={AppRoute}>
        <DefaultRoute handler={EventStreamRoute} />
        <NotFoundRoute handler={AppRoute}/>

        <Route
          addHandlerKey
          name="question"
          path={baseUrl + "/questions/:id"}
          handler={QuestionRoute} />

        <Route
          addHandlerKey
          name="answer_matrix"
          path={baseUrl + "/answer_matrix"}
          handler={AnswerMatrixRoute} />
      </Route>
    </Routes>
  );
});