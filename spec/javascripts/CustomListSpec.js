(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  define(['jquery.ajaxJSON', 'i18n', 'compiled/widget/CustomList', 'helpers/simulateClick', 'helpers/loadFixture'], function(_, I18n, CustomList, simulateClick, loadFixture) {
    module('CustomList', {
      setup: function() {
        var index, items;
        this.fixture = loadFixture('CustomList');
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
        this.list = new CustomList(this.fixture.find('#customList'), items, {
          url: 'fixtures/ok.json',
          appendTarget: this.fixture.find('#customList')
        });
        this.list.open();
        return this.lis = this.fixture.find('.customListItem');
      },
      teardown: function() {
        return this.fixture.detach();
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
