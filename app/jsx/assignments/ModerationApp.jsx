/** @jsx React.DOM */

define([
  'react',
  './ModeratedStudentList',
  './stores/ModerationStore',
  './actions/ModerationActions'
], function (React, ModeratedStudentList, Store, Actions) {

  return React.createClass({
    displayName: 'ModerationApp',
    componentDidMount () {
      this.actions.loadInitialSubmissions(this.props.student_submissions_url);
    },
    componentWillMount () {
      this.store = new Store();
      this.actions = new Actions(this.store);
    },
    render () {
      return (
        <ModeratedStudentList actions={this.actions} store={this.store} />
      );
    }
  });

});
