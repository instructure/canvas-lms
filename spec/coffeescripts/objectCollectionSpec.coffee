define ['compiled/util/objectCollection'], (objectCollection) ->

  QUnit.module 'objectCollection',
    setup: ->
      arrayOfObjects = [
        {id: 1, name: 'foo'}
        {id: 2, name: 'bar'}
        {id: 3, name: 'baz'}
        {id: 4, name: 'quux'}
      ]
      @collection = objectCollection arrayOfObjects

  test 'indexOf', ->
    needle = @collection[2]
    index = @collection.indexOf needle
    equal index, 2, 'should find the correct index'

  test 'findBy', ->
    byId = @collection.findBy 'id', 1
    equal @collection[0], byId, 'should find the first item by id'

    byName = @collection.findBy 'name', 'bar'
    equal @collection[1], byName, 'should find the second item by name'

  test 'eraseBy', ->
    originalLength = @collection.length
    equal @collection[0].id, 1, 'first item id should be 1'

    @collection.eraseBy 'id', 1

    equal @collection.length, originalLength - 1, 'collection length should less by 1'
    equal @collection[0].id, 2, 'first item id should be 2, since first is erased'

  test 'insert', ->
    corge = {id: 5, name: 'corge'}
    @collection.insert corge
    equal @collection[0], corge, 'should insert at index 0 by default'

    grault = {id: 6, name: 'grault'}
    @collection.insert grault, 2
    equal @collection[2], grault, 'should insert at an arbitrary index'


  test 'erase', ->
    originalLength = @collection.length
    @collection.erase @collection[0]
    equal @collection[0].name, 'bar', 'should erase first item by reference, second item becomes first'
    equal @collection.length, originalLength - 1, 'should decrease length'

  test 'sortBy', ->
    @collection.sortBy 'name'
    equal @collection[0].name, 'bar'
    equal @collection[1].name, 'baz'
    equal @collection[2].name, 'foo'
    equal @collection[3].name, 'quux'

    @collection.sortBy 'id'
    equal @collection[0].id, 1
    equal @collection[1].id, 2
    equal @collection[2].id, 3
    equal @collection[3].id, 4

    # case where length is zero
    @collection.length = 0
    ok @collection.sortBy 'id'

