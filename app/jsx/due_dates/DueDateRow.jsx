define([
  'underscore',
  'react',
  'jsx/due_dates/DueDateTokenWrapper',
  'jsx/due_dates/DueDateCalendars',
  'jsx/due_dates/DueDateRemoveRowLink',
  'i18n!assignments',
  'jquery'
], (_ , React, DueDateTokenWrapper, DueDateCalendars, DueDateRemoveRowLink, I18n, $) => {


  var DueDateRow = React.createClass({

    propTypes: {
      overrides: React.PropTypes.array.isRequired,
      rowKey: React.PropTypes.string.isRequired,
      dates: React.PropTypes.object.isRequired,
      students: React.PropTypes.object.isRequired,
      sections: React.PropTypes.object.isRequired,
      groups: React.PropTypes.object.isRequired,
      validDropdownOptions: React.PropTypes.array.isRequired,
      handleDelete: React.PropTypes.func.isRequired,
      handleTokenAdd: React.PropTypes.func.isRequired,
      handleTokenRemove: React.PropTypes.func.isRequired,
      defaultSectionNamer: React.PropTypes.func.isRequired,
      replaceDate: React.PropTypes.func.isRequired,
      canDelete: React.PropTypes.bool.isRequired,
      currentlySearching: React.PropTypes.bool.isRequired,
      allStudentsFetched: React.PropTypes.bool.isRequired,
    },

    // --------------------
    // Tokenizing Overrides
    // --------------------

    // this component takes overrides & returns a list of tokens:
    // 1 adhoc override => 1 token per student
    // 1 section override => 1 token for the section
    // 1 group override => 1 token for the group

    tokenizedOverrides(){
      var {sectionOverrides, groupOverrides, adhocOverrides, noopOverrides} = _.groupBy(this.props.overrides,
        (ov) => {
          if (ov.get("course_section_id")) {
            return "sectionOverrides"
          } else if (ov.get("group_id")) {
            return "groupOverrides"
          } else if (ov.get("noop_id")) {
            return "noopOverrides"
          } else {
            return "adhocOverrides"
          }
        }
      )

      return _.union(
        this.tokenizedSections(sectionOverrides),
        this.tokenizedGroups(groupOverrides),
        this.tokenizedAdhoc(adhocOverrides),
        this.tokenizedNoop(noopOverrides)
      )
    },

    tokenizedSections(sectionOverrides){
      var sectionOverrides = sectionOverrides || []
      return _.map(sectionOverrides, (override) => {
        return {
            type: "section",
            course_section_id: override.get("course_section_id"),
            name: this.nameForCourseSection(override.get("course_section_id"))
          }
      })
    },

    tokenizedGroups(groupOverrides){
      var groupOverrides = groupOverrides || []
      return _.map(groupOverrides, (override) => {
        return {
            type: "group",
            group_id: override.get("group_id"),
            name: this.nameForGroup(override.get("group_id"))
          }
      })
    },

    tokenizedAdhoc(adhocOverrides){
      var adhocOverrides = adhocOverrides || []
      return _.reduce(adhocOverrides, (overrideTokens, ov) => {
        var tokensForStudents = _.map(ov.get("student_ids"), this.tokenFromStudentId, this)
        return overrideTokens.concat(tokensForStudents)
      }, [])
    },

    tokenizedNoop(noopOverrides){
      var noopOverrides = noopOverrides || []
      return _.map(noopOverrides, (override) => {
        return {
            noop_id: override.get("noop_id"),
            name: override.get("title")
          }
      })
    },

    tokenFromStudentId(studentId){
      return {
        type: "student",
        student_id: studentId,
        name: this.nameForStudentToken(studentId)
      }
    },

    nameForCourseSection(sectionId){
      var defaultName = this.props.defaultSectionNamer(sectionId)
      if(defaultName) return defaultName

      return this.nameOrLoading(
        this.props.sections,
        sectionId
      )
    },

    nameForGroup(groupId){
      return this.nameOrLoading(
        this.props.groups,
        groupId
      )
    },

    nameForStudentToken(studentId){
      return this.nameOrLoading(
        this.props.students,
        studentId
      )
    },

    nameOrLoading(collection, id){
      var item = collection[id]
      return item ? item["name"] : I18n.t("Loading...")
    },

    // -------------------
    //      Rendering
    // -------------------

    removeLinkIfNeeded(){
      if(this.props.canDelete){
        return <DueDateRemoveRowLink handleClick={this.props.handleDelete}/>
      }
    },

    render() {
      return (
        <div className="Container__DueDateRow-item" role="region" aria-label={I18n.t("Due Date Set")} data-row-key={this.props.rowKey} >
          {this.removeLinkIfNeeded()}
          <DueDateTokenWrapper tokens              = {this.tokenizedOverrides()}
                               handleTokenAdd      = {this.props.handleTokenAdd}
                               handleTokenRemove   = {this.props.handleTokenRemove}
                               potentialOptions    = {this.props.validDropdownOptions}
                               rowKey              = {this.props.rowKey}
                               defaultSectionNamer = {this.props.defaultSectionNamer}
                               currentlySearching  = {this.props.currentlySearching}
                               allStudentsFetched  = {this.props.allStudentsFetched}/>

          <DueDateCalendars dates       = {this.props.dates}
                            rowKey      = {this.props.rowKey}
                            overrides   = {this.props.overrides}
                            replaceDate = {this.props.replaceDate}
                            sections    = {this.props.sections}/>
        </div>
      )
    }

  })

  return DueDateRow
});
