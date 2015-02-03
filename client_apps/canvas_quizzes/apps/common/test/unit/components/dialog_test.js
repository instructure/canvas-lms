define(function(require) {
  var React = require('react');
  var Subject = require('jsx!components/dialog');

  describe('Components.Dialog', function() {
    var Contents = React.createClass({
      render: function() {
        return React.DOM.p({ children: 'Hello from Dialog!' });
      }
    });

    this.reactSuite({
      type: Subject
    });

    var getDialog = function() {
      return document.body.querySelector('.ui-dialog');
    };

    it('should render', function() {
      setProps({ content: Contents });

      expect(getDialog()).toBeTruthy();
      expect(getDialog().innerText).toMatch('Hello from Dialog!');
    });

    it('should pass properties through to the content', function() {
      setProps({ name: 'Ahmad' }).then(function() {
        expect(subject.state.content.props.name).toEqual('Ahmad');
      });
    });

    it('should not pass parent-specific props, like @className', function() {
      setProps({ className: 'test' }).then(function() {
        expect(subject.props.className).toEqual('test');
        expect(subject.state.content.props.className).toBeFalsy();
      });
    });

    it('should accept custom tagNames', function() {
      setProps({ tagName: 'button' });
      expect(subject.getDOMNode().tagName).toEqual('BUTTON');
    });

    describe('#open, #isOpen, #close', function() {
      it('should work', function() {
        setProps({ content: Contents });

        subject.open();
        expect(subject.isOpen()).toBe(true);
        expect(getDialog().style.display).toEqual('block');

        subject.close();
        expect(subject.isOpen()).toBe(false);
        expect(getDialog().style.display).toEqual('none');

        subject.open();
        expect(subject.isOpen()).toBe(true);
        expect(getDialog().style.display).toEqual('block');
      });
    });
  });
});