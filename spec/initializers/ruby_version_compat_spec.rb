require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

describe 'ruby_version_compat' do
  describe 'backport of ruby #7278' do
    it "should not output to stdout/stderr" do
      pending("ruby 1.9+ only") if RUBY_VERSION < "1.9."

      output = capture_io do
        sio = StringIO.new("")
        imio = Net::InternetMessageIO.new(sio)
        imio.write_message("\u3042\r\u3044\n\u3046\r\n\u3048").should == 23
        sio.string.should == "\u3042\r\n\u3044\r\n\u3046\r\n\u3048\r\n.\r\n".force_encoding('us-ascii')

        sio = StringIO.new("")
        imio = Net::InternetMessageIO.new(sio)
        imio.write_message("\u3042\r").should == 8
        sio.string.should == "\u3042\r\n.\r\n".force_encoding('us-ascii')
      end

      output.should == ['', '']
    end
  end
end
