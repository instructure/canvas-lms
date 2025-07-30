# frozen_string_literal: true

# In app/controllers/token_generator_controller.rb

class TokenGeneratorController < ApplicationController
  # This skips all standard security checks for this one action
  skip_before_action :require_user, :require_login, :require_password_session, :get_context, :find_token, raise: false

  # CHANGE THIS to a secret key your Java app must send
  BACKEND_SECRET_KEY = "change-this-to-a-very-long-and-secret-string"

  def create_for_user
    # Authenticate your backend service
    unless request.headers["X-Backend-Secret"] == BACKEND_SECRET_KEY
      return render json: { error: "Unauthorized to use this endpoint" }, status: :unauthorized
    end

    # --- vvv THIS IS THE MODIFIED LOGIC vvv ---

    # 1. Get username and password from the request body
    username = params[:username]
    password = params[:password]

    unless username && password
      return render json: { error: "Username or password missing" }, status: :bad_request
    end

    # 2. Find the user's login pseudonym
    pseudonym = Pseudonym.find_by(unique_id: username.downcase)

    # 3. Authenticate the user
    if pseudonym&.valid_password?(password)
      user = pseudonym.user

      # 4. If authentication is successful, proceed to create the token
      dev_key = DeveloperKey.default
      return render json: { error: "Default developer key not found" }, status: :internal_server_error unless dev_key

      plaintext_token = SecureRandom.hex(40)

      begin
        user.access_tokens.create!(
          developer_key: dev_key,
          purpose: "Backend Service Token for " + user.name,
          token: plaintext_token,
          workflow_state: "active"
        )

        render json: { access_token: plaintext_token }
      rescue => e
        render json: { error: "Failed to save token: #{e.message}" }, status: :internal_server_error
      end
    else
      # 5. If authentication fails, return an error
      render json: { error: "Invalid username or password" }, status: :unauthorized
    end
    # --- ^^^ END OF MODIFIED LOGIC ^^^ ---
  end
end