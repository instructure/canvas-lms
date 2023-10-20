# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class PseudonymSession < Authlogic::Session::Base
  LAST_REQUEST_WINDOW = 10.minutes

  last_request_at_threshold LAST_REQUEST_WINDOW
  verify_password_method :valid_arbitrary_credentials?
  login_field :unique_id
  record_selection_method :custom_find_by_unique_id
  remember_me_for 2.weeks
  allow_http_basic_auth false
  consecutive_failed_logins_limit 0

  attr_accessor :remote_ip
  attr_reader :login_error

  # In authlogic 3.2.0, it tries to parse the last part of the cookie (delimited by '::')
  # as a timestamp to verify whether the cookie is stale.
  # This conflicts with the uuid that we use instead in that place,
  # so skip that check for now, to keep behavior similar between Rails 2 and 3.
  def remember_me_expired?
    false
  end

  # ditto
  def cookie_credentials
    nil
  end

  secure CanvasRails::Application.config.session_options[:secure]
  httponly true

  # modifications to authlogic's cookie persistence (used for the "remember me" token)
  # see the SessionPersistenceToken class for details
  def save_cookie
    return unless remember_me?

    token = SessionPersistenceToken.generate(record)
    controller.cookies[cookie_key] = {
      value: token.pseudonym_credentials,
      expires: remember_me_until,
      domain: controller.cookie_domain,
      httponly:,
      secure:,
    }
  end

  def persist_by_cookie
    cookie = controller.cookies[cookie_key]
    if cookie
      token = SessionPersistenceToken.find_by_pseudonym_credentials(cookie)
      self.unauthorized_record = token.use! if token
      is_valid = valid?
      if is_valid
        # this token has been used -- destroy it, and generate a new one
        # remember_me is implicitly true when they login via the remember_me token
        controller.session[:used_remember_me_token] = true
        self.remember_me = true
        save!
      end
      is_valid
    else
      false
    end
  end

  # added behavior: destroy the server-side SessionPersistenceToken as well as the browser cookie
  def destroy_cookie
    cookie = controller.cookies.delete cookie_key, domain: controller.cookie_domain
    return true unless cookie

    token = SessionPersistenceToken.find_by_pseudonym_credentials(cookie)
    token.try(:destroy)
    true
  end

  # Validate the session using password auth (either local or LDAP, but not
  # SSO). If too many failed attempts have occured, the validation will fail.
  # In this case, `login_error` will be non-nil, rather than
  # `invalid_password?`.
  #
  # Note that for IP based max attempt tracking to occur, you'll need to set
  # remote_ip on the PseudonymSession before calling save/valid?. Otherwise,
  # only total # of failed attempts will be tracked.
  def validate_by_password
    super

    # have to call super first, as that's what loads attempted_record
    if (@login_error = attempted_record&.audit_login(remote_ip, !invalid_password?))
      case @login_error
      when :too_many_attempts
        errors.add(password_field, I18n.t("errors.max_attempts", "Too many failed login attempts. Please try again later or contact your system administrator."))
      when :too_recent_login
        errors.add(password_field, I18n.t("errors.rapid_attempts", "You have recently logged in multiple times too quickly. Please wait a few seconds and try again."))
      else
        errors.add(password_field, I18n.t("Login has been denied for security reasons. Please try again later or contact your system administrator."))
      end
      nil
    end
  end

  # This block is pulled from Authlogic::Session::Base.find,
  # which does all this same stuff but logs nothing making it hard
  # to know why your user that was previously logged in is now not
  # logged in.
  def self.find_with_validation
    with_scope(find_options: Pseudonym.eager_load(:user)) do
      sess = new({ priority_record: nil }, nil)
      if sess.nil?
        Rails.logger.info "[AUTH] Failed to create pseudonym session"
        next false
      end
      sess.priority_record = nil
      if sess.persisting?
        Rails.logger.info "[AUTH] Approved Authlogic session"
        next sess
      end
      sess.errors.full_messages.each { |msg| Rails.logger.warn "[AUTH] Authlogic Validation Error: #{msg}" }
      Rails.logger.warn "[AUTH] Authlogic Failed Find" if sess.attempted_record.nil?
      # established AuthLogic behavior is to return false if the session is not valid
      false
    end
  end

  def persist_by_session_search(persistence_token, record_id)
    return super unless record_id

    Shard.shard_for(record_id).activate do
      Rails.cache.fetch(["pseudonym_session", record_id].cache_key, expires_in: Setting.get("pseudonym_session_cache_ttl", 5).to_f.seconds) do
        super
      end
    end
  end

  # this block is pulled from Authlogic::Session::Base.save_record, and does an update_columns in
  # order to avoid a transaction and its associated db roundtrips.
  # It also gives us a useful place to do a smarter update
  # when we have last_request_at tweaks piling up
  def save_record(alternate_record = nil)
    r = alternate_record || record
    if r != priority_record && r&.has_changes_to_save? && !r.readonly?
      changed_columns = r.changes_to_save.keys
      if changed_columns == ["last_request_at"]
        # we're ONLY updating the last_request_at field.  This
        # can create a problem when we're trying to do many of these at
        # once, they pile up waiting on locks and each successful one writes
        # a new version of the row which is I/O intensive since this happens
        # a lot.  We want to use the SAME threshold we use for telling authlogic
        # to not bother incrementing the value to make sure we don't update
        # here if another process has already done so while we were waiting on the lock
        Pseudonym.where(id: r, last_request_at: ...LAST_REQUEST_WINDOW.ago)
                 .update_all(last_request_at: r.last_request_at)
      else
        r.save_without_transaction
      end
    end
  end
end
