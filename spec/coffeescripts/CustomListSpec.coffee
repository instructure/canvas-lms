describe "CustomList", ->

  beforeEach =>
    loadFixtures 'CustomList.html'
    items = []
    for index in [0..100]
      items.push
        id: index
        shortName: "Course #{index}"
        longName: "Course long #{index}"
        subtitle: "Enrolled as Teacher"
        href: "/courses/#{index}"

    @list = new CustomList '#customList', items,
      url: '/spec/javascripts/fixtures/ok.json'
      appendTarget: '#customList'

    @list.open()
    @lis = jQuery '.customListItem'

  afterEach =>
    @list.teardown()

  it 'should open and close', =>
    @list.close()
    expect(@list.wrapper).toBeHidden()
    @list.open()
    expect(@list.wrapper).toBeVisible()

  it 'should remove and add the first item', =>
    originalLength = @list.targetList.children().length

    runs =>
      simulateClick( @lis[0] )

      # this next click should get ignored beacuse the DOM is animating, if it's
      # not, the first test in the next "runs" block will fail.
      simulateClick( @lis[1] )

    # wait for the animation to complete, that's when the data gets updated
    waits @list.options.animationDuration + 1

    runs =>
      expectedLength = originalLength - 1
      expect(@list.pinned.length).toEqual(expectedLength)

      # click again to put it back
      simulateClick( @lis[0] )
      expect(@list.pinned.length).toEqual(originalLength)

  it 'should cancel pending add request on remove', =>

    # Add one that doesn't exist
    el = jQuery @lis[16]
    @list.add(16, el)
    expect(@list.requests.add[16]).toBeDefined();

    # then immediately remove it before the request has time to come back
    item = @list.pinned.findBy('id', 16)
    @list.remove(item, el)
    expect(@list.requests.add[16]).toBeUndefined();

  it 'should cancel pending remove request on add', =>
    el = jQuery @lis[1]
    item = @list.pinned.findBy('id', 1)
    @list.remove(item, el)
    expect(@list.requests.remove[1]).toBeDefined();

    @list.add(1, el)
    expect(@list.requests.remove[1]).toBeUndefined();

  it 'should reset', =>

    originalLength = @list.targetList.children().length

    runs =>
      simulateClick @lis[0]

    waits 251 #animation

    runs =>
      button = jQuery('.customListRestore')[0]
      expect(@list.requests.reset).toBeUndefined('request should not be defined yet')

      simulateClick button
      expect(@list.requests.reset).toBeDefined('reset request should be defined')

      length = @list.targetList.children().length
      expect(length).toEqual(originalLength, 'targetList items restored')
      jasmine.Fixtures.noCleanup = true
