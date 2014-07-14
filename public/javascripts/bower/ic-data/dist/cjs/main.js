"use strict";
var BaseAdapter = require("./adapters/base")["default"] || require("./adapters/base");
var BaseSerializer = require("./serializers/base")["default"] || require("./serializers/base");

var Course = require("./models/course")["default"] || require("./models/course");
var CourseAdapter = require("./adapters/course")["default"] || require("./adapters/course");
var CourseSerializer = require("./serializers/course")["default"] || require("./serializers/course");

var Module = require("./models/module")["default"] || require("./models/module");
var ModuleAdapter = require("./adapters/module")["default"] || require("./adapters/module");
var ModuleSerializer = require("./serializers/module")["default"] || require("./serializers/module");

var ModuleItem = require("./models/module-item")["default"] || require("./models/module-item");
var ModuleItemSerializer = require("./serializers/module-item")["default"] || require("./serializers/module-item");
var ModuleItemAdapter = require("./adapters/module-item")["default"] || require("./adapters/module-item");

var File = require("./models/file")["default"] || require("./models/file");
var FileSerializer = require("./serializers/file")["default"] || require("./serializers/file");
var FileAdapter = require("./adapters/file")["default"] || require("./adapters/file");

var Folder = require("./models/folder")["default"] || require("./models/folder");
var FolderSerializer = require("./serializers/folder")["default"] || require("./serializers/folder");
var FolderAdapter = require("./adapters/folder")["default"] || require("./adapters/folder");

var parseLinkHeader = require("./parse-link-header")["default"] || require("./parse-link-header");
var DS = require("ember-data")["default"] || require("ember-data");
var Ember = require("ember")["default"] || require("ember");
var get = Ember.get;

DS.Store.reopen({
  find: function (type, id, context){
    if(context){
      var record = this.recordForId(type, id);
      record.set('courseIdProperty', context.courseId);
      record.set('moduleIdProperty', context.moduleId);
      record.set('fullNameProperty', context.fullName);
      record.set('isRoot', context.isRoot);
    }

    if(id){
      return this._super(type,id);
    } else {
      return this._super(type);
    }
  },

});

DS.ManyArray.reopen({
  getNextPage: function(){
    var store = get(this, 'store');
    var  type = get(this, 'type');
    var meta = this.get('meta');
    var record = this.get('owner');
    var adapter = store.adapterFor(record.constructor);
    var serializer = store.serializerFor(type);
    var hasMany = this;
    var relationship = record._relationships[this.name];
    if (!meta || !meta.next){
      return Ember.RSVP.resolve(null);
    }

    var link = meta.next;
    var promise = adapter.findHasMany(store, record, link, relationship);
    return promise.then(function(adapterPayload){
      var payload = serializer.extract(store, type, adapterPayload, null, 'findHasMany');
      var records = store.pushMany(type, payload);
      hasMany.set('meta', Ember.copy(store.metadataFor(type)));
      hasMany.addObjects(records);
      return hasMany;
    });
  }
});


DS.AdapterPopulatedRecordArray.reopen({
  load: function(data) {
    var store = get(this, 'store'),
        type = get(this, 'type'),
        records = store.pushMany(type, data),
        meta = store.metadataFor(type);

    this.setProperties({
      content: Ember.A(records),
      isLoaded: true,
      meta: Ember.copy(meta)
    });

    // TODO: should triggering didLoad event be the last action of the runLoop?
    Ember.run.once(this, 'trigger', 'didLoad');
  }
});

exports.BaseAdapter = BaseAdapter;
exports.BaseSerializer = BaseSerializer;
exports.Course = Course;
exports.CourseAdapter = CourseAdapter;
exports.CourseSerializer = CourseSerializer;
exports.Module = Module;
exports.ModuleAdapter = ModuleAdapter;
exports.ModuleSerializer = ModuleSerializer;
exports.ModuleItem = ModuleItem;
exports.ModuleItemSerializer = ModuleItemSerializer;
exports.ModuleItemAdapter = ModuleItemAdapter;
exports.File = File;
exports.FileSerializer = FileSerializer;
exports.FileAdapter = FileAdapter;
exports.Folder = Folder;
exports.FolderSerializer = FolderSerializer;
exports.FolderAdapter = FolderAdapter;
exports.parseLinkHeader = parseLinkHeader;