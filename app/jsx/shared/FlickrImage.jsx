define([
  'react'
], (React) => {

  class FlickrImage extends React.Component {
    constructor (props) {
      super(props);

      this.handleClick = this.handleClick.bind(this);
    }

    handleClick (event) {
      this.props.selectImage(this.props.url);
    }

    render () {

      const imageStyle = {
        backgroundImage: `url(${this.props.url})`
      };

      return (
        <a className="FlickrImage"
           onClick={this.handleClick}
           href="javascript:;"
           ref="flickrImage">
          <img className="FlickrImage__screenreader"
               alt={this.props.searchTerm}
               src={this.props.url}>
          </img>
          <div className="FlickrImage__display"
               style={imageStyle}>
          </div>
        </a>
      );
    }
  }

  return FlickrImage;

});