"use strict";
var Model = require("ember-data").Model;
var attr = require("ember-data").attr;

var ModuleItem = Model.extend({
  title: attr(),

  // need this to do anything
  moduleId: attr(),

  //TODO HACKS, FIX
  //Add merging support to adapterDidCommit
  moduleIdProperty: function(key, value){
    if (value) {
      this.set('moduleIdCache', value);
      return value;
   }
    var id = this.get('moduleId');
    if (id){
      this.set('moduleIdCache', id);
      return id;
    }
    return this.get('moduleIdCache');
  },

  // need this to do anything
  courseId: attr(),

  //TODO HACKS, FIX
  //Add merging support to adapterDidCommit
  courseIdProperty: function(key, value){
    if (value) {
      this.set('courseIdCache', value);
      return value;
   }
    var id = this.get('courseId');
    if (id){
      this.set('courseIdCache', id);
      return id;
    }
    return this.get('courseIdCache');
  }.property('courseId')

});
exports["default"] = ModuleItem;