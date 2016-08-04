define([
  'i18n!react_files',
  'underscore',
  'react',
  'compiled/react_files/components/SearchResults',
  'jsx/files/NoResults',
  'jsx/files/ColumnHeaders',
  'compiled/models/Folder',
  'jsx/files/FolderChild',
  'jsx/files/LoadingIndicator',
  'jsx/files/FilePreview',
  'page',
  'compiled/react_files/modules/FocusStore'
], function(I18n, _, React, SearchResults, NoResults, ColumnHeaders, Folder, FolderChild, LoadingIndicator, FilePreview, Page, FocusStore) {

  SearchResults.displayErrors =  function (errors) {
    var error_message= null

    if (errors != null) {
      error_message = errors.map(function (error) {
        return (
          <li>
            {error.message}
          </li>
        )
      })
    }

    return (
      <div>
        <p>
          {I18n.t({one: 'Your search encountered the following error:', other: 'Your search encountered the following errors:'}, {count: errors.length}) }
        </p>
        <ul>
          { error_message }
        </ul>
      </div>
    );
  }

  SearchResults.closeFilePreview = function (url) {
    page(url);
    FocusStore.setFocusToItem();
  }

  SearchResults.renderFilePreview = function () {
    if (this.props.query.preview != null && this.state.collection.length) {
      return (
        /*
         * Prepare and render the FilePreview if needed.
         * As long as ?preview is present in the url.
         */
        <FilePreview
          isOpen={true}
          params={this.props.params}
          query={this.props.query}
          collection={this.state.collection}
          usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
          splat={this.props.splat}
          closePreview={this.closeFilePreview}
        />
      )
    }
  }

  SearchResults.render =  function () {
    if (this.state.errors) {
      return (this.displayErrors(this.state.errors))
    } else if (this.state.collection.loadedAll && (this.state.collection.length == 0)) {
      return (<NoResults search_term={this.props.query.search_term } />)
    } else {
      return (
        <div role='grid'>
          <div ref='accessibilityMessage' className='SearchResults__accessbilityMessage col-xs' tabIndex='0'>
            {I18n.t("Warning: For improved accessibility in moving files, please use the Move To Dialog option found in the menu.")}
          </div>
          <ColumnHeaders
            to='search'
            query= {this.props.query}
            params={this.props.params}
            pathname={this.props.pathname}
            toggleAllSelected={this.props.toggleAllSelected}
            areAllItemsSelected={this.props.areAllItemsSelected}
            usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
          />
          {
            this.state.collection.models.sort(Folder.prototype.childrenSorter.bind(this.state.collection, this.props.query.sort, this.props.query.order)).map((child) => {
              return (
                <FolderChild
                  key={child.cid}
                  model={child}
                  isSelected={_.indexOf(this.props.selectedItems, child) >=0}
                  toggleSelected={this.props.toggleItemSelected.bind(null, child)}
                  userCanManageFilesForContext={this.props.userCanManageFilesForContext}
                  usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
                  externalToolsForContext={this.props.externalToolsForContext}
                  previewItem={this.props.previewItem.bind(null, child)}
                  dndOptions={this.props.dndOptions}
                  modalOptions={this.props.modalOptions}
                  clearSelectedItems={this.props.clearSelectedItems}
                  onMove={this.props.onMove}
                />
              )
            })
          }

          <LoadingIndicator isLoading={!this.state.collection.loadedAll} />

          { this.renderFilePreview() }

        </div>
      )
    }
  };

  return React.createClass(SearchResults);

});
