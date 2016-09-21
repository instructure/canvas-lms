define([
  'underscore',
  'compiled/models/AssignmentOverride',
  'compiled/models/Section'
], (_, AssignmentOverride, Section) => {

  var TokenActions = {

    // -------------------
    //   Adding Tokens
    // -------------------

    handleTokenAdd(newToken, overridesFromRow, rowKey, dates){
      this.setOverrideInitializer(rowKey, dates)

      if(newToken.course_section_id) {
        return this.handleSectionTokenAdd(newToken, overridesFromRow)
      }
      else if (newToken.group_id) {
        return this.handleGroupTokenAdd(newToken, overridesFromRow)
      }
      else if (newToken.noop_id) {
        return this.handleNoopTokenAdd(newToken, overridesFromRow)
      } else {
        return this.handleStudentTokenAdd(newToken, overridesFromRow)
      }
    },

    // -- Adding Sections --

    handleSectionTokenAdd(token, overridesFromRow) {
      var newOverride = this.newOverrideForRow({
        course_section_id: token.course_section_id,
        title: token.name
      })

      return _.union(overridesFromRow, [newOverride])
    },

    // -- Adding Groups --

    handleGroupTokenAdd(token, overridesFromRow){
      var newOverride = this.newOverrideForRow({
        group_id: token.group_id,
        title: token.name
      })

      return _.union(overridesFromRow, [newOverride])
    },

    // -- Adding Students --

    handleStudentTokenAdd(token, overridesFromRow){
      var existingAdhocOverride = this.findAdhoc(overridesFromRow)

      return existingAdhocOverride ?
        this.addStudentToExistingAdhocOverride(token, existingAdhocOverride, overridesFromRow) :
        this.createNewAdhocOverrideForRow(token, overridesFromRow)
    },

    addStudentToExistingAdhocOverride(newToken, existingOverride, overridesFromRow){
      var newStudentIds = existingOverride.get( "student_ids" ).concat( newToken.id )
      var newOverride = existingOverride.set("student_ids", newStudentIds)
      newOverride.unset("title", {silent: true})

      return _.chain(overridesFromRow).
               difference([existingOverride]).
               union([newOverride]).
               value()
    },

    createNewAdhocOverrideForRow(newToken, overridesFromRow){
      var freshOverride = this.newOverrideForRow({ student_ids: [] })
      return this.addStudentToExistingAdhocOverride(newToken, freshOverride, overridesFromRow)
    },

    // -- Adding Noop --

    handleNoopTokenAdd(token, overridesFromRow){
      var newOverride = this.newOverrideForRow({
        noop_id: token.noop_id,
        title: token.name
      })

      if(token == AssignmentOverride.conditionalRelease) {
        overridesFromRow = this.removeDefaultSection(overridesFromRow)
      }

      return _.union(overridesFromRow, [newOverride])
    },

    // -------------------
    //  Removing Tokens
    // -------------------

    handleTokenRemove(tokenToRemove, overridesFromRow){
      if(tokenToRemove.course_section_id) {
        return this.handleSectionTokenRemove(tokenToRemove, overridesFromRow)
      }
      else if (tokenToRemove.group_id) {
        return this.handleGroupTokenRemove(tokenToRemove, overridesFromRow)
      }
      else if (tokenToRemove.noop_id) {
        return this.handleNoopTokenRemove(tokenToRemove, overridesFromRow)
      }
      else {
        return this.handleStudentTokenRemove(tokenToRemove, overridesFromRow)
      }
    },

    handleSectionTokenRemove(tokenToRemove, overridesFromRow){
      return this.removeForType("course_section_id", tokenToRemove, overridesFromRow)
    },

    handleGroupTokenRemove(tokenToRemove, overridesFromRow){
      return this.removeForType("group_id", tokenToRemove, overridesFromRow)
    },

    handleNoopTokenRemove(tokenToRemove, overridesFromRow){
      return this.removeForType("noop_id", tokenToRemove, overridesFromRow)
    },

    removeForType(selector, tokenToRemove, overridesFromRow){
      var overrideToRemove = _.find(overridesFromRow, function(override){
        return override.get(selector) == tokenToRemove[selector]
      })

      return _.difference(overridesFromRow, [overrideToRemove])
    },

    removeDefaultSection(overridesFromRow){
      return this.handleTokenRemove({ course_section_id: Section.defaultDueDateSectionID}, overridesFromRow)
    },

    handleStudentTokenRemove(tokenToRemove, overridesFromRow){
      var adhocOverride = this.findAdhoc(overridesFromRow, tokenToRemove.student_id)
      var newStudentIds = _.difference(adhocOverride.get("student_ids"), [tokenToRemove.student_id])

      if ( _.isEmpty(newStudentIds) ) {
        return _.difference(overridesFromRow, [adhocOverride])
      }

      var newOverride = adhocOverride.set("student_ids", newStudentIds)
      newOverride.unset("title", {silent: true})
      return _.chain(overridesFromRow).
               difference([adhocOverride]).
               union([newOverride]).
               value()
    },

    setOverrideInitializer(rowKey, dates){
      if (!dates) dates = {}

      var date_attrs = {
        due_at: dates["due_at"],
        due_at_overridden: !!dates["due_at"],
        lock_at: dates["lock_at"],
        lock_at_overridden: !!dates["lock_at"],
        unlock_at: dates["unlock_at"],
        unlock_at_overridden: !!dates["unlock_at"],
        rowKey: rowKey
      }

      this.newOverrideForRow = function(attributes){
        let all_attrs = _.extend(date_attrs, attributes)
        return new AssignmentOverride(all_attrs)
      }
    },

    // -------------------
    //      Helpers
    // -------------------

    findAdhoc(collection, idToRemove){
      return _.find(collection, (ov) =>{
        return !!ov.get("student_ids") &&
          (idToRemove ? _.contains(ov.get("student_ids"), idToRemove) : true)
      })
    },
  }

  return TokenActions
});