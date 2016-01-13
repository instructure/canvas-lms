/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  // var d3 = require('d3');
  var _ = require('lodash');
  var I18n = require('i18n!quiz_statistics.answers_tables');
  var UserListDialog = require('jsx!./../user_list_dialog');

  var AnswerRow = React.createClass({
    propTypes: {
      datum: React.PropTypes.object.isRequired,
      graphSettings: React.PropTypes.object.isRequired
    },

    getInitialState: function() {
      return {neverLoaded: true};
    },

    dialogBuilder: function(answer) {
      if (!_.isEmpty(answer.user_names)) {
        return(
          <div>
            <UserListDialog key={answer.id+answer.poolId} answer_id={answer.id} user_names={answer.user_names} />
          </div>
        );
      }
      else if(answer.responses > 0){
        return(<div>{I18n.t('%{userCount} respondents',{userCount: answer.responses})}</div>);
      }
    },

    renderBarPlot: function() {
      return (
        <div
          key={this.props.datum.id}
          className={this.getBarClass()}
          style={this.getBarStyles()}
        >
          { this.props.datum.correct && <i className="icon-check"/> }
        </div>

      );
    },

    componentDidMount: function() {
      this.setState({neverLoaded: false});
    },

    getBarStyles: function() {
      var width = this.props.graphSettings.xScale(this.props.datum.count) + this.props.graphSettings.visibilityThreshold + "px";
      // Hacky way to get initial state width animations
      if (this.state.neverLoaded) {
        width = "0px";
      }
      return {
        width: width,
        height: this.props.graphSettings.barHeight - 2 + "px"
      };
    },

    getBarClass: function() {
      var className = this.props.datum.correct ? 'bar bar-highlighted' : 'bar';
      return (this.props.datum.special ? className + " bar-striped" : className);
    },

    render: function() {
      var datum = this.props.datum;
      return (
        <tr className={datum.correct ? 'correct' : undefined}>
          <th scope="row" className="answer-textfield">
            {datum.answer.text}
          </th>
          <td className="respondent-link">
            {this.dialogBuilder(datum.answer)}
          </td>
          <td className="answer-ratio">
            {datum.answer.ratio} <sup>%</sup>
          </td>
          <td className="answer-distribution-cell" aria-hidden style={{width: this.props.graphSettings.maxWidth}}>
            {this.renderBarPlot()}
          </td>
        </tr>
      );
    },
  });

  return AnswerRow;
});