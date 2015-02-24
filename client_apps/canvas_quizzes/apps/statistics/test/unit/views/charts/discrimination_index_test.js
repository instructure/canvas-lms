define(function(require) {
  var Subject = require('jsx!views/charts/discrimination_index');
  var K = require('constants');

  describe('Views.Charts.DiscriminationIndex', function() {
    this.reactSuite({
      type: Subject
    });

    it('should render', function() {
      expect(subject.isMounted()).toEqual(true);
    });

    it('goes positive when the DI is above the threshold', function() {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD + 0.1
      });

      expect(find('.index').className).toMatch('positive');
    });

    it('shows a "+" sign when positive', function() {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD + 0.1
      });

      expect(find('.sign').innerText).toEqual('+');
    });

    it('goes negative when <= the threshold', function() {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD
      });

      expect(find('.index').className).toMatch('negative');
    });

    it('shows a "+" sign when below the threshold and above 0', function() {
      setProps({
        discriminationIndex: K.DISCRIMINATION_INDEX_THRESHOLD - 0.1
      });

      expect(find('.sign').innerText).toEqual('+');
    });

    it('shows a "-" sign when below 0', function(){
      setProps({
        discriminationIndex: -0.1
      });

      expect(find('.sign').innerText).toEqual('-');
    });

    describe('chart', function() {
      beforeEach(function() {
        setProps({
          width: 270,
          height: 14 * 3,
          topStudentCount: 4,
          middleStudentCount: 2,
          bottomStudentCount: 2,
          correctBottomStudentCount: 1,
          correctMiddleStudentCount: 2,
          correctTopStudentCount: 1,
        });
      });

      it('renders the chart', function() {
        expect(find('svg.chart')).toBeTruthy();
      });

      it('renders two bars, .correct and .incorrect, for each student bracket', function() {
        expect(findAll('svg rect').length).toEqual(6);
        expect(findAll('svg rect.correct').length).toEqual(3);
        expect(findAll('svg rect.incorrect').length).toEqual(3);
      });

      it('positions the bars correctly', function() {
        [
          { coords: [ 135, 0 ], width: 33.75 }, // top correct
          { coords: [ 135, 14 ], width: 135 }, // middle correct
          { coords: [ 135, 28 ], width: 67.5 }, // bottom correct

          { coords: [ 32.75, 0 ], width: 101.25 }, // top incorrect
          { coords: [ 134, 14 ], width: 0 }, // middle incorrect
          { coords: [ 66.5, 28 ], width: 67.5 }, // bottom incorrect
        ].forEach(function(expected, index) {
          var rect = find('rect:nth-of-type(' + (index+1) + ')');

          expect(rect.x.baseVal.value).toEqual(expected.coords[0], 'rect[' + index + '][x]');
          expect(rect.y.baseVal.value).toEqual(expected.coords[1], 'rect[' + index + '][y]');
          expect(rect.width.baseVal.value).toEqual(expected.width, 'rect[' + index + '][w]');
        });
      });
    });
  });
});