(function() {
  define(['compiled/util/objectCollection'], function(objectCollection) {
    module('objectCollection', {
      setup: function() {
        var arrayOfObjects;
        arrayOfObjects = [
          {
            id: 1,
            name: 'foo'
          }, {
            id: 2,
            name: 'bar'
          }, {
            id: 3,
            name: 'baz'
          }, {
            id: 4,
            name: 'quux'
          }
        ];
        return this.collection = objectCollection(arrayOfObjects);
      }
    });
    test('indexOf', function() {
      var index, needle;
      needle = this.collection[2];
      index = this.collection.indexOf(needle);
      return equal(index, 2, 'should find the correct index');
    });
    test('findBy', function() {
      var byId, byName;
      byId = this.collection.findBy('id', 1);
      equal(this.collection[0], byId, 'should find the first item by id');
      byName = this.collection.findBy('name', 'bar');
      return equal(this.collection[1], byName, 'should find the second item by name');
    });
    test('eraseBy', function() {
      var originalLength;
      originalLength = this.collection.length;
      equal(this.collection[0].id, 1, 'first item id should be 1');
      this.collection.eraseBy('id', 1);
      equal(this.collection.length, originalLength - 1, 'collection length should less by 1');
      return equal(this.collection[0].id, 2, 'first item id should be 2, since first is erased');
    });
    test('insert', function() {
      var corge, grault;
      corge = {
        id: 5,
        name: 'corge'
      };
      this.collection.insert(corge);
      equal(this.collection[0], corge, 'should insert at index 0 by default');
      grault = {
        id: 6,
        name: 'grault'
      };
      this.collection.insert(grault, 2);
      return equal(this.collection[2], grault, 'should insert at an arbitrary index');
    });
    test('erase', function() {
      var originalLength;
      originalLength = this.collection.length;
      this.collection.erase(this.collection[0]);
      equal(this.collection[0].name, 'bar', 'should erase first item by reference, second item becomes first');
      return equal(this.collection.length, originalLength - 1, 'should decrease length');
    });
    return test('sortBy', function() {
      this.collection.sortBy('name');
      equal(this.collection[0].name, 'bar');
      equal(this.collection[1].name, 'baz');
      equal(this.collection[2].name, 'foo');
      equal(this.collection[3].name, 'quux');
      this.collection.sortBy('id');
      equal(this.collection[0].id, 1);
      equal(this.collection[1].id, 2);
      equal(this.collection[2].id, 3);
      return equal(this.collection[3].id, 4);
    });
  });
}).call(this);
