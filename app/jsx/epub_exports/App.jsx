import React from 'react'
import CourseStore from 'jsx/epub_exports/CourseStore'
import CourseList from 'jsx/epub_exports/CourseList'

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

export default EpubExportApp
