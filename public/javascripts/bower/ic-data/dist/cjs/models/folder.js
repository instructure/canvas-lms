"use strict";
var Model = require("ember-data").Model;
var attr = require("ember-data").attr;
var hasMany = require("ember-data").hasMany;
var belongsTo = require("ember-data").belongsTo;
var ArrayProxy = require("ember").ArrayProxy;
var copy = require("ember").copy;
var PaginatedArrayProxy = require("./paginated-array-proxy")["default"] || require("./paginated-array-proxy");

var Folder = Model.extend({
  parent_folder: belongsTo('folder', {async:true, inverse:'folders'}),

  folders: hasMany('folder', { async:true, inverse: 'parent_folder' }),

  context_type: attr(),

  context_id: attr(),

  files: hasMany('file', { async: true }),

  children: function(){
    return PaginatedArrayProxy.create({folder:this});

  }.property(),

  files_count: attr(),

  position: attr(),

  folders_url: attr(),

  files_url: attr(),

  full_name: attr(),

  isRoot: null,

  course_id: attr(),

  courseIdProperty: function(){
    var id = this.get('course_id');
    if (id){
      this.set('courseIdCache', id);
      return id;
    }
    return this.get('courseIdCache');
  }.property('course_id'),

  fullNameProperty: function(){
    var id = this.get('full_name');
    if (id){
      this.set('fullNameCache', id);
      return id;
    }
    return this.get('fullNameCache');
  }.property('full_name'),

  folders_count: attr(),

  name: attr(),

  // TODO: take out when things get fixed upstream in ember-data
  updateHasMany: function(name, records){
    this._super(name, records);
    var hasMany = this._relationships[name];
    var type = hasMany.get('type');
    hasMany.set('meta', copy(this.store.metadataFor(type)));
  }

  /*
  TODO uncomment once we figuure out the container isssue
  created_at: attr('date'),

  updated_at: attr('date'),

  lock_at: attr('date'),

  unlock_at: attr('date'),

  hidden: attr('boolean'),

  hidden_for_user: attr('boolean'),

  locked: attr('boolean'),

  locked_for_user: attr('boolean'),
  */

});

exports["default"] = Folder;