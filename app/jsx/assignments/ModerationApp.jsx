/** @jsx React.DOM */

define([
  'react',
  'i18n!moderated_grading',
  './ModeratedStudentList',
  './Header',
  './FlashMessageHolder',
  './actions/ModerationActions',
  './ModeratedColumnHeader'
], function (React, I18n, ModeratedStudentList, Header, FlashMessageHolder, Actions, ModeratedColumnHeader) {

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

    handleSortByThisColumn (mark, props) {
      this.props.store.dispatch(
        Actions.sortMarkColumn(
          {
            previousMarkColumn: props.markColumn,
            markColumn: mark,
            currentSortDirection: props.currentSortDirection
          }
        )
      );
    },

    render () {
      return (
        <div className='ModerationApp'>
          <FlashMessageHolder store={this.props.store} />
          <h1 className='screenreader-only'>{I18n.t('Moderate %{assignment_name}', {assignment_name: 'TODO!!!!!!!!'})}</h1>
          <Header store={this.props.store} actions={Actions} />
          <ModeratedColumnHeader handleSortByThisColumn={this.handleSortByThisColumn} currentSortDirection={this.state.markColumnSort.currentSortDirection} markColumn={this.state.markColumnSort.markColumn} />
          <ModeratedStudentList {...this.state} />
        </div>
      );
    }
  });

});
