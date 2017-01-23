# encoding: utf-8

require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

describe 'ruby_version_compat' do
  # from minitest, MIT licensed
  def capture_io
    orig_stdout, orig_stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    yield
    return $stdout.string, $stderr.string
  ensure
    $stdout, $stderr = orig_stdout, orig_stderr
  end

  describe 'backport of ruby #7278' do
    it "should not output to stdout/stderr" do
      output = capture_io do
        # this file is marked utf-8 for one of the specs below, so we need to force these string literals to be binary
        sio = StringIO.new("".force_encoding('binary'))
        imio = Net::InternetMessageIO.new(sio)
        expect(imio.write_message("\u3042\r\u3044\n\u3046\r\n\u3048")).to eq 23
        expect(sio.string.force_encoding('binary')).to eq "\u3042\r\n\u3044\r\n\u3046\r\n\u3048\r\n.\r\n".force_encoding('binary')

        sio = StringIO.new("".force_encoding('binary'))
        imio = Net::InternetMessageIO.new(sio)
        expect(imio.write_message("\u3042\r")).to eq 8
        expect(sio.string.force_encoding('binary')).to eq "\u3042\r\n.\r\n".force_encoding('binary')
      end

      expect(output).to eq ['', '']
    end
  end

  describe "force_utf8_params" do
    it "should allow null filenames through" do
      testfile = fixture_file_upload("scribd_docs/txt.txt", "text/plain", true)
      testfile.instance_variable_set(:@original_filename, nil)
      controller = ApplicationController.new
      controller.stubs(:params).returns({ :upload => { :file1 => testfile } })
      controller.stubs(:request).returns(mock(:path => "/upload"))
      expect { controller.force_utf8_params() }.to_not raise_error
      expect(testfile.original_filename).to be_nil
    end
  end

  describe "ERB::Util.html_escape" do
    it "should be silent and escape properly with the regexp utf-8 monkey patch" do
      stdout, stderr = capture_io do
        escaped = ERB::Util.html_escape("åß∂åß∂<>")
        expect(escaped.encoding).to eq Encoding::UTF_8
        expect(escaped).to eq "åß∂åß∂&lt;&gt;"
      end
      expect(stdout).to eq ''
      expect(stderr).to eq ''
    end
  end

  describe "ActiveSupport::Inflector#transliterate" do
    it "should be silent and return equivalent strings" do
      stdout, stderr = capture_io do
        expect(ActiveSupport::Inflector.transliterate("a string")).to eq "a string"
        complex = ERB::Util.html_escape("test ßå")
        expect(ActiveSupport::Inflector.transliterate(complex)).to eq "test ssa"
      end
      expect(stdout).to eq ''
      expect(stderr).to eq ''
    end
  end
end
