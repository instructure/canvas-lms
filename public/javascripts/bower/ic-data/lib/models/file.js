import { Model, attr, belongsTo } from 'ember-data';

var File = Model.extend({

  folder: belongsTo('folder'),

  user: attr(),//belongsTo('user', {embedded: 'always'}),

  size: attr('number'),

  'content-type': attr('number'),

  url: attr('string'),

  display_name: attr('string'),

  // used so ChildrenController can sort by 'name'
  name: Ember.computed.alias('display_name'),

  created_at: attr('date'),

  updated_at: attr('date'),

  lock_at: attr('date'),

  unlock_at: attr('date'),

  hidden: attr('boolean'),

  hidden_for_user: attr('boolean'),

  locked: attr('boolean'),

  locked_for_user: attr('boolean'),

  lock_info: attr('string'),

  lock_explanation: attr('string'),

  thumbnail_url: attr('string')


});

export default File;

