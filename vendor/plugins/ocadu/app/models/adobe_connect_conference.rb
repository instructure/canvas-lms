require 'net/http'
require 'net/https'
require 'httpclient'
class AdobeConnectConference < WebConference
  
  # Some params:
  # conference_key - vendor-specific conference ID. Needs to be specified
  # title - user-provided name of the conference
  # user - conference creator 
  # description
  # duration
  # uuid
  
  # Called by WebConference.craft_url, when starting / joining a meeting
  # Returns the conference key, which in this case is the meeting SCO ID
  def initiate_conference 
    return conference_key if conference_key
    
    create_meeting unless meeting_exists?
    save
    get_conference_key
  end
  
  # Required by WebConference
  def conference_status
    active = meeting_exists?
    active ? :active : :closed
  end

  def admin_join_url(user, return_to="http://www.instructure.com")
    add_admin(user)
    meeting_url
  end
  
  def participant_join_url(user, return_to="http://www.instructure.com")
    add_admin(user) if self.grants_right?(user, nil, :initiate)
    meeting_url
  end
  
  private
  
  # Retrieve the SCO ID for this meeting
  def get_conference_key
    params = { 'url-path' => meeting_url_suffix }                                                                                                                                                          
    result = request('sco-by-url', params)                                                                                                                                                                     
    result.xpath('//results/sco[@sco-id]').attr('sco-id').value
  end
  
  # Registers user as a particpant with connect
  def add_admin(user)
    params = {
      'acl-id'        => get_conference_key,
      'principal-id'  => connect_user_id(user),
      'permission-id' => 'host'
    }
    request('permissions-update', params)
  end
  
  def create_meeting
    params = {
      'type'        => 'meeting',
      'name'        => meeting_name,
      'folder-id'   => meeting_folder_id,
      'date-begin'  => self.start_at.iso8601,
      'url-path'    => meeting_url_suffix
    }
    params['date-end'] = self.end_at.iso8601 unless end_at.nil?
    result = request('sco-update', params)
    
    # Check response status code for "ok"
    if ( result.xpath('//results/status[@code = "ok"]').empty? )
      error = result.at_xpath('//results/status/invalid')
      error_msg = "adobe connect error creating meeting. Field: #{error['field']}, Value: #{error['subcode']}"
      logger.error error_msg
      return nil 
    end
    meeting_sco_id = result.at_xpath('//results/sco')['sco-id']
    
    # Make meeting public
    response = request('permissions-update', {
      'acl-id'          => meeting_sco_id,
      'principal-id'    => 'public-access',
      'permissions-id'  => 'view-hidden'
    })
    
    # Return meeting sco-id
    meeting_sco_id
  end
  
  def meeting_exists?
    params = { 'url-path' => meeting_url_suffix }
    result = request('sco-by-url', params)
    !result.xpath('//results/status[@code = "ok"]').empty?
  end
  
  # Define meeting name based on course info + conference id (must be unique)
  def meeting_name
    "#{self.context.course_code}: #{self.title} [#{self.id}]"
  end
 
  def meeting_url
    "#{config[:domain]}/#{meeting_url_suffix}" 
  end
    
  def meeting_url_suffix
    "canvas-meeting-#{self.id.to_s}"
  end
  
  # Find the meeting container folder sco by name
  def meeting_folder_id
    # First call sco-shortcuts to find the 'user-meetings' folder
    meeting_container = request('sco-shortcuts').at_xpath '//results/shortcuts/sco[@type="user-meetings"]'
    return nil if meeting_container == nil
    
    # Get sco details for the specified meeting folder
    meeting_folder = request('sco-expanded-contents', {
      'sco-id'      => meeting_container['sco-id'], 
      'filter-name' => config[:meeting_container] 
    }).at_xpath '//results/expanded-scos/sco'
    
    return nil if meeting_folder == nil
    
    # Return sco id of meeting folder
    meeting_folder['sco-id']
  end
  
  # Load the session key needed for authentication
  def session_key
    return @session_key if @session_key
    @session_key = request('common-info', nil, true).at_xpath('//results/common/cookie').content   
  end
  
  # Checks if a user exists, if not, create them
  def connect_user_id(user)
    # Use sis login : user.sis_user_id
    response = request('principal-list', {
      'filter-login'  => user.sis_user_id
    })
    
    return response.at_xpath('//results/principal-list/principal')['principal-id'] unless response.xpath('//results/principal-list').empty?
    
    # User not found. Create them
    connect_create_user user
  end
  
  # Create the connect user
  def connect_create_user(user)
    response = request('principal-update', {
      'first-name'   => user.first_name,
      'last-name'    => user.last_name,
      'login'        => user.sis_user_id,
      'password'     => '',
      'type'         => 'user',
      'has-children' => '0',
      'email'        => user.email
    })
    
    # Check response
    #raise response.inspect
  end
  
  # Authenticate to connect
  def login
    return if logged_in?
    
    xml = request('login', { 
      'login'     => config[:login], 
      'password'  => config[:password_dec]}, 
      true
    )
    
    # Check status of last request. Should have a code attribute == ok
    if ( xml.xpath('//results/status[@code = "ok"]').empty? )
      logger.error "adobe connect login error"
      raise "Unable to login to Adobe Connect Server" 
    end
    
    true
  end
  
  # Checks if we are logged in
  def logged_in?
    xml = request('common-info', nil, true)
    # Check for presence of user node. If it's not empty, we're logged in
    ! xml.xpath('//results/common/user').empty?
  end
  
  # Make a request to server. Will confim login first, unless skipped flag is set
  def request(command, params={}, skip_session=false)
    params['session' => session_key] unless skip_session
    login unless skip_session
    
    uri = "#{config[:domain]}/api/xml?action="+command
    response = client.get(uri, params)
    #response.status - HTTP CODE
    #response.header
    
    xml = Nokogiri::XML(response.body)
    
    # TODO: error checking
    #result = xml.xpath('//results/status') 
    
    xml
  end
  
  # Get http client. Lazy-load
  def client
    return @client || @client = HTTPClient.new
  end
  
  # attr_accessible :long_running
  # end
  # def conference_status
    # :active
    # #if (result = send_request(:isMeetingRunning, :meetingID => conference_key)) && result[:running] == 'true'
    # #  :active
    # #else
    # #  :closed
    # #end
  # end

end
