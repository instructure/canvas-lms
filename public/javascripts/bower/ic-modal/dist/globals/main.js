!function(e){if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),(f.ic||(f.ic={})).modal=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
"use strict";
var ModalComponent = _dereq_("./modal")["default"] || _dereq_("./modal");
var ModalFormComponent = _dereq_("./modal-form")["default"] || _dereq_("./modal-form");
var ModalTriggerComponent = _dereq_("./modal-trigger")["default"] || _dereq_("./modal-trigger");
var ModalTitleComponent = _dereq_("./modal-title")["default"] || _dereq_("./modal-title");
var modalCss = _dereq_("./templates/modal-css")["default"] || _dereq_("./templates/modal-css");
var modalTemplate = _dereq_("./templates/modal")["default"] || _dereq_("./templates/modal");
var Application = window.Ember.Application;
_dereq_("./tabbable-selector");
Application.initializer({
  name: 'ic-modal',
  initialize: function(container) {
    container.register('component:ic-modal', ModalComponent);
    container.register('component:ic-modal-form', ModalFormComponent);
    container.register('component:ic-modal-trigger', ModalTriggerComponent);
    container.register('component:ic-modal-title', ModalTitleComponent);
    container.register('template:components/ic-modal-css', modalCss);
    container.register('template:components/ic-modal-form-css', modalCss);
    container.register('template:components/ic-modal', modalTemplate);
    container.register('template:components/ic-modal-form', modalTemplate);
  }
});

exports.ModalComponent = ModalComponent;
exports.ModalFormComponent = ModalFormComponent;
exports.ModalTriggerComponent = ModalTriggerComponent;
exports.ModalTitleComponent = ModalTitleComponent;
exports.modalCss = modalCss;
},{"./modal":5,"./modal-form":2,"./modal-title":3,"./modal-trigger":4,"./tabbable-selector":6,"./templates/modal":8,"./templates/modal-css":7}],2:[function(_dereq_,module,exports){
"use strict";
var ModalComponent = _dereq_("./modal")["default"] || _dereq_("./modal");


/**
 * Modal dialog designed specifically for submitting forms.
 *
 * @event on-submit - sent when the form has been submit
 *   @param modal ModalFormComponent - the modal form being submitted
 *   @param event Event - the DOM event. If you set `event.returnValue` to a
 *     promise then the modal's `awaiting-return-value` will be true, and the
 *     modal will not close until the promise resolves.
 * @event on-cancel - sent when the modal was closed but the form was not submitted.
 * @class ModalFormComponent
 * @extends ModalComponent
 */

exports["default"] = ModalComponent.extend({

  /**
   * Can't use a custom element because we need all the goodness that browser
   * pack into forms.
   *
   * @property tagName
   * @private
   */

  tagName: 'form',

  /**
   * Because we can't use a custom tagName, we add a className for styling.
   *
   * @property classNames
   * @public
   */

  classNames: ['ic-modal-form'],

  attributeBindings: ['awaiting-return-value'],

  /**
   * Will be true when a dialog's returnValue is a promise. You can style your
   * modal with `[awaiting-return-value] {}`, or branch in your template like so:
   *
   * ```html
   * {{#ic-modal-form awaiting-return-value=saving}}
   *   {{#ic-modal-content}}
   *     {{#if saving}}
   *       Saving...
 *       {{else}}
 *         <button type="submit">Save</button>
 *       {{/if}}
   *   {{/ic-modal-content}}
   * {{/ic-modal-form}}
   * ```
   *
   * @property awaiting-return-value
   * @private
   */

  'awaiting-return-value': null,

  /**
   * Provides a way to send the 'on-cancel' action, see `close`.
   *
   * @property didSubmit Boolean
   * @private
   */

  didSubmit: false,

  /**
   * Closes the dialog after submit. If the `event.returnValue` is a promise,
   * it will wait for the promise to resolve.
   *
   * @method handleSubmit
   * @private
   */

  handleSubmit: function(event) {
    event.preventDefault();
    this.set('didSubmit', true);
    // loses focus on submit, this might be better solved in ModalComponent but
    // I don't understand the issue well enough
    Ember.run.later(this.$(), 'focus', 0);
    this.sendAction('on-submit', this, event);
    if (event.returnValue && 'function' == typeof event.returnValue.then) {
      this.set('awaiting-return-value', 'true');
      event.returnValue.then(function() {
        this.set('awaiting-return-value', null);
        this.close();
      }.bind(this), function() {
        this.set('awaiting-return-value', null);
      }.bind(this));
    } else {
      this.close();
    }
  }.on('submit'),

  close: function() {
    if (this.get('awaiting-return-value')) {
      return this.sendAction('on-invalid-close', this);
    }
    if (!this.get('didSubmit')) {
      this.sendAction('on-cancel', this);
    }
    this.set('didSubmit', false);
    return this._super.apply(this, arguments);
  }

});
},{"./modal":5}],3:[function(_dereq_,module,exports){
"use strict";
var Ember = window.Ember["default"] || window.Ember;

exports["default"] = Ember.Component.extend({
  
  tagName: 'ic-modal-title',

  attributeBindings: ['aria-hidden'],

  /**
   * Tells the screenreader not to read this element. The modal has its
   * 'aria-labelledby' set to the id of this element so it would be redundant.
   *
   * @property aria-hidden
   */

  'aria-hidden': 'true',

  /**
   * @method registerTitle
   * @private
   */

  registerWithModal: function() {
    this.get('parentView').registerTitle(this);
  }.on('willInsertElement')
    
});
},{}],4:[function(_dereq_,module,exports){
"use strict";
var Ember = window.Ember["default"] || window.Ember;
var ModalComponent = _dereq_("./modal")["default"] || _dereq_("./modal");

exports["default"] = Ember.Component.extend({

  classNames: ['ic-modal-trigger'],

  attributeBindings: [
    'aria-label',
    'disabled',
    'type'
  ],

  /**
   * We don't want triggers as the target for form submits from focused fields.
   */

  type: 'button',

  /**
   * We aren't using a tagName because we want these to always be
   * buttons. Maybe when web components land for real we can inherit
   * from HTMLButtonElement and get <ic-modal-trigger> :D
   *
   * If you change the tagName you must add tabindex and implement keyboard events
   * like a button.
   *
   * @property tagName
   * @private
   */

  tagName: 'button',

  /**
   * Finds the modal this element controls. If a trigger is a child of
   * the modal, you do not need to specify a "controls" attribute.
   *
   * @method findModal
   * @private
   */

  findModal: function() {
    var parent = findParent(this);
    if (parent) {
      // we don't care about "controls" if we are child
      this.set('modal', parent);
      parent.registerTrigger(this);
    } else {
      // later so that DOM order doesn't matter
      Ember.run.schedule('afterRender', this, function() {
        this.set('modal', Ember.View.views[this.get('controls')]);
      });
    }
  }.on('willInsertElement'),

  /**
   * Shows or hides the associated modal.
   *
   * @method toggleModalVisibility
   * @private
   */

  toggleModalVisibility: function(event) {
    this.sendAction('on-toggle', this);
    // don't focus if it was a mouse click, cause that's ugly
    var wasMouse = event.clientX && event.clientY;
    this.get('modal').toggleVisibility(this, {focus: !wasMouse});
  }.on('click'),

  /**
   * When a modal closes it will return focus to the trigger that opened
   * it, keeping the user's focus position.
   *
   * @method focus
   * @public
   */

  focus: function() {
    this.$()[0].focus();
  }

});

function findParent(trigger) {
  var parent = trigger.get('parentView');
  if (!parent) return false;
  if (parent instanceof ModalComponent) return parent;
  return findParent(parent);
}
},{"./modal":5}],5:[function(_dereq_,module,exports){
"use strict";
// http://www.w3.org/TR/wai-aria-practices/#dialog_modal

var Ember = window.Ember["default"] || window.Ember;

var alias = Ember.computed.alias;

/**
 * If you do something to move focus outside of the browser (like
 * command+l to go to the address bar) and then tab back into the
 * window, capture it and focus the first tabbable element in an active
 * modal.
 */

var lastOpenedModal = null;

Ember.$(document).on('focusin', handleTabIntoBrowser);

function handleTabIntoBrowser(event) {
  if (!lastOpenedModal) return;
  lastOpenedModal.focus();
}

/**
 * Accessible modal dialog component.
 *
 * @class Modal
 * @event willOpen
 * @event didOpen
 * @event willClose
 */

exports["default"] = Ember.Component.extend({

  tagName: 'ic-modal',

  attributeBindings: [
    'after-open',
    'aria-hidden',
    'aria-labelledby',
    'is-open',
    'role',
    'tabindex'
  ],

  /**
   * Allows for css transitions, the class is added after the dialog is
   * set to display: block. For example, to create a fade in effect:
   *
   * ```css
   * ic-dialog[is-open] {
   *   opacity: 0;
   *   transition: opacity 150ms ease;
   * }
   *
   * ic-dialog[after-open] {
   *   opacity: 1;
   * }
   * ```
   *
   * @property after-open
   * @private
   */

  'after-open': null,

  /**
   * It is counter-intuitive to have a tabindex of 0 since we don't want
   * the modal to actually be tabbable. However, were it not tabbable
   * and you click inside of it, the document gets focus and ruins all of
   * our tab navigation scoping. Now that it will keep focus, tabbing
   * after a click will work as expected. It's not actually tabbable,
   * however, since the modal is display:none when closed, and we hijack
   * tabs on the last and first tabbable elements when open.
   *
   * @property tabindex
   * @private
   */

  tabindex: 0,

  /**
   * Tells the screenreader not to read this when closed.
   *
   * @property aria-hidden
   * @private
   */

  'aria-hidden': function() {
    // coerce to string cause that's how the screenreaders like it
    return !this.get('isOpen')+'';
  }.property('isOpen'),

  /**
   * When the dialog opens the screenreader will get the label from the
   * title component
   *
   * @property aria-labelledby
   * @private
   */

  'aria-labelledby': alias('titleComponent.elementId'),

  /**
   * Used as a bound attribute so you can style modals with
   * `ic-modal[is-open] {}`.
   *
   * @property is-open
   * @private
   */

  'is-open': function() {
    return this.get('isOpen') ? 'true' : null;
  }.property('isOpen'),

  /**
   * Tells the screenreader to treat this element as a dialog.
   *
   * @property role
   * @private
   */

  role: 'dialog',

  /**
   * @property isOpen
   * @private
   */

  isOpen: false,

  /**
   * Opens the modal. Takes one option `{focus: false}`, which defaults
   * to false. If false it won't try to focus the dialog after it opens,
   * this is used when the modal is opened by a mouse click.
   *
   * @method open
   * @public
   */

  open: function(options) {
    options = options || {};
    this.trigger('willOpen');
    this.sendAction('on-open', this);
    this.set('isOpen', true);
    lastOpenedModal = this;
    Ember.run.schedule('afterRender', this, function() {
      this.maybeMakeDefaultChildren();
      this.set('after-open', 'true');
      this.trigger('didOpen');
      if (options.focus !== false) {
        // after render because we want the the default close button to get focus
        Ember.run.schedule('afterRender', this, 'focus');
      } else {
        // when options.focus is false it means we used the mouse, and designers hate
        // focus styles showing up, so lets not do that. Instead, focus the whole thing
        // so that tab will work next time.
        this.$().focus();
      }
    });
  },

  /**
   * Closes the dialog and also focuses the trigger that opened it in
   * the first place so the user's tab position is preserved with fierce
   * integrity.
   *
   * @method close
   * @public
   */

  close: function() {
    this.trigger('willClose');
    this.sendAction('on-close', this);
    this.set('isOpen', false);
    this.set('after-open', null);
    lastOpenedModal = null;
    var toggler = this.get('toggler');
    toggler && toggler.focus();
  },

  /**
   * We need to focus an element so that keyboard and screenreader users end up
   * in the right place after the dialog is opened (or when the users tabs back
   * into the browser window from the browser chrome).
   *
   * @method focus
   * @private
   */

  focus: function() {
    if (this.get('element').contains(document.activeElement)) {
      // just let it be if we already contain the activeElement
      return;
    }
    var target = this.$('[autofocus]');
    if (!target.length) target = this.$(':tabbable');
    // maybe they destroyed the close button? this shoudn't happen but could
    if (!target.length) target = this.$();
    target[0].focus();
  },

  /**
   * Shows or hides the modal, depending on current state.
   *
   * @method toggleVisibility
   * @param toggler ToggleComponent
   * @param options Object
   * @public
   */

  toggleVisibility: function(toggler, options) {
    if (this.get('isOpen')) {
      this.close();
      this.set('toggler', null);
    } else {
      this.open(options);
      if (toggler) {
        this.set('toggler', toggler);
      }
    }
  },

  /**
   * @method handleKeyDown
   * @private
   */

  handleKeyDown: function(event) {
    if (event.keyCode == 9 /*tab*/) this.keepTabNavInside(event);
    if (event.keyCode == 27 /*esc*/) this.close();
  }.on('keyDown'),

  /**
   * When the dialog is open, we want to keep all tab navigation scoped
   * to the dialog since the point of a modal is to temporarily branch
   * the current user workflow. Tabbing on the last or first tabbable
   * elements will loop back around the other.
   *
   * @method keepTabNavInside
   * @private
   */

  keepTabNavInside: function(event) {
    if (event.keyCode !== 9) return;
    var tabbable = this.$(':tabbable');
    var finalTabbable = tabbable[event.shiftKey ? 'first' : 'last']()[0];
    var leavingFinalTabbable = (
      finalTabbable === document.activeElement ||
      // handle immediate shift+tab after opening with mouse
      this.get('element') === document.activeElement
    );
    if (!leavingFinalTabbable) return;
    event.preventDefault();
    tabbable[event.shiftKey ? 'last' : 'first']()[0].focus();
  },

  /**
   * Clicking outside the dialog should close it. We don't need to
   * handle other forms of losing focus (like keyboard nav) because we
   * already handle all of the keyboard navigation when its open.
   *
   * @method closeOnClick
   * @private
   */

  closeOnClick: function(event) {
    if (event.target !== this.get('element')) return;
    this.close();
  }.on('click'),

  /**
   * Often you need a mechanism besides an ic-modal-toggle to close an
   * open dialog; when you have a dialog with a form, you want to close
   * the dialog when the form has been submitted. You can bind to this
   * attribute and set it to true, causing the dialog to close.
   *
   * ```html
   * {{#ic-modal close-when=formIsSubmitted}}
   *   <form {{action "submitForm" on="submit"}}>
   *     <button type="submit">submit</button>
   *   </form>
   * {{/ic-modal}}
   * ```
   *
   * ```js
   * App.ApplicationController = Ember.Controller.extend({
   *   actions: {
   *     submitForm: function() {
   *       // do some work
   *       this.set('formIsSubmitted', true); // dialog closes
   *     }
   *   }
   * });
   * ```
   *
   * @property close-when
   * @public
   */

  'close-when': false,

  /**
   * Facilitates 'close-when' behavior.
   *
   * @method closeWhen
   * @private
   */

  closeWhen: function() {
    if (!this.get('close-when')) return;
    this.close();
    this.set('close-when', false);
  }.observes('close-when'),

  /**
   * Often you need a mechanism besides an ic-modal-toggle to open a dialog,
   * like to start a new feature tour. You can bind to this attribute and set
   * it to true, causing the dialog to open.
   *
   * ```html
   * {{#ic-modal open-when=starTour}}
   *   Ohai
   * {{/ic-modal}}
   * ```
   *
   * ```js
   * App.ApplicationController = Ember.Controller.extend({
   *   checkTour: function() {
   *     if (ENV.NEEDS_TOUR) this.set('startTour', true);
   *   }.on('init')
   * });
   * ```
   *
   * @property close-when
   * @public
   */

  'open-when': false,

  /**
   * Facilitates 'open-when' behavior.
   *
   * @method openWhen
   * @private
   */

  openWhen: function() {
    if (!this.get('open-when')) return;
    this.open();
    this.set('open-when', false);
  }.observes('open-when'),

  /**
   * All Dialogs need a title for the screenreader (and the UI, usually
   * anyway) and a close button. If a modal does not have an
   * `ic-modal-title` or an `ic-modal-toggle` then this will create some
   * defaults.
   *
   * @method maybeMakeDefaultChildren
   * @private
   */

  maybeMakeDefaultChildren: function() {
    if (!this.get('titleComponent')) this.set('makeTitle', true);
    if (!this.get('triggerComponent')) this.set('makeTrigger', true);
  },

  /**
   * @method registerTitle
   * @private
   */

  registerTitle: function(component) {
    this.set('titleComponent', component);
  },

  /**
   * @method registerTrigger
   * @private
   */

  registerTrigger: function(component) {
    this.set('triggerComponent', component);
  }

});
},{}],6:[function(_dereq_,module,exports){
"use strict";
/*!
 * Adapted from jQuery UI core
 *
 * http://jqueryui.com
 *
 * Copyright 2014 jQuery Foundation and other contributors
 * Released under the MIT license.
 * http://jquery.org/license
 *
 * http://api.jqueryui.com/category/ui-core/
 */

var Ember = window.Ember["default"] || window.Ember;

var $ = Ember.$;

function focusable( element, isTabIndexNotNaN ) {
  var nodeName = element.nodeName.toLowerCase();
  return ( /input|select|textarea|button|object/.test( nodeName ) ?
    !element.disabled :
    "a" === nodeName ?
      element.href || isTabIndexNotNaN :
      isTabIndexNotNaN) && visible( element );
}

function visible(element) {
  var $el = $(element);
  return $.expr.filters.visible(element) &&
    !$($el, $el.parents()).filter(function() {
      return $.css( this, "visibility" ) === "hidden";
    }).length;
}

if (!$.expr[':'].tabbable) {
  $.expr[':'].tabbable = function( element ) {
    var tabIndex = $.attr( element, "tabindex" ),
      isTabIndexNaN = isNaN( tabIndex );
    return ( isTabIndexNaN || tabIndex >= 0 ) && focusable( element, !isTabIndexNaN );
  }
};
},{}],7:[function(_dereq_,module,exports){
"use strict";
var Ember = window.Ember["default"] || window.Ember;
exports["default"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("ic-modal-screen,\nic-modal,\nic-modal-main,\nic-modal-title {\n  display: block;\n}\n\nic-modal,\n.ic-modal-form {\n  display: none;\n  -webkit-overflow-scrolling: touch;\n  position: fixed;\n  bottom: 0;\n  left: 0;\n  right: 0;\n  top: 0;\n  overflow: auto;\n  background-color: hsla(0, 0%, 100%, .90);\n  padding: 10px;\n}\n\nic-modal[is-open],\n.ic-modal-form[is-open] {\n  display: block;\n}\n\nic-modal-main {\n  position: relative;\n  margin: 40px auto;\n  max-width: 800px;\n  padding: 20px;\n  border-radius: 4px;\n  background: #fff;\n  border: 1px solid hsl(0, 0%, 70%);\n}\n\nic-modal-title {\n  margin: 0 -20px 20px -20px;\n  padding: 0 20px 20px 20px;\n  border-bottom: 1px solid hsl(0, 0%, 90%);\n}\n\n.ic-modal-trigger.ic-modal-close {\n  position: absolute;\n  right: 10px;\n  top: 10px;\n  background: none;\n  border: none;\n  color: inherit;\n  font-size: 18px;\n  padding: 6px;\n}\n\n.ic-modal-trigger.ic-modal-close:focus {\n  outline: none;\n  text-shadow: 0 0 6px hsl(208, 47%, 60%),\n    0 0 2px hsl(208, 47%, 60%),\n    0 0 2px hsl(208, 47%, 60%),\n    0 0 1px hsl(208, 47%, 60%);\n}\n\n");
  
});
},{}],8:[function(_dereq_,module,exports){
"use strict";
var Ember = window.Ember["default"] || window.Ember;
exports["default"] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1, self=this, functionType="function", blockHelperMissing=helpers.blockHelperMissing, helperMissing=helpers.helperMissing;

function program1(depth0,data) {
  
  var buffer = '', stack1;
  data.buffer.push("\n  <ic-modal-main>\n\n    ");
  stack1 = helpers['if'].call(depth0, "makeTitle", {hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(2, program2, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n\n    ");
  stack1 = helpers['if'].call(depth0, "makeTrigger", {hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(5, program5, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n\n    ");
  stack1 = helpers._triageMustache.call(depth0, "yield", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n\n  </ic-modal-main>\n");
  return buffer;
  }
function program2(depth0,data) {
  
  var buffer = '', stack1, helper, options;
  data.buffer.push("\n      ");
  options={hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(3, program3, data),contexts:[],types:[],data:data}
  if (helper = helpers['ic-modal-title']) { stack1 = helper.call(depth0, options); }
  else { helper = (depth0 && depth0['ic-modal-title']); stack1 = typeof helper === functionType ? helper.call(depth0, options) : helper; }
  if (!helpers['ic-modal-title']) { stack1 = blockHelperMissing.call(depth0, 'ic-modal-title', {hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(3, program3, data),contexts:[],types:[],data:data}); }
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n    ");
  return buffer;
  }
function program3(depth0,data) {
  
  
  data.buffer.push("Modal Content");
  }

function program5(depth0,data) {
  
  var buffer = '', stack1, helper, options;
  data.buffer.push("\n      ");
  stack1 = (helper = helpers['ic-modal-trigger'] || (depth0 && depth0['ic-modal-trigger']),options={hash:{
    'class': ("ic-modal-close"),
    'aria-label': ("close")
  },hashTypes:{'class': "STRING",'aria-label': "STRING"},hashContexts:{'class': depth0,'aria-label': depth0},inverse:self.noop,fn:self.program(6, program6, data),contexts:[],types:[],data:data},helper ? helper.call(depth0, options) : helperMissing.call(depth0, "ic-modal-trigger", options));
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n    ");
  return buffer;
  }
function program6(depth0,data) {
  
  
  data.buffer.push("×");
  }

  stack1 = helpers['if'].call(depth0, "isOpen", {hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(1, program1, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n\n");
  return buffer;
  
});
},{}]},{},[1])
(1)
});