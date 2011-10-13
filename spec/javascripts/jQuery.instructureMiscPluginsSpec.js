(function() {
  define(['js!vendor/jquery-1.6.4.js', 'js!jquery.instructure_misc_plugins.js!order'], function() {
    module('instructure misc plugins');
    test('showIf', function() {
      var el;
      loadFixture("jQuery.instructureMiscPlugins");
      el = jQuery('#checkbox1');
      el.showIf(function() {
        return true;
      });
      equal(el.is(":visible"), true, 'should show if callback returns true');
      el.showIf(function() {
        return false;
      });
      equal(el.is(":visible"), false, 'should be hidden if callback returns false');
      el.showIf(true);
      equal(el.is(":visible"), true, 'should show if true as argument');
      el.showIf(false);
      equal(el.is(":visible"), false, 'should not show if false as argument');
      el.showIf(true);
      equal(el.is(":visible"), true);
      equal(el.showIf(function() {
        return true;
      }), el);
      equal(el.showIf(function() {
        return false;
      }), el);
      equal(el.showIf(true), el);
      equal(el.showIf(false), el);
      el.showIf(function() {
        ok(this.nodeType);
        return notEqual(this.constructor, jQuery);
      });
      return removeFixture("jQuery.instructureMiscPlugins");
    });
    return test('disableIf', function() {
      var el;
      loadFixture("jQuery.instructureMiscPlugins");
      el = jQuery('#checkbox1');
      el.disableIf(function() {
        return true;
      });
      equal(el.is(":disabled"), true);
      el.disableIf(function() {
        return false;
      });
      equal(el.is(":disabled"), false);
      el.disableIf(function() {
        return true;
      });
      equal(el.is(":disabled"), true);
      el.disableIf(false);
      equal(el.is(":disabled"), false);
      el.disableIf(true);
      equal(el.is(":disabled"), true);
      equal(el.disableIf(function() {
        return true;
      }), el);
      equal(el.disableIf(function() {
        return false;
      }), el);
      equal(el.disableIf(true), el);
      equal(el.disableIf(false), el);
      return removeFixture("jQuery.instructureMiscPlugins");
    });
  });
}).call(this);
