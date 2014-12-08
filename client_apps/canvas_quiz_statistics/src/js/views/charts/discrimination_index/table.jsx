/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_statistics.discrimination_index');
  var Text = require('jsx!../../../components/text');

  // A table for screen-readers that provides an alternative view of the data.
  var Table = React.createClass({
    getDefaultProps: function() {
      return {
        brackets: []
      };
    },

    render: function() {
      return (
        <table>
          <caption>
            <Text phrase="audible_chart_description">
              This table lists how each bracket of students in the class have
              responded to this question.

              Student brackets are composed based on their score.

              The top bracket consists of the highest 27%,
              while the middle bracket consists of the middle 46%,
              and the bottom bracket consists of the lowest 27%.
            </Text>
          </caption>

          <tbody>
            {this.props.brackets.map(this.renderEntry)}
          </tbody>
        </table>
      );
    },

    renderEntry: function(bracket) {
      var label;

      if (bracket.incorrect === 0) {
        label = I18n.t('audible_bracket_aced',
          'All students in this bracket have answered correctly.');
      }
      else if (bracket.correct === 0) {
        label = I18n.t('audible_bracket_failed',
          'Not a single student in this bracket has provided a correct answer.');
      }
      else {
        label = I18n.t('audible_response_ratio_distribution',
          '%{correct_ratio}% of students in this bracket have answered correctly.', {
            correct_ratio: bracket.correctRatio
          });
      }

      return (
        <tr key={'bracket-'+bracket.id}>
          <th scope="row">
            {bracket.label}
          </th>

          <td>
            {label}
          </td>
        </tr>
      );
    }
  });

  return Table;
});
