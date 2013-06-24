define(['jquery'], function($) {

  function ScrollIntoView(el, options) {
    this.callback = $.proxy(this, 'callback');
    this.$el = $(el);
    this.options = $.extend({}, this.defaults, options);
    this.findScrollParent();
    this.scroll();
  }

  ScrollIntoView.prototype.defaults = {
    duration: 200,
    offset: {
      x: 20,
      y: 20
    }
  };

  ScrollIntoView.window = $(window);

  ScrollIntoView.SCROLLABLE_ROOT = document.body;

  ScrollIntoView.prototype.scroll = function() {
    this.calculateDimensions();
    this.calculateScrollOptions();
    if ($.isEmptyObject(this.scrollOptions)) {
      this.callback();
    } else {
      this.scrollParent.animate(this.scrollOptions, this.callback);
    }
  };

  ScrollIntoView.prototype.callback = function() {
    this.options.complete && this.options.complete.call(this.$el);
  };

  ScrollIntoView.prototype.findScrollParent = function() {
    var parent = this.$el.scrollParent();
    if (parent[0] == document) {
      parent = $(this.constructor.SCROLLABLE_ROOT);
    }
    this.scrollParent = parent;
  };

  ScrollIntoView.prototype.calculateDimensions = function() {
    var el = this.calculateElementDimensions(this.$el);
    var parent = this.calculateElementDimensions(this.scrollParent);
    this.dimensions = {
      relative: {
        top: el.box.top - (parent.box.top + parent.border.top),
        right: parent.box.right - parent.border.right -
               parent.scrollbar.right - el.box.right,
        bottom: parent.box.bottom - parent.border.bottom -
                parent.scrollbar.bottom - el.box.bottom,
        left: el.box.left - (parent.box.left + parent.border.left)
      },
      element: el,
      parent: parent
    };
  };

  ScrollIntoView.prototype.calculateElementDimensions = function($el) {
    var win = this.constructor.window;
    var isRoot = $el[0] == this.constructor.SCROLLABLE_ROOT;
    if (isRoot) $el = $(document.documentElement);
    var rect = $el[0].getBoundingClientRect();
    return {
      border: this.calculateBorder($el[0]),
      scroll: {
        top: (isRoot ? win : $el).scrollTop(),
        left: (isRoot ? win : $el).scrollLeft()
      },
      scrollbar: {
        right: isRoot ? 0 : $el.innerWidth() - $el[0].clientWidth,
        bottom: isRoot ? 0 : $el.innerHeight() - $el[0].clientHeight
      },
      box: {
        top: isRoot ? 0 : rect.top,
        right: isRoot ? $el[0].clientWidth : rect.right,
        bottom: isRoot ? $el[0].clientHeight : rect.bottom,
        left: isRoot ? 0 : rect.left
      }
    };
  };

  ScrollIntoView.prototype.calculateBorder = function(el) {
    var hasComputedStyle = !!(document.defaultView &&
                           document.defaultView.getComputedStyle);
    var styles = hasComputedStyle ?
                   document.defaultView.getComputedStyle(el, null) :
                   el.currentStyle;
    var b = {
      top: (parseFloat(hasComputedStyle ?
                       styles.borderTopWidth :
                       $.css(el, "borderTopWidth")) || 0),
      left: (parseFloat(hasComputedStyle ?
                        styles.borderLeftWidth :
                        $.css(el, "borderLeftWidth")) || 0),
      bottom: (parseFloat(hasComputedStyle ?
                          styles.borderBottomWidth :
                          $.css(el, "borderBottomWidth")) || 0),
      right: (parseFloat(hasComputedStyle ?
                         styles.borderRightWidth :
                         $.css(el, "borderRightWidth")) || 0)
    };
    return {
      top: b.top,
      left: b.left,
      bottom: b.bottom,
      right: b.right,
      vertical: b.top + b.bottom,
      horizontal: b.left + b.right
    };
  };

  ScrollIntoView.prototype.calculateScrollOptions = function() {
    var options = {};
    var relative = this.dimensions.relative;
    var offset = this.options.offset;
    var e = this.dimensions.element;
    var p = this.dimensions.parent;
    if (relative.top < 0) { // above viewport
      options.scrollTop = p.scroll.top + relative.top - offset.y;
    } else if (relative.top > 0 && relative.bottom < 0) { // below viewport
      options.scrollTop = p.scroll.top + offset.y +
                          Math.min(relative.top, -relative.bottom);
    }
    if (relative.left < 0) { // left of viewport
      options.scrollLeft = p.scroll.left + relative.left - offset.x;
    } else if (relative.left > 0 && relative.right < 0) { // right of viewport
      options.scrollLeft = p.scroll.left + offset.x +
                           Math.min(relative.left, -relative.right);
    }
    this.scrollOptions = options;
  };

  $.fn.scrollIntoView = function(options, duration) {
    if (duration && options) options.duration = duration;
    new ScrollIntoView(this, options);
    return this;
  };

  return ScrollIntoView;

});
