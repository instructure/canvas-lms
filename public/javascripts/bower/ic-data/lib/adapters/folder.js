import BaseAdapter from './base';
import {String} from 'ember';

var FolderAdapter = BaseAdapter.extend({
  findQuery: function(store, type, query){
    var contextType = query.contextType,
        contextId = query.contextId,
        fullName = query.fullName,
        url = this.buildURL(type.typeKey);

    delete query.contextType;
    delete query.contextId;
    delete query.fullName;

    if (fullName != null) { // use by_path even if full_name is ''
      url = [
        this.urlPrefix(),
        String.pluralize(contextType),
        contextId,
        'folders/by_path',
        encodeURI(fullName)
      ].join('/');
    }

    return this.ajax(url, 'GET', query).then(function(folders){
      if (!Array.isArray(folders)) folders = [folders];
      return folders;
    });
  },


 find: function(store, type, id) {

    var record = store.getById(type, id);
    if(!record.get('courseIdProperty')){
      return this._super(store,type,id);
    }
    var url = this.urlPrefix()+'/courses/'+record.get('courseIdProperty')+'/folders/'+record.get('id');
    if (record.get('isRoot')){
      url = this.urlPrefix()+'/courses/'+record.get('courseIdProperty')+'/folders/root';
    } else if (record.get('fullNameProperty')){
    }
    var courseId = record.get('courseIdProperty');
    return this.ajax(url, "GET").then( function(folders){
      if (!Array.isArray(folders)) {
        folders.course_id = courseId;
        return folders;
      }

      folders.forEach( function(folder){
        folders.course_id = courseId;
      });
      return folders;
    });
  },
  /*
  createRecord: function(store, type, record) {
    var data = {};
    var serializer = store.serializerFor(type.typeKey);
    var url = this.urlPrefix()+'/accounts/'+record.get('account_id')+'/courses';
    record.set('account_id', null);
    serializer.serializeIntoHash(data, type, record, { includeId: true });
    return this.ajax(url, "POST", { data: data });
  },

  deleteRecord: function(store, type, record) {
    var id = record.get('id');
    var data = { event: 'delete' };
    return this.ajax(this.buildURL(type.typeKey, id), "DELETE", {data: data});
  }
  */
});

export default FolderAdapter;

