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

    isModerationSet (students) {
      return !!(_.find(students, (student) => {
        return student.in_moderation_set;
      }));
    },
    handleSelectAll (event) {
      if (event.target.checked) {
        var allStudents = this.props.store.getState().students;
        this.props.store.dispatch(Actions.selectAllStudents(allStudents));
      } else {
        this.props.store.dispatch(Actions.unselectAllStudents());
      }
    },
    render () {
      return (
        <div className='ModerationApp' role="grid">
          <FlashMessageHolder {...this.state.flashMessage} />
          <h1 className='screenreader-only'>{I18n.t('Moderate %{assignment_name}', {assignment_name: this.state.assignment.title})}</h1>
          <Header
            onPublishClick={
              () => {
                this.props.store.dispatch(Actions.publishStarted());
                this.props.store.dispatch(Actions.publishGrades())
              }
            }
            onReviewClick={
              () => {
                this.props.store.dispatch(Actions.moderationStarted());
                this.props.store.dispatch(Actions.addStudentToModerationSet());
              }
            }
            published={this.state.assignment.published}
            selectedStudentCount={this.state.studentList.selectedCount}
            inflightAction={this.state.inflightAction}
          />
          <div className='grid-row' role="row">
            <div className='col-xs-12'>
              <div className='screenreader-only'>{I18n.t('Clicking on the column headers will sort the rows by that column.')}</div>
              <ModeratedColumnHeader
                includeModerationSetHeaders={this.isModerationSet(this.state.studentList.students)}
                sortDirection={this.state.studentList.sort.direction}
                markColumn={this.state.studentList.sort.column}
                store={this.props.store}
                handleSortMark1={() => this.props.store.dispatch(Actions.sortMark1Column())}
                handleSortMark2={() => this.props.store.dispatch(Actions.sortMark2Column())}
                handleSortMark3={() => this.props.store.dispatch(Actions.sortMark3Column())}
                handleSelectAll={this.handleSelectAll}
              />
            </div>
          </div>
            <div className='grid-row' role="row">
              <div className='col-xs-12'>
                <ModeratedStudentList
                  includeModerationSetColumns={this.isModerationSet(this.state.studentList.students)}
                  handleCheckbox={this.handleCheckbox}
                  onSelectProvisionalGrade={(provisionalGradeId) => this.props.store.dispatch(Actions.selectProvisionalGrade(provisionalGradeId))}
                  studentList={this.state.studentList}
                  assignment={this.state.assignment}
                  urls={this.state.urls}
                />
            </div>
          </div>
        </div>
      );
    }
  });

});
