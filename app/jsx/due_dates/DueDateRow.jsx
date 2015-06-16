/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'jsx/due_dates/DueDateTokenWrapper',
  'jsx/due_dates/DueDateCalendars',
  'jsx/due_dates/DueDateRemoveRowLink',
  'i18n!assignments',
  'jquery'
], (_ , React, DueDateTokenWrapper, DueDateCalendars, DueDateRemoveRowLink, I18n, $) => {

  var DueDateTokenWrapper = React.createFactory(DueDateTokenWrapper)
  var DueDateCalendars = React.createFactory(DueDateCalendars)
  var DueDateRemoveRowLink = React.createFactory(DueDateRemoveRowLink)

  var DueDateRow = React.createClass({

    propTypes: {
      overrides: React.PropTypes.array.isRequired,
      rowKey: React.PropTypes.string.isRequired,
      dates: React.PropTypes.object.isRequired,
      students: React.PropTypes.object.isRequired,
      sections: React.PropTypes.object.isRequired,
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
    // 1 adhoc overrides => 1 token per student
    // 1 section overrides => 1 token for the section

    tokenizedOverrides(){
      var {sectionOverrides, adhocOverrides} = _.groupBy(this.props.overrides,
        (ov) => {
          return !!ov.get("course_section_id") ? "sectionOverrides" : "adhocOverrides"
        }
      )

      return _.union(
        this.tokenizedSections(sectionOverrides),
        this.tokenizedAdhoc(adhocOverrides)
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

    tokenizedAdhoc(adhocOverrides){
      var adhocOverrides = adhocOverrides || []
      return _.reduce(adhocOverrides, (overrideTokens, ov) => {
        var tokensForStudents = _.map(ov.get("student_ids"), this.tokenFromStudentId, this)
        return overrideTokens.concat(tokensForStudents)
      }, [])
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

      var section = this.props.sections[sectionId]
      return section ? section["name"] : I18n.t("Loading...")
    },

    nameForStudentToken(studentId){
      var student = this.props.students[studentId]
      return student ? student["name"] : I18n.t("Loading...")
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
        <div className="Container__DueDateRow-item" data-row-key={this.props.rowKey} >
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
