define([
  'react',
  'enzyme',
  'jsx/gradezilla/default_gradebook/components/ViewOptionsMenu'
], (React, { mount }, ViewOptionsMenu) => {
  module('ViewOptionsMenu', {
    setup () {
      this.wrapper = mount(<ViewOptionsMenu />);
    },

    teardown () {
      this.wrapper.unmount();
    }
  });

  test('it renders', function () {
    ok(this.wrapper.component.isMounted());
  });
});
