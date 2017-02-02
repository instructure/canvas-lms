import React from 'react'
import I18n from 'i18n!flickr_search'
import FlickrActions from './actions/FlickrActions'
import FlickrStore from './stores/FlickrStore'
import FlickrImage from './FlickrImage'
import SVGWrapper from './SVGWrapper'
import Spinner from 'instructure-ui/Spinner'

  class FlickrSearch extends React.Component {

    constructor () {
      super();

      this.handleChange = this.handleChange.bind(this);
      this.handleInput = this.handleInput.bind(this);
      this.incrementPageCount = this.incrementPageCount.bind(this);
      this.decrementPageCount = this.decrementPageCount.bind(this);
    }

    componentWillMount() {
      this.state = FlickrStore.getState();
      this.unsubscribe = FlickrStore.subscribe(this.handleChange);
    }

    componentWillUnmount() {
      this.unsubscribe();
    }

    handleChange() {
      this.setState(FlickrStore.getState());
    }

    handleInput (event) {
      event.preventDefault();
      var value = event.target.value;

      if (value === '') {
        this.clearFlickrResults();
      }
      else {
        this.searchFlickr(value, 1);
      }
    }

    searchFlickr (value, page) {
      FlickrStore.dispatch(FlickrActions.searchFlickr(value, page));
    }

    clearFlickrResults () {
      FlickrStore.dispatch(FlickrActions.clearFlickrSearch());
    }

    incrementPageCount () {
      this.searchFlickr(this.state.searchTerm, this.state.page + 1);
    }

    decrementPageCount() {
      this.searchFlickr(this.state.searchTerm, this.state.page - 1);
    }

    render () {
      var photos = this.state.searchResults.photos;

      return (
        <div>
          <div className="FlickrSearch__logo">
            <SVGWrapper url="/images/flickr_logo.svg" />
          </div>
          <div className="ic-Input-group">
            <div className="ic-Input-group__add-on" role="presentation" aria-hidden="true" tabIndex="-1">
              <i className="icon-search"></i>
            </div>
            <input className="ic-Input"
                   placeholder={I18n.t('Search flickr')}
                   aria-label="Search widgets"
                   value={this.state.searchTerm}
                   type="search"
                   onChange={this.handleInput} />
          </div>

          {!this.state.searching ?
            <div className="FlickrSearch__images">
              {photos ? photos.photo.map( (photo) => {
                return <FlickrImage key={photo.id}
                                    url={photo.url_m}
                                    searchTerm={this.state.searchTerm}
                                    selectImage={this.props.selectImage} />
              }) : null }
            </div>
            :
            <div className="FlickrSearch__loading">
              <Spinner title="Loading"/>
            </div>
          }

          {photos ?
            <span className="FlickrSearch__pageNavigation">
              {(this.state.page > 1 && !this.state.searching) ?
                <a className="FlickrSearch__control" ref="flickrSearchControlPrev" href="#" onClick={this.decrementPageCount}>
                  <i className="icon-arrow-open-left"/> {I18n.t('Previous')}
                </a>
                :
                null
              }
              {(this.state.page < photos.pages && !this.state.searching) ?
                <a className="FlickrSearch__control" ref="flickrSearchControlNext" href="#" onClick={this.incrementPageCount}>
                  {I18n.t('Next')} <i className="icon-arrow-open-right"/>
                </a>
                :
                null
              }
            </span>
            :
            null
          }
        </div>
      );
    }
  }

export default FlickrSearch
