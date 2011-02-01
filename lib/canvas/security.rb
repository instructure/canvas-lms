#
# Copyright (C) 2011 Instructure, Inc.
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

module Canvas::Security
  def self.encryption_key
    res = config && config['encryption_key']
    raise('encryption key required, see security.yml.example') unless res
    raise('encryption key is too short, see security.yml.example') unless res.to_s.length >= 20
    res.to_s
  end
  
  def self.config
    @config ||= (YAML.load_file(RAILS_ROOT + "/config/security.yml")[RAILS_ENV] rescue nil)
  end
  
  def self.encrypt_password(secret, key)
    require 'base64'
    c = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    c.encrypt
    c.key = Digest::SHA1.hexdigest(key + "_" + encryption_key)
    c.iv = iv = c.random_iv
    e = c.update(secret)
    e << c.final
    [Base64.encode64(e), Base64.encode64(iv)]
  end
  
  def self.decrypt_password(secret, salt, key)
    require 'base64'
    c = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    c.decrypt
    c.key = Digest::SHA1.hexdigest(key + "_" + encryption_key)
    c.iv = Base64.decode64(salt)
    d = c.update(Base64.decode64(secret))
    d << c.final
    d.to_s
  end
end