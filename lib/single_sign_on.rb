# frozen_string_literal: true

class SingleSignOn
  include ActiveModel::Attributes

  attribute :nonce, :string
  attribute :return_sso_url, :string
  attribute :app_id, :string
  attribute :email, :string
  attribute :external_id, :integer
  attribute :name, :string

  attribute :message_class, :string
  attribute :message_code, :string

  def self.config
    @config ||= DynamicSettings.find("alphacamp-sso", tree: "config", service: "canvas")
  end

  # clinet 專案 ID
  def self.app_id
    "canvas"
  end

  # Account 網址，可以以任意慣用的方式存放
  # https://account.alphacamp.co/sso/connect
  def self.sso_url
    config[:url]
  end

  # client 專案網址，可以以任意慣用的方式存放
  def self.return_url
    config[:return_url]
  end

  # sso_secret ，請以加密的方式存放
  def self.sso_secret
    config[:secret]
  end

  def self.generate_sso(**options)
    sso = new
    sso.nonce = SecureRandom.hex
    sso.message_class = options[:message_class]
    sso.message_code = options[:message_code]

    sso.register_nonce
    sso.return_sso_url = return_url
    sso
  end

  def self.parse(sso_payload, sso_sig)
    sso = new

    if sso.sign(sso_payload) != sso_sig
      diags = "\n\nsso: #{sso_payload}\n\nsig: #{sso_sig}\n\nexpected sig: #{sso.sign(sso_payload)}"
      raise ParseError, "Bad signature for payload #{diags}"
    end

    decoded = Base64.decode64(sso_payload)
    decoded_hash = Rack::Utils.parse_query(decoded)

    decoded_hash.each { |key, value| sso.public_send("#{key}=", value) }

    sso
  end

  def register_nonce
    return unless nonce.present?

    redis.set(nonce_key, "1", ex: 10.minutes.to_i)
  end

  def nonce_valid?
    nonce.present? && redis.get(nonce_key)
  end

  def expire_nonce!
    return unless nonce.present?

    redis.del(nonce_key)
  end

  def to_url
    "#{sso_url}?#{payload}"
  end

  def to_h
    {
      nonce: nonce,
      return_sso_url: return_sso_url,
      app_id: app_id,
      message_class: message_class,
      message_code: message_code
    }
  end

  def lookup_or_create_user
    sso_record = SingleSignOnRecord.find_by(external_id: external_id)

    pseudonym = Pseudonym.find_by(unique_id: email)

    if sso_record && (user = sso_record.user)
      sso_record.update!(last_payload: unsigned_payload)
    else
      user = pseudonym.user

      if (sso_record = user.single_sign_on_record)
        sso_record.update!(external_id: external_id, last_payload: unsigned_payload)
      else
        user.create_single_sign_on_record!(
          external_id: external_id,
          last_payload: unsigned_payload
        )
      end
    end

    [user, pseudonym]
  end

  def sign(payload)
    OpenSSL::HMAC.hexdigest("sha256", sso_secret, payload)
  end

  private

  def app_id
    @app_id || self.class.app_id
  end

  def sso_url
    @sso_url || self.class.sso_url
  end

  def return_url
    @return_url || self.class.return_url
  end

  def sso_secret
    @sso_secret || self.class.sso_secret
  end

  def nonce_key
    "SSO_NONCE_#{nonce}"
  end

  def payload
    payload = Base64.strict_encode64(unsigned_payload)
    "sso=#{CGI.escape(payload)}&sig=#{sign(payload)}"
  end

  def unsigned_payload
    Rack::Utils.build_query(to_h)
  end

  # 如果沒有使用 redis 可以以其他 cache 工具替代
  def redis
    @redis ||= Redis.new
  end
end
