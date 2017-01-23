define((require) => {
  const React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  const Subject = require('jsx!components/dialog');

  describe('Components.Dialog', function () {
    const Contents = React.createClass({
      render () {
        return React.DOM.p({ children: 'Hello from Dialog!' });
      }
    });

    this.reactSuite({
      type: Subject
    });

    const getDialog = function () {
      return document.body.querySelector('.ui-dialog');
    };

    it('should render', () => {
      setProps({ content: Contents });

      expect(getDialog()).toBeTruthy();
      expect(getDialog().innerText).toMatch('Hello from Dialog!');
    });

    it('should pass properties through to the content', () => {
      setProps({ name: 'Ahmad' }).then(() => {
        expect(subject.state.content.props.name).toEqual('Ahmad');
      });
    });

    it('should not pass parent-specific props, like @className', () => {
      setProps({ className: 'test' }).then(() => {
        expect(subject.props.className).toEqual('test');
        expect(subject.state.content.props.className).toBeFalsy();
      });
    });

    it('should accept custom tagNames', () => {
      setProps({ tagName: 'button' });
      expect(subject.getDOMNode().tagName).toEqual('BUTTON');
    });

    describe('#open, #isOpen, #close', () => {
      it('should work', () => {
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
