######################################## Encryption module #########################################
############################ AES 128-bit encryption with SHA256 Hash ###############################

####################################### New PG Encryption ##########################################

module EncryptionNewPG

  require 'openssl'
  require 'base64'
  require 'digest'
  require 'securerandom'

  ### function returns dictionary of encrypted data ###
  ### accepts a dictionary with data and key to encrypt with ###
  ### can accept multiple key value pairs in the dictionary ###
  def new_pg_encrypt(paytmparams)
    if (paytmparams.class != Hash) || (paytmparams.keys == [])
      return false
    end
    if !paytmparams.has_key?(:key)
      return false
    end
    encrypted_data = Hash[]
    key = paytmparams.delete(:key)
    keys = paytmparams.keys
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    begin
      keys.each do |k|
        data = paytmparams[k]
        aes.encrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        encrypted_k = aes.update(k.to_s) + aes.final
        encrypted_k = Base64.encode64(encrypted_k.to_s)
        aes.encrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        encrypted_data[encrypted_k] = aes.update(data.to_s) + aes.final
        encrypted_data[encrypted_k] = Base64.encode64(encrypted_data[encrypted_k])
      end
    rescue Exception => e
      return false
    end
    return encrypted_data
  end

  ### function returns a single encrypted value ###
  ### input data -> value to be encrypted ###
  ### key -> key to use for encryption ###
  def new_pg_encrypt_variable(data, key)
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    aes.encrypt
    aes.key = key
    aes.iv = '@@@@&&&&####$$$$'
    encrypted_data = nil
    begin
      encrypted_data = aes.update(data.to_s) + aes.final
      encrypted_data = Base64.encode64(encrypted_data)
    rescue Exception => e
      return false
    end
    return encrypted_data
  end


  ### function returns dictionary of decrypted data ###
  ### accepts a dictionary with data and key to decrypt with ###
  ### can accept multiple key value pairs in the dictionary ###
  def new_pg_decrypt(paytmparams)
    if (paytmparams.class != Hash) || (paytmparams.keys == [])
      return false
    end
    if !paytmparams.has_key?(:key)
      return false
    end
    decrypted_data = Hash[]
    key = paytmparams.delete(:key)
    keys = paytmparams.keys
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    begin
      keys.each do |k|
        data = paytmparams[k]
        aes.decrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        decrypted_k = Base64.decode64(k.to_s)
        decrypted_k = aes.update(decrypted_k.to_s) + aes.final
        if data.empty?
          decrypted_data[decrypted_k] = ""
          next
        end
        aes.decrypt
        aes.key = key
        aes.iv = '@@@@&&&&####$$$$'
        data = Base64.decode64(data)
        decrypted_data[decrypted_k] = aes.update(data) + aes.final
      end
    rescue Exception => e
      return false
    end
    return decrypted_data
  end


  ### function returns a single decrypted value ###
  ### input data -> value to be decrypted ###
  ### key -> key to use for decryption ###
  def new_pg_decrypt_variable(data, key)
    aes = OpenSSL::Cipher::Cipher.new("aes-128-cbc")
    aes.decrypt
    aes.key = key
    aes.iv = '@@@@&&&&####$$$$'
    decrypted_data = nil
    begin
      decrypted_data = Base64.decode64(data.to_s)
      decrypted_data = aes.update(decrypted_data) + aes.final
    rescue Exception => e
      return false
    end
    return decrypted_data
  end


  def new_pg_generate_salt(length)
    salt = SecureRandom.urlsafe_base64(length*(3.0/4.0))
    return salt.to_s
  end


  ### function returns checksum of given key value pairs ###
  ### accepts a hash with key value pairs ###
  ### calculates sha256 checksum of given values ###
  def new_pg_checksum(paytmparams, key, salt_length = 4)
    if paytmparams.class != Hash
      return false
    end
    if key.empty?
      return false
    end
    salt = new_pg_generate_salt(salt_length)
    keys = paytmparams.keys
    str = nil
    keys = keys.sort
    keys.each do |k|
      if str.nil?
        str = paytmparams[k].to_s
        next
      end
      str = str + '|'  + paytmparams[k].to_s
    end
    str = str + '|' + salt
    check_sum = Digest::SHA256.hexdigest(str)
    check_sum = check_sum + salt
    ### encrypting checksum ###
    check_sum = new_pg_encrypt_variable(check_sum, key)
    return check_sum
  end

  ### function returns checksum of given key value pairs ###
  ### accepts a hash with key value pairs ###
  ### calculates sha256 checksum of given values ###
  def new_pg_refund_checksum(paytmparams, key, salt_length = 4)
    keys = paytmparams.keys
    keys.each do |k|
      if ! paytmparams[k].empty?
        #if params[k].to_s.include? "REFUND"
        unless paytmparams[k].to_s.include? "|"
            next
        end
        paytmparams[k] = paytmparams[k]
      end
    end
    if paytmparams.class != Hash
      return false
    end
    if key.empty?
      return false
    end
    salt = new_pg_generate_salt(salt_length)
    keys = paytmparams.keys
    str = nil
    keys = keys.sort
    keys.each do |k|
      if str.nil?
        str = paytmparams[k].to_s
        next
      end
      str = str + '|'  + paytmparams[k].to_s
    end
    str = str + '|' + salt
    check_sum = Digest::SHA256.hexdigest(str)
    check_sum = check_sum + salt
    ### encrypting checksum ###
    check_sum = new_pg_encrypt_variable(check_sum, key)
    return check_sum
  end

  ### function returns checksum of given key value pairs (must contain the :checksum key) ###
  ### accepts a hash with key value pairs ###
  ### calculates sha256 checksum of given values ###
  ### returns true if checksum is consistent ###
  ### returns false in case of inconsistency ###
  def new_pg_verify_checksum(paytmparams, check_sum, key, salt_length = 4)
    binding.pry
    if paytmparams.class != Hash
      return false
    end
    if key.empty?
      return false
    end
    if check_sum.nil? || check_sum.empty?
      return false
    end
    generated_check_sum = nil
    check_sum = new_pg_decrypt_variable(check_sum, key)
    if check_sum == false
      return false
    end
    begin
      salt = check_sum[(check_sum.length-salt_length), (check_sum.length)]
      keys = paytmparams.keys
      str = nil
      keys = keys.sort
      keys.each do |k|
        if str.nil?
          str = paytmparams[k].to_s
          next
        end
        str = str + '|' + paytmparams[k].to_s
      end
      str = str + '|' + salt
      generated_check_sum = Digest::SHA256.hexdigest(str)
      generated_check_sum = generated_check_sum + salt
    rescue Exception => e
      return false
    end
    if check_sum == generated_check_sum
      return true
    else
      return false
    end
  end

end
