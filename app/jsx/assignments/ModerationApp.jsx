/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'i18n!moderated_grading',
  './ModeratedStudentList',
  './Header',
  './FlashMessageHolder',
  './actions/ModerationActions',
  './ModeratedColumnHeader'
], function (_, React, I18n, ModeratedStudentList, Header, FlashMessageHolder, Actions, ModeratedColumnHeader) {

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
    handleCheckbox (student, event) {
      if (event.target.checked) {
        this.props.store.dispatch(Actions.selectStudent(student.id));
      } else {
        this.props.store.dispatch(Actions.unselectStudent(student.id));
      }
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
    isModerationSet (students) {
      return (_.find(students, (student) => {
        return student.in_moderation_set
      }));
    },
    render () {
      return (
        <div className='ModerationApp'>
          <FlashMessageHolder store={this.props.store} />
          <h1 className='screenreader-only'>{I18n.t('Moderate %{assignment_name}', {assignment_name: 'TODO!!!!!!!!'})}</h1>
          <Header store={this.props.store} actions={Actions} />
          <ModeratedColumnHeader 
            includeModerationSetHeaders={this.isModerationSet(this.state.students)}
            handleSortByThisColumn={this.handleSortByThisColumn}
            currentSortDirection={this.state.markColumnSort.currentSortDirection}
            markColumn={this.state.markColumnSort.markColumn}
            store={this.props.store}
          />
           <ModeratedStudentList 
             includeModerationSetColumns={this.isModerationSet(this.state.students)}
             handleCheckbox={this.handleCheckbox} 
             {...this.state}
           />
        </div>
      );
    }
  });

});
