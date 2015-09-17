/** @jsx React.DOM */

define([
  'react',
  'i18n!moderated_grading',
  './ModeratedStudentList',
  './Header',
  './FlashMessageHolder',
  './actions/ModerationActions'
], function (React, I18n, ModeratedStudentList, Header, FlashMessageHolder, Actions) {

  return React.createClass({
    displayName: 'ModerationApp',

    propTypes: {
      store: React.PropTypes.object.isRequired
    },

    getInitialState () {
      return this.props.store.getState();
    },

    componentDidMount () {
      this.props.store.subscribe(this.handleChange);
      this.props.store.dispatch(Actions.apiGetStudents());
    },

    handleChange () {
      this.setState(this.props.store.getState());
    },

    render () {
      return (
        <div className='ModerationApp'>
          <FlashMessageHolder store={this.props.store} />
          <h1 className='screenreader-only'>{I18n.t('Moderate %{assignment_name}', {assignment_name: 'TODO!!!!!!!!'})}</h1>
          <Header store={this.props.store} actions={Actions} />
          <ModeratedStudentList {...this.state} />
        </div>

      );
    }
  });

});
