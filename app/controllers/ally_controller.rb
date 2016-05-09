class AllyController < ApplicationController

  #
  # REST methods
  #

  ##
  # Returns whether the plugin is enabled for the account. If its
  # enabled extra information such as the client ID and base URL
  # of the Ally API is returned as well
  def enabled
    plugin_data = get_plugin_data
    data = {
      :enabled => plugin_data[:enabled],
      :clientId => plugin_data[:client_id],
      :baseUrl => plugin_data[:base_url]
    }
    render :json => data
  end

  ##
  # Sign a request to the Ally REST API but don't execute it.
  # The UI will execute the request
  def sign
    if (request = get_request())
      plugin_data = get_plugin_data()
      puts request.to_yaml
      data = {
        :clientId => plugin_data[:client_id],
        :baseUrl => plugin_data[:base_url],
        :path => request.path,
        :header => request.to_hash["authorization"][0],
        :body => request.body,
      }
      render :json => data
    end
  end

  ##
  # Proxy data from the Ally REST API
  def proxy
    if (request = get_request())
      # TODO: Cache the HTTP object per hostname allowing
      # for connection pooling
      plugin_data = get_plugin_data()
      uri = URI.parse(plugin_data[:base_url])
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(request)

      # Render successful requests as JSON
      if response.code == 200 || response.code == 201
        render :json => response.body, :status => response.code
      else
        render :text => response.body, :status => response.code
      end
    end
  end

  protected

  # Caches HTTP objects PER ally hostname. This allows for HTTP
  # connection pooling which avoids opening a new connection to
  # the Ally REST API
  http_caches = {}

  ##
  # Get a request object that can be constructed for the parameters
  # to the `sign` or `proxy` endpoints
  def get_request()
    # Respond with a 400 if the Ally plugin hasn't been enabled
    plugin_data = get_plugin_data
    if !plugin_data[:enabled]
      render :text => "Ally has not been enabled yet", :status => :bad_request
      return false
    end

    # Send an appropriate response depending on the role of the user
    role = get_course_role()
    if role == nil
      render_unauthorized_action
      return false
    end

    # Get the parameters that need to be signed
    method = params['http_method']
    path = params['http_path']
    parameters = params['http_parameters']

    # Perform basic validation of the parameters
    if !(method == "GET" || method == "POST")
      render :text => "The provided http_method needs to be 'GET' or 'POST'", :status => :bad_request
      return false
    elsif !path || !parameters
      render :text => "The http_path and http_parameters need to be provided", :status => :bad_request
      return false
    end

    # Convert the parameters to a hash
    parameters = Rack::Utils.parse_nested_query(parameters)

    # Sign and return the request
    ally_client = Ally::Client.new(plugin_data[:client_id], plugin_data[:secret], plugin_data[:base_url])
    course_id = @context.id
    user_id = @current_user[:id]
    return ally_client.sign(course_id, user_id, role, method, path, parameters)
  end

  ##
  # Get the Ally role of the current user within the course.
  #
  # Returns one of:
  #   - "course-manager"  if the user can add or update files in the course
  #   - "student"         if the user has READ rights in the course
  #   - nil               if the user does not have access to the course
  def get_course_role
    get_context
    if @context.grants_any_right?(@current_user, session, *Array([:update, :create]))
      "course-manager"
    elsif @context.grants_any_right?(@current_user, session, *Array(:read))
      "student"
    else
      nil
    end
  end

  ##
  # Get the plugin data for this account
  def get_plugin_data
    plugin = Canvas::Plugin.find(:ally)
    enabled = plugin.try(:enabled?)
    data = {
      :enabled => enabled
    }
    if enabled
      data[:client_id] = plugin.settings[:client_id_dec]
      data[:secret] = plugin.settings[:secret_dec]
      data[:base_url] = plugin.settings[:base_url_dec]
    end

    data
  end
end
