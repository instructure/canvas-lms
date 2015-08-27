/** @jsx React.DOM */

define(['axios'], function(axios){
  class ModerationActions {
    constructor (store) {
      this.store = store;
    }

    updateSubmission (submission) {
      // Update the submission and then update the store
    }

    loadInitialSubmissions (submissions_url) {
      axios.get(submissions_url)
           .then(function(response){
             this.store.addSubmissions(response.data);
           }.bind(this))
           .catch(function(response){
             console.log('finished');
           })
    }
  }

  return ModerationActions;
});
