(function() {
  var Slide, Slideshow;
  Slide = (function() {
    function Slide(title, slideshow) {
      var slide, _ref;
      this.title = title;
      this.slideshow = slideshow;
      this.body = $('<li/>').addClass('slide');
      this.slideshow.slides.append(this.body);
      this.prevSlide = this.slideshow.slideObjects[this.slideshow.slideObjects.length - 1];
      if ((_ref = this.prevSlide) != null) {
        _ref.nextSlide = this;
      }
      this.nextSlide = null;
      this.indicator = $("<a/>").addClass('slide').attr('href', '#').attr('title', $.h(this.title)).html('&nbsp;');
      this.indicator.data('slide', this);
      this.slideshow.navigation.append(this.indicator);
      slide = this;
      this.indicator.click(function() {
        slideshow.showSlide(slide);
        return false;
      });
      this.hide();
    }
    Slide.prototype.addParagraph = function(text, klass) {
      var paragraph;
      paragraph = $("<p/>");
      if (klass != null) {
        paragraph.addClass(klass);
      }
      paragraph.html($.h(text));
      return this.body.append(paragraph);
    };
    Slide.prototype.addImage = function(src, klass, url) {
      var image, link;
      image = $("<img/>").attr('src', src);
      if (klass != null) {
        image.addClass(klass);
      }
      if (url) {
        link = $("<a/>").attr('href', url).attr('target', '_blank');
        link.append(image);
        return this.body.append(link);
      } else {
        return this.body.append(image);
      }
    };
    Slide.prototype.show = function() {
      this.body.show();
      return this.indicator.addClass('current_slide');
    };
    Slide.prototype.hide = function() {
      this.indicator.removeClass('current_slide');
      return this.body.hide();
    };
    return Slide;
  })();
  Slideshow = (function() {
    function Slideshow(id) {
      var slideshow;
      slideshow = this;
      this.dom = $('<div/>').attr('id', id);
      this.slides = $('<ul/>').addClass('slides');
      this.dom.append(this.slides);
      this.separator = $("<div/>").addClass('separator');
      this.dom.append(this.separator);
      this.navigation = $("<div/>").addClass('navigation');
      this.dom.append(this.navigation);
      this.backButton = $("<a/>").addClass('back').attr('href', '#').attr('title', $.h(I18n.t('titles.back', 'Back'))).html('&nbsp;');
      this.navigation.append(this.backButton);
      this.backButton.click(function() {
        slideshow.showPrevSlide();
        return false;
      });
      this.forwardButton = $("<a/>").addClass('forward').attr('href', '#').attr('title', $.h(I18n.t('titles.forward', 'Forward'))).html('&nbsp;');
      this.navigation.append(this.forwardButton);
      this.forwardButton.click(function() {
        slideshow.showNextSlide();
        return false;
      });
      this.closeButton = $("<a/>").addClass('close').attr('href', '#').attr('title', $.h(I18n.t('titles.close', 'Close'))).html('&nbsp;');
      this.navigation.append(this.closeButton);
      this.closeButton.click(function() {
        slideshow.close();
        return false;
      });
      this.slideObjects = [];
      this.slideShown = null;
    }
    Slideshow.prototype.addSlide = function(name, callback) {
      var slide;
      slide = new Slide(name, this);
      this.slideObjects.push(slide);
      return callback(slide);
    };
    Slideshow.prototype.start = function() {
      this.showSlide(this.slideObjects[0]);
      return this.dialog = this.dom.dialog({
        dialogClass: 'slideshow_dialog',
        height: 529,
        width: 700,
        modal: true,
        draggable: false,
        resizable: false
      });
    };
    Slideshow.prototype.showSlide = function(slide) {
      var _ref;
      if (slide) {
        if (!(this.slideShown && slide === this.slideShown)) {
          if ((_ref = this.slideShown) != null) {
            _ref.hide();
          }
          this.slideShown = slide;
          this.slideShown.show();
        }
        if (this.slideShown.prevSlide) {
          this.backButton.removeClass('inactive');
        } else {
          this.backButton.addClass('inactive');
        }
        if (this.slideShown.nextSlide) {
          return this.forwardButton.removeClass('inactive');
        } else {
          return this.forwardButton.addClass('inactive');
        }
      }
    };
    Slideshow.prototype.showPrevSlide = function() {
      var _ref;
      return this.showSlide((_ref = this.slideShown) != null ? _ref.prevSlide : void 0);
    };
    Slideshow.prototype.showNextSlide = function() {
      var _ref;
      return this.showSlide((_ref = this.slideShown) != null ? _ref.nextSlide : void 0);
    };
    Slideshow.prototype.close = function() {
      var _ref;
      this.dom.dialog('close');
      this.dom.hide();
      if ((_ref = this.slideShown) != null) {
        _ref.hide();
      }
      return this.slideShown = null;
    };
    return Slideshow;
  })();
  window.Slideshow = Slideshow;
}).call(this);
