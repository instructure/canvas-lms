module Multipart
  class Post
    BOUNDARY = CanvasUuid::Uuid.generate('canvas-rules', 15)
    HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY}

    def prepare_query (params, field_priority=[])
      fp = []
      creds = params.delete :basic_auth
      if creds
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
          Param.new(k, v)
        end
      end

      completed_fields = {}
      field_priority.each do |k|
        if params.has_key?(k) && !completed_fields.has_key?(k)
          fp.push(file_param(k, params[k]))
          completed_fields[k] = true
        end
      end
      params.each { |k, v| fp.push(file_param(k, v)) unless completed_fields.has_key?(k) }
      query = fp.collect { |p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
      return query, HEADER
    end
  end
end
