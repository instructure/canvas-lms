(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  describe("CustomList", function() {
    beforeEach(__bind(function() {
      var index, items;
      loadFixtures('CustomList.html');
      items = [];
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
        url: '/spec/javascripts/fixtures/ok.json',
        appendTarget: '#customList'
      });
      this.list.open();
      return this.lis = jQuery('.customListItem');
    }, this));
    afterEach(__bind(function() {
      return this.list.teardown();
    }, this));
    it('should open and close', __bind(function() {
      this.list.close();
      expect(this.list.wrapper).toBeHidden();
      this.list.open();
      return expect(this.list.wrapper).toBeVisible();
    }, this));
    it('should remove and add the first item', __bind(function() {
      var originalLength;
      originalLength = this.list.targetList.children().length;
      runs(__bind(function() {
        simulateClick(this.lis[0]);
        return simulateClick(this.lis[1]);
      }, this));
      waits(this.list.options.animationDuration + 1);
      return runs(__bind(function() {
        var expectedLength;
        expectedLength = originalLength - 1;
        expect(this.list.pinned.length).toEqual(expectedLength);
        simulateClick(this.lis[0]);
        return expect(this.list.pinned.length).toEqual(originalLength);
      }, this));
    }, this));
    it('should cancel pending add request on remove', __bind(function() {
      var el, item;
      el = jQuery(this.lis[16]);
      this.list.add(16, el);
      expect(this.list.requests.add[16]).toBeDefined();
      item = this.list.pinned.findBy('id', 16);
      this.list.remove(item, el);
      return expect(this.list.requests.add[16]).toBeUndefined();
    }, this));
    it('should cancel pending remove request on add', __bind(function() {
      var el, item;
      el = jQuery(this.lis[1]);
      item = this.list.pinned.findBy('id', 1);
      this.list.remove(item, el);
      expect(this.list.requests.remove[1]).toBeDefined();
      this.list.add(1, el);
      return expect(this.list.requests.remove[1]).toBeUndefined();
    }, this));
    return it('should reset', __bind(function() {
      var originalLength;
      originalLength = this.list.targetList.children().length;
      runs(__bind(function() {
        return simulateClick(this.lis[0]);
      }, this));
      waits(251);
      return runs(__bind(function() {
        var button, length;
        button = jQuery('.customListRestore')[0];
        expect(this.list.requests.reset).toBeUndefined('request should not be defined yet');
        simulateClick(button);
        expect(this.list.requests.reset).toBeDefined('reset request should be defined');
        length = this.list.targetList.children().length;
        expect(length).toEqual(originalLength, 'targetList items restored');
        return jasmine.Fixtures.noCleanup = true;
      }, this));
    }, this));
  });
}).call(this);
