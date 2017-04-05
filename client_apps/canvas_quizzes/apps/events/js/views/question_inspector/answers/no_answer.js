/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var I18n = require('i18n!quiz_log_auditing');

  return (
    <em className="ic-QuestionInspector__NoAnswer">
      {I18n.t('no_answer', 'No answer')}
    </em>
  );
});