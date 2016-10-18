define([
  'reflux',
  'jquery',
  'jsx/gradebook/grid/constants'
], function (Reflux, $, GradebookConstants) {
  var SectionsActions = Reflux.createActions({
    load: {asyncResult: true},
    selectSection: {asyncResult: false}
  })

  SectionsActions.load.listen(function() {
    var url, self;

    self = this;
    url = GradebookConstants.sections_url;

    $.getJSON(url)
      .then(this.completed)
      .fail((jqxhr, textStatus, error) => self.failed(error));
  });

  return SectionsActions;
});
