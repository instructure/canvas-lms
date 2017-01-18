define([
  'react',
  'jsx/epub_exports/CourseStore',
  'jsx/epub_exports/CourseList'
], function(React, CourseStore, CourseList){

  var EpubExportApp = React.createClass({
    displayName: 'EpubExportApp',

    //
    // Preparation
    //

    getInitialState: function() {
      return CourseStore.getState();
    },
    handleCourseStoreChange () {
      this.setState(CourseStore.getState());
    },

    //
    // Lifecycle
    //

    componentDidMount () {
      CourseStore.addChangeListener(this.handleCourseStoreChange);
      CourseStore.getAll();
    },
    componentWillUnmount () {
      CourseStore.removeChangeListener(this.handleCourseStoreChange);
    },

    //
    // Rendering
    //

    render() {
      return (
        <CourseList courses={this.state} />
      );
    }
  });

  return EpubExportApp;
});
