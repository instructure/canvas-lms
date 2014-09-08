require 'spec_helper'

module I18nTasks
  module I18n
    describe Utils do
      describe '#extract_amd_scripts' do
        def subject(*args)
          Utils.extract_amd_scripts(*args)
        end

        it 'should return AMD module texts within a block' do
          scripts = subject <<-FILE
            define('foo', function() {});
            define('x', function() {
              return 5;
            });
            define('y', [ 'x' ], function(X) {
              return X + 5;
            });
            // lololl
            define("xyz", function(require) {
              var x = require('x');
              var y = require('y');
            });
          FILE

          scripts.size.should == 4
          scripts[0].should == "define('foo', function() {});"

          scripts[1].should == (<<-SCRIPT
            define('x', function() {
              return 5;
            });
          SCRIPT
          ).strip

          scripts[2].should == (<<-SCRIPT
            define('y', [ 'x' ], function(X) {
              return X + 5;
            });
            // lololl
          SCRIPT
          ).strip

          scripts[3].should == (<<-SCRIPT
            define("xyz", function(require) {
              var x = require('x');
              var y = require('y');
            });
          SCRIPT
          ).strip
        end

        it 'shouldnt break with no scripts' do
          lambda { subject('') }.should_not raise_error
        end

        it 'should work with anonymous modules' do
          scripts = subject <<-FILE
            define(function(require) {
              var I18n = require('i18n!foo');
            });
          FILE

          scripts.size.should == 1
          scripts[0].should == (<<-SCRIPT
            define(function(require) {
              var I18n = require('i18n!foo');
            });
          SCRIPT
          ).strip
        end
      end
    end
  end
end