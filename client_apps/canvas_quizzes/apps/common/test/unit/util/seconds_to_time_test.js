define(function(require) {
  var secondsToTime = require('util/seconds_to_time');

  describe('Util.secondsToTime', function() {
    describe('#toReadableString', function() {
      var subject = secondsToTime.toReadableString;

      it('24 => 24 seconds', function() {
        expect(subject(24)).toEqual('24 seconds');
      });

      it('84 => one minute and 24 seconds', function() {
        expect(subject(84)).toEqual('1 minute and 24 seconds');
      });

      it('144 => 2 minutes and 24 seconds', function() {
        expect(subject(144)).toEqual('2 minutes and 24 seconds');
      });

      it('3684 => one hour and one minute', function() {
        expect(subject(3684)).toEqual('1 hour and 1 minute');
      });
    });
  });
});