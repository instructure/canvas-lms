class Attachments::Verification

  # Attachment verifiers are tokens that can be added to attachment URLs that give
  # the holder of the URL the ability to read an attachment without having an
  # authenticated session. Verifiers capture in them the user id of the current user,
  # the context where the user is viewing the content, and an expiration date.

  # map from ctx_perm to a hash that maps from file permissions to context permissions
  PERMISSION_MAPS = {
    # e.g., grant :read and :download on the file if the context grants :read
    :r_rd => { :read => :read, :download => :read }.freeze
  }.freeze

  attr_reader :attachment

  def initialize(attachment)
    @attachment = attachment
  end

  # Creates a signed verifier for the attachment and specified user. This verifier
  # can be used in attachment URLs to create a signed URL for access in
  # non-authenticated scenarios (such as via the API, mobile, etc).
  #
  # @param user (User) - The user granted access to the attachment
  # @param opts[context] (String) - The context where the verifier is created. This is optional
  #   but strongly recommended for debugging. It is required when using +permission_map_id+.
  #   Normally it will be the asset_string of an AR object.
  # @params opts[permission_map_id] - Key of a PERMISSION_MAPS entry used to derive file permissions
  #   from context permissions, useful where verifiers grant access to a file that would ordinarily
  #   not be accessible, such as file attachments in user context. If omitted, permissions will be
  #   tested directly on the file.
  # @param opts[expires] (Time) - When the verifier should expire. Omit for no expiration
  #
  # Returns the verifier as a string.
  def verifier_for_user(user, opts = {})
    body = {
      id: attachment.global_id,
      ctx: opts[:context]
    }

    if user
      body[:user_id] = user.global_id
    end
    pm = opts[:permission_map_id]
    body[:pm] = pm.to_s if pm && PERMISSION_MAPS.key?(pm)

    Canvas::Security.create_jwt(body, opts[:expires])
  end

  # Decodes a verifier and asserts its validity (but does not check permissions!). You
  # probably want to use `valid_verifier_for_permission?`.
  #
  # @param verifier (String) - The verifier
  #
  # Returns nil if the verifier could not be decoded for whatever reason, and returns
  # a Hash of the body contents if it can.
  def decode_verifier(verifier)
    begin
      body = Canvas::Security.decode_jwt(verifier)
      if body[:id] != attachment.global_id
        CanvasStatsd::Statsd.increment("attachments.token_verifier_id_mismatch")
        Rails.logger.warn("Attachment verifier token id mismatch. token id: #{body[:id]}, attachment id: #{attachment.global_id}, token: #{verifier}")
        return nil
      end

      CanvasStatsd::Statsd.increment("attachments.token_verifier_success")
    rescue Canvas::Security::TokenExpired
      CanvasStatsd::Statsd.increment("attachments.token_verifier_expired")
      Rails.logger.warn("Attachment verifier token expired: #{verifier}")
      return nil
    rescue Canvas::Security::InvalidToken
      CanvasStatsd::Statsd.increment("attachments.token_verifier_invalid")
      Rails.logger.warn("Attachment verifier token invalid: #{verifier}")
      return nil
    end

    return body
  end

  # Decodes a verifier and checks the user of the verifier has permission to access
  # the attachment.
  #
  # @param verifier (String) - The verifier
  # @param permission (Symbol) - Either :read or :download
  #
  # Returns a boolean
  def valid_verifier_for_permission?(verifier, permission)
    # Support for legacy verifiers.
    if verifier == attachment.uuid
      CanvasStatsd::Statsd.increment("attachments.legacy_verifier_success")
      return true
    end

    body = decode_verifier(verifier)
    if body.nil?
      return false
    end

    # tokens that don't specify a user have no further permissions checking
    if !body[:user_id]
      return true
    end
    user = User.find(body[:user_id])

    if body[:ctx] && body[:pm]
      return check_custom_permission(user, permission, body[:ctx], body[:pm].to_sym)
    end

    attachment.grants_right?(user, {}, permission)
  end

  private

  def check_custom_permission(user, permission, context_asset_string, permission_map_id)
    permission_map = PERMISSION_MAPS[permission_map_id]
    return false unless permission_map

    context = Context.find_asset_by_asset_string(context_asset_string)
    return false unless context

    context.grants_right?(user, {}, permission_map[permission])
  end
end

