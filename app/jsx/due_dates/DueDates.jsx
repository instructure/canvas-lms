define([
  'underscore',
  'react',
  'jsx/due_dates/DueDateRow',
  'jsx/due_dates/DueDateAddRowButton',
  'jsx/due_dates/OverrideStudentStore',
  'jsx/due_dates/StudentGroupStore',
  'jsx/due_dates/TokenActions',
  'i18n!assignments',
  'jquery',
  'compiled/jquery.rails_flash_notifications'
], (_ ,React, DueDateRow, DueDateAddRowButton, OverrideStudentStore, StudentGroupStore, TokenActions, I18n, $) => {

  var DueDates = React.createClass({

    propTypes: {
      overrides: React.PropTypes.array.isRequired,
      syncWithBackbone: React.PropTypes.func.isRequired,
      sections: React.PropTypes.array.isRequired,
      defaultSectionId: React.PropTypes.string.isRequired
    },

    // -------------------
    //      Lifecycle
    // -------------------

    getInitialState(){
      return {
        students: {},
        sections: {},
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
      tmp[rowKey] = {overrides: newOverrides, dates: dates}

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
               map((row) => row["overrides"]).
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
          return [key, {overrides: overrides, dates: datesForGroup}]
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
      this.refs[this.rowRef(rowKey)].getDOMNode().querySelector('input').focus();
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

    // --------------------------
    //  Filtering Dropdown Opts
    // --------------------------
    // if a student/section has already been selected
    // it is no longer a valid option -> hide it

    validDropdownOptions(){
      var validStudents = this.valuesWithOmission({object: this.state.students, keysToOmit: this.chosenStudentIds()})
      var validGroups = this.valuesWithOmission({object: this.groupsForSelectedSet(), keysToOmit: this.chosenGroupIds()})
      var validSections = this.valuesWithOmission({object: this.state.sections, keysToOmit: this.chosenSectionIds()})
      return _.union(validStudents, validSections, validGroups)
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

    valuesWithOmission(args){
      return _.chain(args["object"]).
               omit(args["keysToOmit"]).
               values().
               value()
    },

    // -------------------
    //      Rendering
    // -------------------

    rowsToRender(){
      return _.map(this.sortedRowKeys(), (rowKey) => {
        var row = this.state.rows[rowKey]
        var overrides = row.overrides || []
        var dates = row.dates || {}
        return <DueDateRow ref                  = {this.rowRef(rowKey)}
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
                           allStudentsFetched   = {this.state.allStudentsFetched} />
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
