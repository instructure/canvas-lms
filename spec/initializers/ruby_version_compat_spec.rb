# encoding: utf-8

require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

describe 'ruby_version_compat' do
  describe 'backport of ruby #7278' do
    it "should not output to stdout/stderr" do
      pending("ruby 1.9+ only") if RUBY_VERSION < "1.9."

      output = capture_io do
        # this file is marked utf-8 for one of the specs below, so we need to force these string literals to be binary
        sio = StringIO.new("".force_encoding('binary'))
        imio = Net::InternetMessageIO.new(sio)
        imio.write_message("\u3042\r\u3044\n\u3046\r\n\u3048").should == 23
        sio.string.should == "\u3042\r\n\u3044\r\n\u3046\r\n\u3048\r\n.\r\n".force_encoding('binary')

        sio = StringIO.new("".force_encoding('binary'))
        imio = Net::InternetMessageIO.new(sio)
        imio.write_message("\u3042\r").should == 8
        sio.string.should == "\u3042\r\n.\r\n".force_encoding('binary')
      end

      output.should == ['', '']
    end
  end

  describe "force_utf8_params" do
    it "should allow null filenames through" do
      pending("ruby 1.9 only") if RUBY_VERSION < "1.9"
      testfile = ActionController::TestUploadedFile.new(File.join(File.dirname(__FILE__), "/../fixtures/scribd_docs/txt.txt"), "text/plain", true)
      testfile.instance_variable_set(:@original_filename, nil)
      controller = ApplicationController.new
      controller.stubs(:params).returns({ :upload => { :file1 => testfile } })
      controller.stubs(:request).returns(mock(:path => "/upload"))
      expect { controller.force_utf8_params() }.to_not raise_error
      testfile.original_filename.should be_nil
    end
  end

  describe "ERB::Util.html_escape" do
    it "should be silent and escape properly with the regexp utf-8 monkey patch" do
      pending("ruby 1.9+ only") if RUBY_VERSION < "1.9."

      stdout, stderr = capture_io do
        escaped = ERB::Util.html_escape("åß∂åß∂<>")
        escaped.encoding.should == Encoding::UTF_8
        escaped.should == "åß∂åß∂&lt;&gt;"
      end
      stdout.should == ''
      stderr.should == ''
    end
  end

  describe "ActiveSupport::Inflector#transliterate" do
    it "should be silent and return equivalent strings" do
      pending("ruby 1.9+ only") if RUBY_VERSION < "1.9."
      stdout, stderr = capture_io do
        ActiveSupport::Inflector.transliterate("a string").should == "a string"
        complex = ERB::Util.html_escape("test ßå")
        ActiveSupport::Inflector.transliterate(complex).should == "test ssa"
      end
      stdout.should == ''
      stderr.should == ''
    end
  end
end
