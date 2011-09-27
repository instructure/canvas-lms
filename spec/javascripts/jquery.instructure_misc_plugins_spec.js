(function() {
  describe("jquery.instructure_misc_plugins", function() {
    it('showIf', function() {
      loadFixtures("jquery.instructure_misc_plugins.html");
      $("#checkbox1").showIf(function() {
        return true;
      });
      expect($("#checkbox1").is(":visible")).toEqual(true);
      $("#checkbox1").showIf(function() {
        return false;
      });
      expect($("#checkbox1").is(":visible")).toEqual(false);
      $("#checkbox1").showIf(function() {
        return true;
      });
      expect($("#checkbox1").is(":visible")).toEqual(true);
      $("#checkbox1").showIf(false);
      expect($("#checkbox1").is(":visible")).toEqual(false);
      $("#checkbox1").showIf(true);
      expect($("#checkbox1").is(":visible")).toEqual(true);
      expect($("#checkbox1").showIf(function() {
        return true;
      })).toEqual($("#checkbox1"));
      expect($("#checkbox1").showIf(function() {
        return false;
      })).toEqual($("#checkbox1"));
      expect($("#checkbox1").showIf(true)).toEqual($("#checkbox1"));
      expect($("#checkbox1").showIf(false)).toEqual($("#checkbox1"));
      return $('#checkbox1').showIf(function() {
        expect(this.nodeType).toBeDefined();
        return expect(this.constructor).not.toBe(jQuery);
      });
    });
    return it('disableIf', function() {
      loadFixtures("jquery.instructure_misc_plugins.html");
      $("#checkbox1").disableIf(function() {
        return true;
      });
      expect($("#checkbox1").is(":disabled")).toEqual(true);
      $("#checkbox1").disableIf(function() {
        return false;
      });
      expect($("#checkbox1").is(":disabled")).toEqual(false);
      $("#checkbox1").disableIf(function() {
        return true;
      });
      expect($("#checkbox1").is(":disabled")).toEqual(true);
      $("#checkbox1").disableIf(false);
      expect($("#checkbox1").is(":disabled")).toEqual(false);
      $("#checkbox1").disableIf(true);
      expect($("#checkbox1").is(":disabled")).toEqual(true);
      expect($("#checkbox1").disableIf(function() {
        return true;
      })).toEqual($("#checkbox1"));
      expect($("#checkbox1").disableIf(function() {
        return false;
      })).toEqual($("#checkbox1"));
      expect($("#checkbox1").disableIf(true)).toEqual($("#checkbox1"));
      return expect($("#checkbox1").disableIf(false)).toEqual($("#checkbox1"));
    });
  });
}).call(this);
