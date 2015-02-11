class Attachments::Verification

  # Attachment verifiers are tokens that can be added to attachment URLs that give
  # the holder of the URL the ability to read an attachment without having an
  # authenticated session. Verifiers capture in them the user id of the current user,
  # the context where the user is viewing the content, and an expiration date.

  attr_reader :attachment

  def initialize(attachment)
    @attachment = attachment
  end

  # Creates a signed verifier for the attachment and specified user. This verifier
  # can be used in attachment URLs to create a signed URL for access in
  # non-authenticated scenarios (such as via the API, mobile, etc).
  #
  # @param user (User) - The user granted access to the attachment
  # @param context (String) - The context where the verifier is created. This is optional
  #   but strongly recommended for debugging, and possible future uses. Normally it will
  #   be the asset_string of an AR object.
  # @param expires (Time) - When the verifier should expire. `nil` for no expiration
  #
  # Returns the verifier as a string.
  def verifier_for_user(user, ctx = nil, expires = nil)
    body = {
      id: attachment.global_id,
      ctx: ctx
    }

    if user
      body[:user_id] = user.global_id
    end

    Canvas::Security.create_jwt(body, expires)
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
    return attachment.grants_right?(user, {}, permission)
  end
end

