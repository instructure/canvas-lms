define(['ember'], function(Ember) {
window.ic = window.ic || {};

ic.IcDialogTriggerComponent = Ember.Component.extend({

  classNames: ['ic-dialog-trigger'],

  click: Ember.aliasMethod('toggleDialog'),

  toggleDialog: function() {
    var view;
    if (this.get('controls')) {
      view = Ember.View.views[this.get('controls')];
    } else {
      view = this.get('parentView');
    }
    view.toggleVisiblity(this.get('action'));
  }

});


window.ic = window.ic || {};

ic.IcDialogComponent = Ember.Component.extend({

  classNames: ['ic-dialog'],

  classNameBindings: [
    'is-open',
    'modal:ic-modal'
  ],

  modal: false,

  click: function(event) {
    if (event.target === this.$('.ic-dialog-wrapper')[0]) {
      this.toggleVisiblity();
    }
  },

  toggleVisiblity: function(action) {
    this.toggleProperty('is-open');
    if (this.get('is-open')) {
      this.sendAction('on-open');
    } else {
      this.sendAction('on-close', action);
    }
  },

  position: function() {
    if (!this.get('is-open')) { return; }
    this.$('.ic-dialog-content').css({
      left: parseInt(this.calculateCenter('width'), 10),
      top: parseInt(this.calculateCenter('height'), 10)
    });
  }.observes('is-open').on('didInsertElement'),

  calculateCenter: function(axis) {
    var capitalize = Ember.String.capitalize;
    var divisors = { height: 2.5, width: 2};
    var windowSize = window['inner'+capitalize(axis)] / divisors[axis];
    var elementSize = this.$('.ic-dialog-content')[axis]() / divisors[axis];
    return windowSize - elementSize;
  }

});


Ember.Application.initializer({

  name: 'ic-dialog',

  initialize: function(container, application) {
    container.register('component:ic-dialog', ic.IcDialogComponent);
    container.register('component:ic-dialog-trigger', ic.IcDialogTriggerComponent);
  }

});


Ember.TEMPLATES["components/ic-dialog-css"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("<style>\n\n  .ic-dialog {\n    display: none;\n  }\n\n  .ic-dialog.is-open {\n    display: block;\n  }\n\n  .ic-dialog-wrapper {\n    position: fixed;\n    z-index: 10000; /* yeah, 10,000 */\n    left: 0;\n    right: 0;\n    top: 0;\n    bottom: 0;\n  }\n\n  .ic-modal > .ic-dialog-wrapper {\n    background: rgba(0, 0, 0, 0.5);\n  }\n\n  .ic-dialog-content {\n    background: #fff;\n    position: absolute;\n    width: 500px;\n  }\n\n  .ic-dialog-handle {\n    position: absolute;\n    bottom: 0;\n    right: 0;\n  }\n\n  .ic-dialog-handle {\n    width: 16px;\n    height: 16px;\n    border: 1px solid;\n    border-bottom: none;\n    border-right: none;\n    background: #efefef;\n    cursor: nwse-resize;\n  }\n\n</style>\n");
  
});

Ember.TEMPLATES["components/ic-dialog-trigger"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', hashTypes, hashContexts, escapeExpression=this.escapeExpression;


  hashTypes = {};
  hashContexts = {};
  data.buffer.push(escapeExpression(helpers._triageMustache.call(depth0, "yield", {hash:{},contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data})));
  data.buffer.push("\n\n");
  return buffer;
  
});

Ember.TEMPLATES["components/ic-dialog"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1, hashTypes, hashContexts, escapeExpression=this.escapeExpression, self=this;

function program1(depth0,data) {
  
  var buffer = '', hashTypes, hashContexts;
  data.buffer.push("\n      ");
  hashTypes = {};
  hashContexts = {};
  data.buffer.push(escapeExpression(helpers._triageMustache.call(depth0, "ic-dialog-drag-handle", {hash:{},contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data})));
  data.buffer.push("\n    ");
  return buffer;
  }

  data.buffer.push("<div class=\"ic-dialog-wrapper\">\n  <div class=\"ic-dialog-content\">\n    ");
  hashTypes = {};
  hashContexts = {};
  data.buffer.push(escapeExpression(helpers._triageMustache.call(depth0, "yield", {hash:{},contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data})));
  data.buffer.push("\n    ");
  hashTypes = {};
  hashContexts = {};
  stack1 = helpers['if'].call(depth0, "draggable", {hash:{},inverse:self.noop,fn:self.program(1, program1, data),contexts:[depth0],types:["ID"],hashContexts:hashContexts,hashTypes:hashTypes,data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n  </div>\n</div>\n\n");
  return buffer;
  
});
  return ic;
});