if CANVAS_RAILS2
  require File.expand_path('../spec_helper', File.dirname( __FILE__ ))

  describe "parse_multipart" do
    it "should not treat multipart params with content-type but no filename as files" do
      message = <<-MESSAGE.strip.gsub("\n", "\r\n")
--lolwut
Content-Disposition: form-data; name="not-a-file"
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: 8bit

this isn't a file
--lolwut
Content-Disposition: form-data; name="file"; filename="filename.frd"
Content-Type: application/octet-stream
Content-Transfer-Encoding: 8bit

this one really is a file
--lolwut--
      MESSAGE
      env = { 'CONTENT_TYPE' => 'multipart/form-data; boundary=lolwut',
              'CONTENT_LENGTH' => message.size,
              'rack.input' => StringIO.new(message)
      }

      params = Rack::Utils::Multipart.parse_multipart(env)
      params["not-a-file"].should eql "this isn't a file"
      params["file"][:filename].should eql "filename.frd"
      params["file"][:tempfile].read.should eql "this one really is a file"
    end

    it "should not explode with a non-ASCII file attachment" do
      request_file = File.open( File.expand_path('../fixtures/multipart-request', File.dirname(__FILE__)) )
      env = { 'CONTENT_TYPE' => 'multipart/form-data; boundary=----WebKitFormBoundary2raDSu0SsqTAphBU',
              'CONTENT_LENGTH' => request_file.size,
              'rack.input' => request_file
      }
      lambda { Rack::Utils::Multipart.parse_multipart(env) }.should_not raise_error
    end
  end
end
