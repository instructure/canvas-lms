define([
  'underscore',
  'react',
  'react-dom',
  'jsx/due_dates/DueDateRow',
  'jsx/due_dates/DueDateAddRowButton',
  'jsx/due_dates/OverrideStudentStore',
  'jsx/due_dates/StudentGroupStore',
  'jsx/due_dates/TokenActions',
  'compiled/models/AssignmentOverride',
  'jsx/gradebook/AssignmentOverrideHelper',
  'i18n!assignments',
  'jquery',
  'jsx/grading/helpers/GradingPeriodsHelper',
  'timezone',
  'compiled/jquery.rails_flash_notifications'
], (
  _ ,React, ReactDOM, DueDateRow, DueDateAddRowButton, OverrideStudentStore, StudentGroupStore, TokenActions,
  Override, AssignmentOverrideHelper, I18n, $, GradingPeriodsHelper, tz
) => {

  var DueDates = React.createClass({

    propTypes: {
      overrides: React.PropTypes.array.isRequired,
      syncWithBackbone: React.PropTypes.func.isRequired,
      sections: React.PropTypes.array.isRequired,
      defaultSectionId: React.PropTypes.string.isRequired,
      hasGradingPeriods: React.PropTypes.bool.isRequired,
      gradingPeriods: React.PropTypes.array.isRequired,
      isOnlyVisibleToOverrides: React.PropTypes.bool.isRequired,
      dueAt: function(props) {
        const isDate = props['dueAt'] instanceof Date
        if (!isDate && props['dueAt'] !== null) {
          return new Error('Invalid prop `dueAt` supplied to `DueDates`. Validation failed.')
        }
      }
    },

    // -------------------
    //      Lifecycle
    // -------------------

    getInitialState(){
      return {
        students: {},
        sections: {},
        noops: {[Override.conditionalRelease.noop_id]: Override.conditionalRelease},
        rows: {},
        addedRowCount: 0,
        defaultSectionId: null,
        currentlySearching: false,
        allStudentsFetched: false,
        selectedGroupSetId: null
      }
    },

    componentDidMount(){
      this.setState({
        rows: this.rowsFromOverrides(this.props.overrides),
        sections: this.formattedSectionHash(this.props.sections),
        groups: {},
        selectedGroupSetId: this.props.selectedGroupSetId
      }, this.fetchAdhocStudents)

      OverrideStudentStore.addChangeListener(this.handleStudentStoreChange)
      OverrideStudentStore.fetchStudentsForCourse()

      StudentGroupStore.setGroupSetIfNone(this.props.selectedGroupSetId)
      StudentGroupStore.addChangeListener(this.handleStudentGroupStoreChange)
      StudentGroupStore.fetchGroupsForCourse()
    },

    fetchAdhocStudents(){
      OverrideStudentStore.fetchStudentsByID(this.adhocOverrideStudentIDs())
    },

    handleStudentStoreChange(){
      if( this.isMounted() ){
        this.setState({
          students: OverrideStudentStore.getStudents(),
          currentlySearching: OverrideStudentStore.currentlySearching(),
          allStudentsFetched: OverrideStudentStore.allStudentsFetched()
        })
      }
    },

    handleStudentGroupStoreChange(){
      if( this.isMounted() ){
        this.setState({
          groups: this.formattedGroupHash(StudentGroupStore.getGroups()),
          selectedGroupSetId: StudentGroupStore.getSelectedGroupSetId()
        })
      }
    },

    // always keep React Overrides in sync with Backbone Collection
    componentWillUpdate(nextProps, nextState){
      var updatedOverrides = this.getAllOverrides(nextState.rows)
      this.props.syncWithBackbone(updatedOverrides)
    },

    // --------------------------
    //        State Change
    // --------------------------

    replaceRow(rowKey, newOverrides, rowDates){
      var tmp = {}
      var dates = rowDates || this.datesFromOverride(newOverrides[0])
      tmp[rowKey] = {overrides: newOverrides, dates: dates, persisted: false}

      var newRows = _.extend(this.state.rows, tmp)
      this.setState({rows: newRows})
    },

    // -------------------
    //       Helpers
    // -------------------

    formattedSectionHash(unformattedSections){
      var formattedSections = _.map(unformattedSections, this.formatSection)
      return _.indexBy(formattedSections, "id")
    },

    formatSection(section){
      return _.extend(section.attributes, {course_section_id: section.id})
    },

    formattedGroupHash(unformattedGroups){
      var formattedGroups = _.map(unformattedGroups, this.formatGroup)
      return _.indexBy(formattedGroups, "id")
    },

    formatGroup(group){
      return _.extend(group, {group_id: group.id})
    },

    getAllOverrides(givenRows){
      var rows = givenRows || this.state.rows
      return _.chain(rows).
               values().
               map((row) => {
                return _.map(row["overrides"], (override) => {
                  override.attributes.persisted = row.persisted
                  return override
                })
               }).
               flatten().
               compact().
               value()
    },

    adhocOverrides(){
      return _.filter(
        this.getAllOverrides(),
        (ov) => ov.get("student_ids")
      )
    },

    adhocOverrideStudentIDs(){
      return _.chain(this.adhocOverrides()).
               map((ov) => ov.get("student_ids")).
               flatten().
               uniq().
               value()
    },

    datesFromOverride(override){
      return {
        due_at: (override ? override.get("due_at") : null),
        lock_at: (override ? override.get("lock_at") : null),
        unlock_at: (override ? override.get("unlock_at") : null)
      }
    },

    groupsForSelectedSet(){
      var allGroups = this.state.groups
      var setId = this.state.selectedGroupSetId
      return _.chain(allGroups)
        .filter( function(value, key) {
          return value.group_category_id === setId
        })
        .indexBy("id")
        .value()
    },

    // -------------------
    //      Row Setup
    // -------------------

    rowsFromOverrides(overrides){
      var overridesByKey = _.groupBy(overrides, (override) => {
        override.set("rowKey", override.combinedDates())
        return override.get("rowKey")
      })

      return _.chain(overridesByKey)
        .map((overrides, key) => {
          var datesForGroup = this.datesFromOverride(overrides[0])
          return [key, {overrides: overrides, dates: datesForGroup, persisted: true}]
        })
        .object()
        .value()
    },

    sortedRowKeys(){
      var {datedKeys, numberedKeys} = _.chain(this.state.rows)
        .keys()
        .groupBy( (key) => {
          return key.length > 11 ? "datedKeys" : "numberedKeys"
        })
        .value()

      return _.chain([datedKeys,numberedKeys]).flatten().compact().value()
    },


    rowRef(rowKey){
      return "due_date_row-" + rowKey;
    },

    // ------------------------
    // Adding and Removing Rows
    // ------------------------

    addRow(){
      var newRowCount = this.state.addedRowCount + 1
      this.replaceRow(newRowCount, [], {})
      this.setState({ addedRowCount: newRowCount }, function() {
        this.focusRow(newRowCount);
      })
    },

    removeRow(rowToRemoveKey){
      if ( !this.canRemoveRow() ) return

      var previousIndex = _.indexOf(this.sortedRowKeys(), rowToRemoveKey);
      var newRows = _.omit(this.state.rows, rowToRemoveKey);
      this.setState({ rows: newRows }, function() {
        var ks = this.sortedRowKeys();
        var previousRowKey = ks[previousIndex] || ks[ks.length - 1];
        this.focusRow(previousRowKey);
      })
    },

    canRemoveRow(){
      return this.sortedRowKeys().length > 1;
    },

    focusRow(rowKey){
      ReactDOM.findDOMNode(this.refs[this.rowRef(rowKey)]).querySelector('input').focus();
    },

    // --------------------------
    // Adding and Removing Tokens
    // --------------------------

    changeRowToken(addOrRemoveFunction, rowKey, changedToken){
      if (!changedToken) return
      var row = this.state.rows[rowKey]

      var newOverridesForRow = addOrRemoveFunction.call(TokenActions,
        changedToken,
        row["overrides"],
        rowKey,
        row["dates"]
      )

      this.replaceRow(rowKey, newOverridesForRow, row["dates"])
    },

    handleTokenAdd(rowKey, newToken){
      this.changeRowToken(TokenActions.handleTokenAdd, rowKey, newToken)
    },

    handleTokenRemove(rowKey, tokenToRemove){
      this.changeRowToken(TokenActions.handleTokenRemove, rowKey, tokenToRemove)
    },

    replaceDate(rowKey, dateType, newDate){
      var oldOverrides = this.state.rows[rowKey].overrides
      var oldDates = this.state.rows[rowKey].dates

      var newOverrides = _.map(oldOverrides, (override) => {
        override.set(dateType, newDate)
        return override
      })

      var tmp = {}
      tmp[dateType] = newDate
      var newDates = _.extend(oldDates, tmp)

      this.replaceRow(rowKey, newOverrides, newDates)
    },

    // --------------------------
    //  Everyone v Everyone Else
    // --------------------------

    defaultSectionNamer(sectionID){
      if (sectionID !== this.props.defaultSectionId) return null

      var onlyDefaultSectionChosen = _.isEqual(this.chosenSectionIds(), [sectionID])
      var noSectionsChosen = _.isEmpty(this.chosenSectionIds())

      var noGroupsChosen = _.isEmpty(this.chosenGroupIds())
      var noStudentsChosen = _.isEmpty(this.chosenStudentIds())

      var defaultSectionOrNoSectionChosen = onlyDefaultSectionChosen || noSectionsChosen

      if ( defaultSectionOrNoSectionChosen && noStudentsChosen && noGroupsChosen) {
        return I18n.t("Everyone")
      }
      return I18n.t("Everyone Else")
    },

    addStudentIfInClosedPeriod(gradingPeriodsHelper, students, dueDate, studentID) {
      const student = this.state.students[studentID]

      if (student && gradingPeriodsHelper.isDateInClosedGradingPeriod(dueDate)) {
        students = students.concat(student)
      }

      return students
    },

    studentsInClosedPeriods() {
      const allStudents = _.values(this.state.students)
      if (_.isEmpty(allStudents)) return allStudents

      const overrides = _.map(this.props.overrides, override => override.attributes)
      const assignment = {
        due_at: this.props.dueAt,
        only_visible_to_overrides: this.props.isOnlyVisibleToOverrides
      }

      const effectiveDueDates = AssignmentOverrideHelper.effectiveDueDatesForAssignment(assignment, overrides, allStudents)
      const gradingPeriodsHelper = new GradingPeriodsHelper(this.props.gradingPeriods)
      return _.reduce(effectiveDueDates, this.addStudentIfInClosedPeriod.bind(this, gradingPeriodsHelper), [])
    },

    // --------------------------
    //  Filtering Dropdown Opts
    // --------------------------
    // if a student/section has already been selected
    // it is no longer a valid option -> hide it

    validDropdownOptions(){
      let validStudents = this.valuesWithOmission({object: this.state.students, keysToOmit: this.chosenStudentIds()})
      let validGroups = this.valuesWithOmission({object: this.groupsForSelectedSet(), keysToOmit: this.chosenGroupIds()})
      let validSections = this.valuesWithOmission({object: this.state.sections, keysToOmit: this.chosenSectionIds()})
      let validNoops = this.valuesWithOmission({object: this.state.noops, keysToOmit: this.chosenNoops()})
      if (this.props.hasGradingPeriods && !_.contains(ENV.current_user_roles, "admin")) {
        ({validStudents, validGroups, validSections} =
          this.filterDropdownOptionsForMultipleGradingPeriods(validStudents, validGroups, validSections))
      }

      return _.union(validStudents, validSections, validGroups, validNoops)
    },

    extractGroupsAndSectionsFromStudent(groups, toOmit, student) {
      _.each(student.group_ids, function(groupID) {
        toOmit.groupsToOmit[groupID] = toOmit.groupsToOmit[groupID] || groups[groupID]
      })
      _.each(student.sections, (sectionID) => {
        toOmit.sectionsToOmit[sectionID] = toOmit.sectionsToOmit[sectionID] || this.state.sections[sectionID]
      })
      return toOmit
    },

    groupsAndSectionsInClosedPeriods(studentsToOmit) {
      const groups = this.groupsForSelectedSet()
      const omitted = _.reduce(
        studentsToOmit,
        this.extractGroupsAndSectionsFromStudent.bind(this, groups),
        { groupsToOmit: {}, sectionsToOmit: {} }
      )

      return {
        groupsToOmit: _.values(omitted.groupsToOmit),
        sectionsToOmit: _.values(omitted.sectionsToOmit)
      }
    },

    filterDropdownOptionsForMultipleGradingPeriods(students, groups, sections) {
      const studentsToOmit = this.studentsInClosedPeriods()

      if (_.isEmpty(studentsToOmit)) {
        return { validStudents: students, validGroups: groups, validSections: sections }
      } else {
        const { groupsToOmit, sectionsToOmit } = this.groupsAndSectionsInClosedPeriods(studentsToOmit)

        return {
          validStudents: _.difference(students, studentsToOmit),
          validGroups: _.difference(groups, groupsToOmit),
          validSections: _.difference(sections, sectionsToOmit)
        }
      }

    },

    chosenIds(idType){
      return _.chain(this.getAllOverrides()).
               map((ov) => ov.get(idType)).
               compact().
               value()
    },

    chosenSectionIds(){
      return this.chosenIds("course_section_id")
    },

    chosenStudentIds(){
      return _.flatten(this.chosenIds("student_ids"))
    },

    chosenGroupIds(){
      return this.chosenIds("group_id")
    },

    chosenNoops(){
      return this.chosenIds("noop_id")
    },

    valuesWithOmission(args){
      return _.chain(args["object"]).
               omit(args["keysToOmit"]).
               values().
               value()
    },

    disableInputs(row) {
      const rowIsNewOrUserIsAdmin = !row.persisted || _.contains(ENV.current_user_roles, "admin")
      if (!this.props.hasGradingPeriods || rowIsNewOrUserIsAdmin) {
        return false
      }

      const dates = (row.dates || {})
      return this.isInClosedGradingPeriod(dates.due_at)
    },

    isInClosedGradingPeriod(date) {
      if (date === undefined) return false

      const dueAt = date === null ? null : new Date(date)
      return new GradingPeriodsHelper(this.props.gradingPeriods).isDateInClosedGradingPeriod(dueAt)
    },

    // -------------------
    //      Rendering
    // -------------------

    rowsToRender(){
      return _.map(this.sortedRowKeys(), (rowKey) => {
        var row = this.state.rows[rowKey]
        var overrides = row.overrides || []
        var dates = row.dates || {}
        return (
          <DueDateRow
            ref                  = {this.rowRef(rowKey)}
            inputsDisabled       = {this.disableInputs(row)}
            overrides            = {overrides}
            key                  = {rowKey}
            rowKey               = {rowKey}
            dates                = {dates}
            students             = {this.state.students}
            sections             = {this.state.sections}
            groups               = {this.state.groups}
            canDelete            = {this.canRemoveRow()}
            validDropdownOptions = {this.validDropdownOptions()}
            handleDelete         = {this.removeRow.bind(this, rowKey)}
            handleTokenAdd       = {this.handleTokenAdd.bind(this, rowKey)}
            handleTokenRemove    = {this.handleTokenRemove.bind(this, rowKey)}
            defaultSectionNamer  = {this.defaultSectionNamer}
            replaceDate          = {this.replaceDate.bind(this, rowKey)}
            currentlySearching   = {this.state.currentlySearching}
            allStudentsFetched   = {this.state.allStudentsFetched}
          />
        )
      })
    },

    render() {
      var rowsToRender = this.rowsToRender()
      return (
        <div className="ContainerDueDate">
          <div id="bordered-wrapper" className="Container__DueDateRow">
            {rowsToRender}
          </div>
          <DueDateAddRowButton handleAdd={this.addRow} display={true}/>
        </div>
      )
    }
  })

  return DueDates
});
