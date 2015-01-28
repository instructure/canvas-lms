/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_log_auditing');

  return (
    <em className="ic-QuestionInspector__NoAnswer">
      {I18n.t('no_answer', 'No answer')}
    </em>
  );
});