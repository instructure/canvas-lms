(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  define(['js!vendor/jquery-1.6.4.js!order', 'js!jquery.ajaxJSON.js!order', 'js!i18n.js!order', 'js!vendor/handlebars.vm.js!order', 'js!compiled/handlebars_helpers.js!order', 'js!compiled/Template.js!order', 'js!jst/courseList/wrapper.js!order', 'js!jst/courseList/content.js!order', 'js!compiled/util/objectCollection.js!order', 'js!compiled/widget/CustomList.js!order'], function() {
    module('CustomList', {
      setup: function() {
        var index, items;
        loadFixture('CustomList');
        items = window.items = [];
        for (index = 0; index <= 100; index++) {
          items.push({
            id: index,
            shortName: "Course " + index,
            longName: "Course long " + index,
            subtitle: "Enrolled as Teacher",
            href: "/courses/" + index
          });
        }
        this.list = new CustomList('#customList', items, {
          url: 'fixtures/ok.json',
          appendTarget: '#customList'
        });
        this.list.open();
        return this.lis = jQuery('.customListItem');
      },
      teardown: function() {
        return removeFixture('CustomList');
      }
    });
    test('should open and close', function() {
      this.list.close();
      equal(this.list.wrapper.is(':visible'), false, 'starts hidden');
      this.list.open();
      return equal(this.list.wrapper.is(':visible'), true, 'displays on open');
    });
    asyncTest('should remove and add the first item', 2, function() {
      var originalLength;
      originalLength = this.list.targetList.children().length;
      simulateClick(this.lis[0]);
      simulateClick(this.lis[1]);
      return setTimeout(__bind(function() {
        var expectedLength;
        expectedLength = originalLength - 1;
        equal(this.list.pinned.length, expectedLength, 'only one item should have been removed');
        simulateClick(this.lis[0]);
        equal(this.list.pinned.length, originalLength, 'item should be restored');
        return start();
      }, this), 300);
    });
    test('should cancel pending add request on remove', function() {
      var el, item;
      el = jQuery(this.lis[16]);
      this.list.add(16, el);
      ok(this.list.requests.add[16], 'create an "add" request');
      item = this.list.pinned.findBy('id', 16);
      this.list.remove(item, el);
      return equal(this.list.requests.add[16], void 0, 'delete "add" request');
    });
    test('should cancel pending remove request on add', function() {
      var el, item;
      el = jQuery(this.lis[1]);
      item = this.list.pinned.findBy('id', 1);
      this.list.remove(item, el);
      ok(this.list.requests.remove[1], 'create a "remove" request');
      this.list.add(1, el);
      return equal(this.list.requests.remove[1], void 0, 'delete "remove" request');
    });
    return asyncTest('should reset', 2, function() {
      var originalLength;
      originalLength = this.list.targetList.children().length;
      simulateClick(this.lis[0]);
      return setTimeout(__bind(function() {
        var button, length;
        ok(originalLength !== this.list.targetList.children().length, 'length should be different');
        button = jQuery('.customListRestore')[0];
        simulateClick(button);
        length = this.list.targetList.children().length;
        equal(length, originalLength, 'targetList items restored');
        return start();
      }, this), 600);
    });
  });
}).call(this);
