module SFU

  module REST
    extend self

    def canvas_server
      "http://localhost"
    end

    def rest_server
      "https://rest.its.sfu.ca/cgi-bin/WebObjects/AOBRestServer.woa"
    end

    def account_url
       "#{rest_server}/rest/datastore2/global/accountInfo.js"
    end

    def terms_url
      "#{rest_server}/rest/crr/terms.js"
    end

    def courses_url
      "#{rest_server}/rest/crr/resource2.js"
    end

    def course_info_url
      "#{rest_server}/rest/course/course.js"
    end

    def maillist_membership_url
      "#{rest_server}/rest/maillist/members.js"
    end

    def canvas_sis_import_url
      account_id = Account.find_by_name("Simon Fraser University").id
      "#{canvas_server}/api/v1/accounts/#{account_id}/sis_imports.json?extension=csv"
    end

    def text(url, params)
      rest_url = "#{url}?art=#{sfu_rest_token}#{params}"
      RestClient.get rest_url
    end

    def json(url, params)
      rest_url = "#{url}?art=#{sfu_rest_token}#{params}"
      begin
        json_out = RestClient.get rest_url
        JSON.parse json_out
      rescue Exception => e
        case e.message
          when /404/ then 404
          when /500/ then 500
        end

        # If REST server app is unavailable, its webserver returns a 404. Therefore, should be returning a 500 instead
        if e.to_s.eql? "404 Resource Not Found: <html><body><strong>The requested application was not found on this server.</strong></body></html>\n"
          500
        end
      end
    end

    def sfu_rest_token
      token = YAML.load_file Pathname(RAILS_ROOT) + "config/sfu.yml"
      token["sfu_rest_token"]
    end

    def canvas_oauth_token
      token = YAML.load_file Pathname(RAILS_ROOT) + "config/sfu.yml"
      token["canvas_oauth_token"]
    end
  end

end
