/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'i18n!moderated_grading',
  './ModeratedStudentList',
  './ModerationHeader',
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

    handleSelectProvisionalGrade (studentId, selectedProvisionalId, event) {
      this.props.store.dispatch(
        Actions.selectProvisionalGrade(studentId, selectedProvisionalId)
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
          <FlashMessageHolder {...this.state.flashMessage} />
          <h1 className='screenreader-only'>{I18n.t('Moderate %{assignment_name}', {assignment_name: 'TODO!!!!!!!!'})}</h1>
          <Header
            onPublishClick={() => this.props.store.dispatch(Actions.publishGrades())}
            onReviewClick={() => this.props.store.dispatch(Actions.addStudentToModerationSet())}
            published={this.state.assignment.published}
          />
          <ModeratedColumnHeader
            includeModerationSetHeaders={this.isModerationSet(this.state.studentList.students)}
            sortDirection={this.state.studentList.sort.direction}
            markColumn={this.state.studentList.sort.column}
            store={this.props.store}
            handleSortMark1={() => this.props.store.dispatch(Actions.sortMark1Column())}
            handleSortMark2={() => this.props.store.dispatch(Actions.sortMark2Column())}
            handleSortMark3={() => this.props.store.dispatch(Actions.sortMark3Column())}
          />
          <ModeratedStudentList
            includeModerationSetColumns={this.isModerationSet(this.state.studentList.students)}
            handleCheckbox={this.handleCheckbox}
            onSelectProvisionalGrade={this.handleSelectProvisionalGrade}
            studentList={this.state.studentList}
            assignment={this.state.assignment}
            urls={this.state.urls}
          />
        </div>
      );
    }
  });

});
