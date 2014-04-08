var Sortable = ic.Sortable.default;

App = Ember.Application.create();

App.ApplicationRoute = Ember.Route.extend({
  model: function() {
    return findGroups();
  }
});

App.MyGroupComponent = Ember.Component.extend(Sortable, {

  attributeBindings: ['accept-type'],

  setEventData: function(event) {
    var left = this.get('element').getBoundingClientRect().left;
    var x = event.originalEvent.clientX - left;
    var clone = this.$().clone();
    clone.find('.sortable-group').remove();
    clone.appendTo(document.body);
    event.dataTransfer.setDragImage(clone[0], x, 40);
    Ember.run.later(clone, 'remove', 0);
    event.dataTransfer.setData('text/x-group', this.get('model.id'));
  },

  accepts: ['text/x-group', 'text/x-item'],

  validateDragEvent: function(event) {
    if (this.get('self-drop')) {
      return false;
    }
    var accepts = this.get('accepts');
    var transfer = event.dataTransfer.types;
    for (var i = 0, l = accepts.length; i < l; i++) {
      var type = accepts[i];
      if (transfer.contains(type)) {
        this.set('accept-type', type);
        return true;
      }
    }
    return false;
  },

  allowDrag: function(event) {
    // only allow from header
    return event.target.tagName == 'H2';
  },

  resetAcceptType: function() {
    this.set('accept-type', null);
  }.on('dragLeave'),

  acceptDrop: function(event) {
    var type = this.get('accept-type');
    this['accept:'+type](event, event.dataTransfer.getData(type));
    this.set('accept-type', null);
  },

  'accept:text/x-item': function(event, data) {
    data = JSON.parse(data);
    var myGroup = this.get('model');
    var dragGroup = findGroup(data.group_id);
    var dragItem = dragGroup.items.findBy('id', data.id);
    moveItem(dragItem, dragGroup, myGroup);
  },

  'accept:text/x-group': function(event, id) {
    var targetGroup = groups.findBy('id', parseInt(id, 10));
    groups.removeObject(targetGroup);
    var index = groups.indexOf(this.get('model'));
    if (this.get('droppedPosition') === 'after') {
      index = index + 1;
    }
    groups.insertAt(index, targetGroup);
  }

});

App.MyItemComponent = Ember.Component.extend(Sortable, {

  setEventData: function(event) {
    event.dataTransfer.setData('text/x-item', JSON.stringify(this.get('model')));
  },

  validateDragEvent: function(event) {
    return event.dataTransfer.types.contains('text/x-item');
  },

  acceptDrop: function(event) {
    var data = JSON.parse(event.dataTransfer.getData('text/x-item'));
    var targetGroup = findGroup(data.group_id);
    var targetItem = targetGroup.items.findBy('id', data.id);
    var myGroup = findGroup(this.get('model.group_id'));
    targetGroup.items.removeObject(targetItem);
    var index = myGroup.items.indexOf(this.get('model'));
    if (this.get('droppedPosition') === 'after') {
      index = index + 1;
    }
    targetItem.group_id = myGroup.id;
    myGroup.items.insertAt(index, targetItem);
  }

});


App.IconDocumentComponent = Ember.Component.extend({
  attributeBindings: ['width', 'height'],
  tagName: 'icon-document',
  width: 16,
  height: 16
});

var groups = Ember.ArrayProxy.create({
  content: [
    {
      id: 0,
      name: 'A',
      items: [
        {group_id: 0, id: 1, name: 'foo'},
        {group_id: 0, id: 2, name: 'bar'},
        {group_id: 0, id: 3, name: 'baz'},
      ]
    },
    {
      id: 1,
      name: 'B',
      items: [
        {group_id: 1, id: 10, name: 'qux'},
        {group_id: 1, id: 8, name: 'ding'}
      ]
    },

    {
      id: 2,
      name: 'C',
      items: [
        {group_id: 2, id: 5, name: 'quux'},
        {group_id: 2, id: 6, name: 'hooba'},
        {group_id: 2, id: 7, name: 'tuba'},
      ]
    }
  ]
});

function findGroups() {
  return groups;
}

function findGroup(id) {
  return groups.findProperty('id', id);
}

function moveItem(item, from, to) {
  from.items.removeObject(item);
  item.group_id = to.id;
  to.items.addObject(item);
}

