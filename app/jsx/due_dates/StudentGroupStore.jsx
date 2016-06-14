define([
  'react',
  'underscore',
  'jsx/shared/helpers/createStore',
  'jquery',
  'compiled/str/splitAssetString',
  'compiled/fn/parseLinkHeader'
], (React, _, createStore, $, splitAssetString, parseLinkHeader) => {

  // -------------------
  //       About
  // -------------------

  // the student groups store is in charge of fetching groups
  // in a course - currently used on the assignment & discussion
  // edit pages when selection an assignemnt override's set in
  // the due date picker

  // -------------------
  //     Initialize
  // -------------------

  const initialStoreState = {
    groups: {},
    fetchComplete: false,
    selectedGroupSetId: null
  }

  let StudentGroupStore = createStore($.extend(true, {}, initialStoreState))

  // -------------------
  //      Fetching
  // -------------------

  StudentGroupStore.fetchGroupsForCourse = function(url){
    const courseId = splitAssetString(window.ENV.context_asset_string)[1]
    const getGroupsPath = url || "/api/v1/courses/"+courseId+"/groups"

    $.getJSON(getGroupsPath, {},
      this.fetchGroupsCallback.bind(this)
    )
  }

  StudentGroupStore.fetchGroupsCallback = function(data, status, xhr){
    const links = parseLinkHeader(xhr)
    const newGroups = data
    this.addGroups(newGroups)

    if (links.next) {
      this.fetchGroupsForCourse(links.next)
    } else {
      this.markFetchComplete()
    }
  }

  // -------------------
  //   Set & Get State
  // -------------------

  StudentGroupStore.getGroups = function(){
    return StudentGroupStore.getState().groups
  }

  StudentGroupStore.getSelectedGroupSetId = function(){
    return StudentGroupStore.getState().selectedGroupSetId
  }

  StudentGroupStore.addGroups = function(newlyFetchedGroups){
    const newGroupsHash = _.indexBy(newlyFetchedGroups, "id")
    const newGroupsState = _.extend(newGroupsHash, this.getState().groups)
    this.setState({
      groups: newGroupsState
    })
  }

  StudentGroupStore.setSelectedGroupSet = function(setId){
    this.setState({
      selectedGroupSetId: setId
    })
  }

  StudentGroupStore.setGroupSetIfNone = function(setId){
    if (!this.getSelectedGroupSetId()){
      this.setSelectedGroupSet(setId)
    }
  }

  StudentGroupStore.markFetchComplete = function(){
    this.setState({
      fetchComplete: true
    })
  }

  StudentGroupStore.fetchComplete = function(){
    return this.getState().fetchComplete
  }

  // -------------------
  //       Helpers
  // -------------------

  // test helper
  StudentGroupStore.reset = function(){
    this.setState($.extend(true, {}, initialStoreState))
  }

  StudentGroupStore.groupsFilteredForSelectedSet = function(){
    const groups = this.getState().groups
    const setId = this.getState().selectedGroupSetId
    return _.filter( groups, function(value, key) {
      return value.group_category_id === setId
    })
  }

  // -------------------

  return StudentGroupStore
});
