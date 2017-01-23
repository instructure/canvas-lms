define((require) => {
  const Subject = require('jsx!views/charts/discrimination_index');
  const K = require('constants');

  describe('Views.Charts.DiscriminationIndex', function () {
    this.reactSuite({
      type: Subject
    });

    it('should render', () => {
      expect(subject.isMounted()).toEqual(true);
    });

    it('goes positive when the DI is above the threshold', () => {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD + 0.1
      });

      expect(find('.index').className).toMatch('positive');
    });

    it('shows a "+" sign when positive', () => {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD + 0.1
      });

      expect(find('.sign').innerText).toEqual('+');
    });

    it('goes negative when <= the threshold', () => {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD
      });

      expect(find('.index').className).toMatch('negative');
    });

    it('shows a "+" sign when below the threshold and above 0', () => {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD - 0.1
      });

      expect(find('.sign').innerText).toEqual('+');
    });

    it('shows a "-" sign when below 0', () => {
      setProps({
        discriminationIndex: -0.1
      });

      expect(find('.sign').innerText).toEqual('-');
    });
  });
});
