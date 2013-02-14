module Multipart
  # From: http://deftcode.com/code/flickr_upload/multipartpost.rb
  ## Helper class to prepare an HTTP POST request with a file upload
  ## Mostly taken from
  #http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/113774
  ### WAS:
  ## Anything that's broken and wrong probably the fault of Bill Stilwell
  ##(bill@marginalia.org)
  ### NOW:
  ## Everything wrong is due to keith@oreilly.com
  require 'rubygems'
  require 'mime/types'
  require 'net/http'
  require 'cgi'

  class Param
    attr_accessor :k, :v
    def initialize( k, v )
      @k = k
      @v = v
    end

    def to_multipart
      #return "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"\r\n\r\n#{v}\r\n"
      # Don't escape mine...
      return "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
    end
  end

  class FileParam
    attr_accessor :k, :filename, :content
    def initialize( k, filename, content )
      @k = k
      @filename = filename || "file.csv"
      @content = content
    end

    def to_multipart
      #return "Content-Disposition: form-data; name=\"#{CGI::escape(k)}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n "
      # Don't escape mine
      return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" + "Content-Transfer-Encoding: binary\r\n" + "Content-Type: #{MIME::Types.type_for(@filename).first}\r\n\r\n" + content + "\r\n"
    end
  end
  class MultipartPost
    BOUNDARY = AutoHandle.generate('canvas-rules', 15)
    HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY}

    def prepare_query (params, field_priority=[])
      fp = []
      creds = params.delete :basic_auth
      if creds
        require 'base64'
        puts creds[:username]
        puts creds[:password]
        puts Base64.encode64("#{creds[:username]}:#{creds[:password]}")
      end
      def file_param(k, v)
        file_data = v.read rescue nil
        if file_data
          file_path = (v.respond_to?(:path) && v.path) || k.to_s
          FileParam.new(k, file_path, file_data)
        else
          Param.new(k,v)
        end
      end
      completed_fields = {}
      field_priority.each do |k|
        if params.has_key?(k) && !completed_fields.has_key?(k)
          fp.push(file_param(k, params[k]))
          completed_fields[k] = true
        end
      end
      params.each {|k,v| fp.push(file_param(k, v)) unless completed_fields.has_key?(k) }
      query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
      return query, HEADER
    end
  end  
end
