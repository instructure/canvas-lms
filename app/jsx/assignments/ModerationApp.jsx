/** @jsx React.DOM */

define([
  'react',
  'i18n!moderated_grading',
  './ModeratedStudentList',
  './Header',
  './stores/ModerationStore',
  './actions/ModerationActions'
], function (React, I18n, ModeratedStudentList, Header, Store, Actions) {

  return React.createClass({
    displayName: 'ModerationApp',

    propTypes: {
      student_submissions_url: React.PropTypes.string.isRequired,
      publish_grades_url: React.PropTypes.string.isRequired
    },

    componentDidMount () {
      this.actions.loadInitialSubmissions(this.props.student_submissions_url);
    },

    componentWillMount () {
      this.store = new Store();
      this.actions = new Actions(this.store, {
        publish_grades_url: this.props.publish_grades_url
      });
    },

    render () {
      return (
        <div className='ModerationApp'>
          <h1 className='screenreader-only'>{I18n.t('Moderate %{assignment_name}', {assignment_name: 'TODO!!!!!!!!'})}</h1>
          <Header actions={this.actions} />
          <ModeratedStudentList actions={this.actions} store={this.store} />
        </div>
      );
    }
  });

});
