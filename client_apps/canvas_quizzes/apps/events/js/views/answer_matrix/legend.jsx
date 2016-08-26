/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var Emblem = require('jsx!./emblem');
  var I18n = require('i18n!quiz_log_auditing.table_view');

  /**
   * @class Events.Views.AnswerMatrix.Legend
   *
   * A legend that explains what each type of "answer circle" denotes.
   *
   * @seed
   *   {}
   */
  var Legend = React.createClass({
    shouldComponentUpdate: function(nextProps, nextState) {
      return false;
    },

    render: function() {
      return (
        <dl id="ic-AnswerMatrix__Legend">
          <dt>
            {I18n.t('legend.empty_circle', 'Empty Circle')}
          </dt>
          <dd>
            <Emblem />
            {I18n.t('legend.empty_circle_desc', 'An empty answer.')}
          </dd>

          <dt>
            {I18n.t('legend.dotted_circle', 'Dotted Circle')}
          </dt>
          <dd>
            <Emblem answered />
            {I18n.t('legend.dotted_circle_desc', 'An answer, regardless of correctness.')}
          </dd>

          <dt>
            {I18n.t('legend.filled_circle', 'Filled Circle')}
          </dt>
          <dd>
            <Emblem answered last />
            {I18n.t('legend.filled_circle_desc', 'The final answer for the question, the one that counts.')}
          </dd>
        </dl>
      );
    }
  });

  return Legend;
});