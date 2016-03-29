module CustomWaitMethods
  ##
  # waits for JavaScript to evaluate, occasionally when you click an element
  # a bunch of JS needs to run, this basically puts the rest of your test later
  # in the JS thread
  def wait_for_js
    driver.execute_script <<-JS
      window.selenium_wait_for_js = false;
      setTimeout(function() { window.selenium_wait_for_js = true; });
    JS
    keep_trying_until { driver.execute_script('return window.selenium_wait_for_js') == true }
  end

  def wait_for_dom_ready
    driver.execute_async_script(<<-JS)
     var callback = arguments[arguments.length - 1];
     var pollForJqueryAndRequire = function(){
        if (window.jQuery && window.require && !window.requirejs.s.contexts._.defQueue.length) {
          jQuery(function(){
            setTimeout(callback, 1);
          });
        } else {
          setTimeout(pollForJqueryAndRequire, 1);
        }
      }
      pollForJqueryAndRequire();
    JS
  end

  def wait_for_ajax_requests(wait_start = 0)
    result = driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (window.wait_for_ajax_requests_hit_fallback) {
        callback(0);
      } else if (typeof($) == 'undefined') {
        callback(-1);
      } else {
        var fallbackCallback = window.setTimeout(function() {
          // technically, we should cancel the other timeouts that we've set up at this
          // point, but we're going to be raising an exception anyway when this happens,
          // so it's not a big deal.
          window.wait_for_ajax_requests_hit_fallback = 1;
          callback(-2);
        }, 55000);
        var doCallback = function(value) {
          window.clearTimeout(fallbackCallback);
          callback(value);
        }
        var waitForAjaxStop = function(value) {
          $(document).bind('ajaxStop.canvasTestAjaxWait', function() {
            $(document).unbind('.canvasTestAjaxWait');
            doCallback(value);
          });
        }
        if ($.active == 0) {
          // if there are no active requests, wait {wait_start}ms for one to start
          var timeout = window.setTimeout(function() {
            $(document).unbind('.canvasTestAjaxWait');
            doCallback(0);
          }, #{wait_start});
          $(document).bind('ajaxStart.canvasTestAjaxWait', function() {
            window.clearTimeout(timeout);
            waitForAjaxStop(2);
          });
        } else {
          waitForAjaxStop(1);
        }
      }
    JS
    if result == -2
      raise "Timed out waiting for ajax requests to finish. (This might mean there was a js error in an ajax callback.)"
    end
    wait_for_js
    result
  end

  def wait_for_animations(wait_start = 0)
    driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (typeof($) == 'undefined') {
        callback(-1);
      } else {
        var waitForAnimateStop = function(value) {
          var _stop = $.fx.stop;
          $.fx.stop = function() {
            $.fx.stop = _stop;
            _stop.apply(this, arguments);
            callback(value);
          }
        }
        if ($.timers.length == 0) {
          var _tick = $.fx.tick;
          // wait {wait_start}ms for an animation to start
          var timeout = window.setTimeout(function() {
            $.fx.tick = _tick;
            callback(0);
          }, #{wait_start});
          $.fx.tick = function() {
            window.clearTimeout(timeout);
            $.fx.tick = _tick;
            waitForAnimateStop(2);
            _tick.apply(this, arguments);
          }
        } else {
          waitForAnimateStop(1);
        }
      }
    JS
    wait_for_js
  end

  def wait_for_ajaximations(wait_start = 0)
    wait_for_ajax_requests(wait_start)
    wait_for_animations(wait_start)
  end

  def keep_trying_until(seconds = SECONDS_UNTIL_GIVING_UP)
    val = false
    seconds.times do |i|
      puts "trying #{seconds - i}" if i > SECONDS_UNTIL_COUNTDOWN
      val = false
      begin
        val = yield
        break if val
      rescue StandardError, RSpec::Expectations::ExpectationNotMetError
        raise if i == seconds - 1
      end
      sleep 1
    end
    raise "Unexpected #{val.inspect}" unless val
    val
  end

  # pass in an Element pointing to the textarea that is tinified.
  def wait_for_tiny(element)
    # TODO: Better to wait for an event from tiny?
    parent = element.find_element(:xpath, '..')
    tiny_frame = nil
    keep_trying_until {
      begin
        tiny_frame = parent.find_element(:css, 'iframe')
      rescue => e
        puts "#{e.inspect}"
        false
      end
    }
    tiny_frame
  end
end