/**
 * Initialize a new Usher with an $Element or selector.
 *
 * @param {String|$Element} selector CSS selector string or jQuery element
 * @api public
 * @return {Usher}
 */

define(['jquery', 'jqueryui/core', 'vendor/usher/scrollIntoView'], function($) {

  function Usher(selector, options) {
    if (!(this instanceof Usher)) return new Usher(selector);
    this.options = $.extend({}, this.defaults, options);
    this.bindMethods();
    this.$el = jQuery(selector);
    this.eventProxy = $({});
    this.initPopups();
    this.attachEvents();
    this.$el.hide();
    return this;
  }

  Usher.prototype.defaults = {
    position: true,
    resetStyles: { opacity: 0 },
    offset: {x: 20, y: 20},
    animations: {
      left:   { left: '-=10px', opacity: 1 },
      right:  { left: '+=10px', opacity: 1 },
      bottom: { top: '+=10px',  opacity: 1 },
      top:    { top: '-=10px',  opacity: 1 }
    }
  };

  /**
   * Start a tour.
   *
   * @return {Usher}
   * @api public
   */

  Usher.prototype.start = function(index) {
    index = index == null ? 0 : index;
    this.show(index);
  };

  Usher.prototype.indexOfPopupId = function(id) {
    for (var i = 0; i < this.popups.length; i++) {
      if (this.popups[i].attr('id') == id) return i;
    }
    return -1;
  };

  /**
   * Show the popup at `index`.
   *
   * @param {Number} index
   * @return {Usher}
   * @api public
   */

  Usher.prototype.show = function(index) {
    if (typeof index === 'string') {
      index = this.indexOfPopupId(index);
    }
    this.$el.show();
    this.hideCurrent();
    this.$popup = this.popups[index];
    this.beforeShow();
    this.$popup.show();
    this.$popup.css(this.options.resetStyles);
    if (this.options.position) {
      this.position();
    }
    this.scroll(this.animate);
    this.trigger(this.$popup.attr('id'));
    return this;
  };

  /**
   * Adds event listener to the instance.
   *
   * Events:
   *
   * - when a popup is shown, triggers its id
   * - when a popup is hidden, triggers {id}:hide
   * - when the tour is closed
   *
   * @param {String} popupId
   * @param {Function} handler
   * @api public
   */

  Usher.prototype.on = function(popupId, handler) {
    this.eventProxy.on(popupId, handler);
  };

  /**
   * Removes an event listener from the instance.
   *
   * @param {String} event
   * @param {Function} handler
   * @api public
   */

  Usher.prototype.off = function(event, handler) {
    this.eventProxy.off(event, handler);
  };

  /**
   * Closes the tour.
   *
   * @returns {Usher}
   * @api public
   */

  Usher.prototype.close = function(event) {
    this.$el.hide();
    if (event) event.preventDefault();
    this.trigger('hide');
    return this;
  };

  /**
   * Called before a popup is shown.
   *
   * @api private
   */

  Usher.prototype.beforeShow = function() {
    this.trigger(this.$popup.attr('id') + ':before');
  };


  /**
   * Animates the popup.
   *
   * @api private
   */

  Usher.prototype.animate = function() {
    this.$popup.animate(this.getPopupAnimation(), 200);
  };

  /**
   * Gets animation options for the popup animation.
   *
   * @api private
   */

  Usher.prototype.getPopupAnimation = function() {
    var direction = this.$popup.data('position') || 'bottom';
    return this.options.animations[direction];
  };

  /**
   * Triggers event listeners on `name` for both the usher
   * instance and the $el.
   *
   * @param {String} name
   * @api private
   */

  Usher.prototype.trigger = function(event) {
    this.eventProxy.trigger.apply(this.eventProxy, arguments);
    this.$el.trigger.apply(this.$el, arguments);
  };

  /**
   * Binds methods to the instance to be used functionally.
   *
   * @api private
   */

  Usher.prototype.bindMethods = function() {
    var methods = ['initPopups', 'close', 'animate', 'showFromDataAttribute'];
    for (var i = 0; i < methods.length; i += 1) {
      this[methods[i]] = $.proxy(this, methods[i]);
    }
  };

  /**
   * Attaches events to `$el`.
   *
   * @api private
   */

  Usher.prototype.attachEvents = function() {
    this.$el.on('click.usher', '.usher-close', this.close);
    $('body').on('click.usher', '[data-usher-show]', this.showFromDataAttribute);
  };

  Usher.prototype.showFromDataAttribute = function(event) {
    var id = $(event.target).data('usherShow');
    this.show(id);
  };

  /**
   * Removes events from `$el`.
   *
   * @api private
   */

  Usher.prototype.removeEvents = function() {
    this.$el.off('.usher');
  };

  /**
   * Initializes popup elements.
   *
   * @api private
   */

  Usher.prototype.initPopups = function() {
    this.popups = this.$el.children().map(this.initPopup);
  };

  /**
   * Initialize single popup element.
   *
   * @return {$Element}
   * @api private
   */

  Usher.prototype.initPopup = function(index, el) {
    return $(el).hide().css('position', 'absolute');
  };

  /**
   * Hides current popup.
   *
   * @api private
   */

  Usher.prototype.hideCurrent = function() {
    if (!this.$popup) return; // don't first time showing
    this.$popup.hide();
    this.trigger(this.$popup.attr('id') + ':hide');
  };

  /**
   * Positions the current popup.
   *
   * @api private
   */

  Usher.prototype.position = function() {
    var pointsTo = this.$popup.data('points-to');
    if (pointsTo) {
      this.pointTo(pointsTo);
    } else {
      this.positionDefault();
    }
  };

  /**
   * Positions the current popup in the center of the viewport.
   *
   * @api private
   */

  Usher.prototype.positionDefault = function() {
    this.$popup.position(this.constructor.positions['default']);
  };

  /**
   * Positions the current popup relative to the element it points to.
   *
   * @api private
   */

  Usher.prototype.pointTo = function(pointTo) {
    var position = this.$popup.data('position') || 'bottom';
    var options = this.constructor.positions[position];
    options.of = $(pointTo);
    this.$popup.position(options);
  };

  /**
   * Scrolls the current popup into view.
   *
   * @api private
   */

  Usher.prototype.scroll = function(callback) {
    this.$popup.scrollIntoView({
      offset: this.getScrollOffset(),
      complete: callback
    });
  };

  /**
   * Determines the offset in `scroll`
   *
   * @api private
   */

  Usher.prototype.getScrollOffset = function() {
    return {
      x: parseInt(this.$popup.data('offset-x') || this.options.offset.x, 10),
      y: parseInt(this.$popup.data('offset-y') || this.options.offset.y, 10)
    };
  };

  /**
   * Map `points-to` values to `$.fn.position` options.
   */

  // collision: 'none' because $.fn.position mistakenly flips the element if
  // the `of` element has a negative scrollX :\
  Usher.positions = {
    left:      { my: 'right',  at: 'left',   collision: 'none' },
    right:     { my: 'left',   at: 'right',  collision: 'none' },
    top:       { my: 'bottom', at: 'top',    collision: 'none' },
    bottom:    { my: 'top',    at: 'bottom', collision: 'none' },
    'default': { my: 'center', at: 'center', of: window, collision: 'none' }
  };

  return Usher;

});
