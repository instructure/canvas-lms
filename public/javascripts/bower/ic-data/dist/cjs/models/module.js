"use strict";
var Model = require("ember-data").Model;
var attr = require("ember-data").attr;
var belongsTo = require("ember-data").belongsTo;
var hasMany = require("ember-data").hasMany;
var copy = require("ember").copy;

var Module = Model.extend({

  // need this to do anything
  course_id: attr(),

  items: hasMany('moduleItem', {async:true}),

  //TODO HACKS, FIX
  //Add merging support to adapterDidCommit
  courseIdProperty: function(){
    var id = this.get('course_id');
    if (id){
      this.set('courseIdCache', id);
      return id;
    }
    return this.get('courseIdCache');
  }.property('course_id'),

  name: attr(),

  updateHasMany: function(name, records){
    this._super(name, records);
    var hasMany = this._relationships[name];
    var type = hasMany.get('type');
    hasMany.set('meta', copy(this.store.metadataFor(type)));
  }
});

exports["default"] = Module;