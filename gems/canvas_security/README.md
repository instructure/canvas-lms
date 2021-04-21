# CanvasSecurity

An artisanal collection of utility functions for making sure
we don't goof on auth/privacy.

## Usage

CanvasSecurity encapsulates pretty much anything canvas has to do
for encrypting/decrypting, signing/verifying, and encoding/decoding.
This library depends on ConfigFile and DynamicSettings for loading
the right settings at runtime from the canvas environment,
so you can worry about securing the right things.

### Encryption/Decryption

If you need to package up some blob of data so that it is not
deciperable in the wild, you can use encrypt:

```ruby
my_secret_data = 'foobar'
encrypted = CanvasSecurity.encrypt_data(my_secret_data)
```

This will use 'aes-256-gcm' to encrypt the data using a random
nonce and the encryption key stored in the security.yml config.
The return value is an array containing:

```ruby
[
  encrypted_data,
  nonce,
  tag
]
```

You can pass these around even outside the ecosystem, because they
require the key to decrypt.

At a later time when canvas needs to decrypt these to get the
original value, you pass these three values to:

```ruby
unencrypted = CanvasSecurity.decrypt_data(encrypted_data, nonce, tag)
```

There' another pair of methods (encrypt_password/decrypt_password), which
perform a very similar function:

```ruby
crypted_secret, salt = CanvasSecurity.encrypt_password(secret, 'some_useful_name')
###
secret = CanvasSecurity.decrypt_password(crypted_secret, salt, 'some_useful_name')
```

The major difference between the two is that the string you pass as a useful
name is concatenated as part of the encryption key, so that with
a single encryption key configured for canvas, you can still use a unique key for
a given specific secret.

### Signing/Verifying

To generate a useful signature for a blob of data, use:

```ruby
data_packet = 'some_thing_important'
signature = CanvasSecurity.sign_hmac_sha512(data_packet)
```

these can be passed around together outside the network because
you would need the signing secret to re-generate a signature
if you changed the content of the data packet.  To verify
the packet was generated internally later:

```ruby
verified = CanvasSecurity.verify_hmac_sha512(data_packet, signature)
```

if verified is true, the contents of the data and the signature
match.  If it's false, the data packet has been modified and would
have generated a different signature, and you can reject the packet as suspect.


### JWTs

Canvas uses JWTs for passing around signed information about who
a user is and what they're allowed to do. You can issue a JWT
based on a ruby hash you construct:

```ruby
payload = {foo: 'bar'}
jwt = CanvasSecurity.create_encrypted_jwt(payload, signing_secret, encryption_secret)
```

Although that JWT contains almost no information^, it is
still a correctly signed token that's been subsequently encrypted.

You can verify the signature and decrypt upon receiving such a token:

```ruby
decrypted = CanvasSecurity.decrypt_services_jwt(jwt, signing_secret, encryption_secret)
```

This will error unless your JWT has a valid signature and can be decrypted.

### Encode/Decode

CanvasSecurity has a simple wrapper around base64 encoding, the
primary value of which is forcing the string encoding to change
consistently:

```ruby
text = "foobar"
encoded = CanvasSecurity.base64_encode(text)
decoded = CanvasSecurity.base64_decode(encoded)
```

## Running Tests

This gem is tested with rspec.  You can use `test.sh` to run it, or
do it yourself with `bundle exec rspec spec`.