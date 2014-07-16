import BaseAdapter from './adapters/base';
import BaseSerializer from './serializers/base';

import Course from './models/course';
import CourseAdapter from './adapters/course';
import CourseSerializer from './serializers/course';

import Module from './models/module';
import ModuleAdapter from './adapters/module';
import ModuleSerializer from './serializers/module';

import ModuleItem from './models/module-item';
import ModuleItemSerializer from './serializers/module-item';
import ModuleItemAdapter from './adapters/module-item';

import File from './models/file';
import FileSerializer from './serializers/file';
import FileAdapter from './adapters/file';

import Folder from './models/folder';
import FolderSerializer from './serializers/folder';
import FolderAdapter from './adapters/folder';

import parseLinkHeader from './parse-link-header';
import DS from 'ember-data';
import Ember from 'ember';
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

export {
  BaseAdapter,
  BaseSerializer,

  Course,
  CourseAdapter,
  CourseSerializer,

  Module,
  ModuleAdapter,
  ModuleSerializer,

  ModuleItem,
  ModuleItemSerializer,
  ModuleItemAdapter,

  File,
  FileSerializer,
  FileAdapter,

  Folder,
  FolderSerializer,
  FolderAdapter,

  parseLinkHeader
};

