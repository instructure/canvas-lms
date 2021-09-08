# InstAccess

An InstAccess token is a signed, encrypted JWT (aka a JWE) that is usable to
authenticate to the Canvas API and any other APIs in the Instructure ecosystem
that choose to use it.  Depending on how this gem is configured, the
`InstAccess::Token` class can (a) both issue encrypted tokens and validate and
deserialize decrypted tokens, or (b) just validate and deserialize decrypted
tokens.  It can therefore be used by the identity provider (today this is
Canvas) to produce tokens, but also by any services that want to accept
InstAccess tokens for authentication (including Canvas -- it is both an
InstAccess token provider and an InstAccess token consumer).

Signing and encryption are each asymmetrical procedures.  Signing is done with
an RSA private key, encrypting is done with an RSA public key, and these should
not be corresponding keys.  I.e. there are two RSA keypairs involved.

In addition to the single InstAccess token provider and many InstAccess token
consumers, there is a single InstAccess token decrypter.  This is an API
Gateway tier that sits between the public internet, which always deals with
encrypted InstAccess tokens, and the private network of Instructure services,
which are only able to deal with decrypted InstAccess tokens.

The `InstAccess::Token` class can generate encrypted InstAccess tokens when
it's configured with both a private signing key and a public encryption key.
It can also validate and deserialize decrypted InstAccess tokens with this
configuration.  The single InstAccess provider should be configured this way.

All InstAccess token consumers should configure the class with just the
*public* signing key, which will allow them only to validate and deserialize
decrypted tokens.

The API Gateway needs to know the private encryption key and the public signing
key so that it can decrypt tokens and validate them before passing them to
InstAccess token consumers.

## Configuration Cheat Sheet

Given two keypairs in plaintext:
```ruby
private_signing_key = "-----BEGIN RSA PRIVATE KEY-----\n123abc..."
public_signing_key = "-----BEGIN PUBLIC KEY-----\n456def..."
private_encryption_key = "-----BEGIN RSA PRIVATE KEY-----\n321qwe..."
public_encryption_key = "-----BEGIN PUBLIC KEY-----\n987asd..."
```

The InstAccess token provider should be configured like:
```ruby
InstAccess.configure(
  signing_key: private_signing_key,
  encryption_key: public_encryption_key
)
```

InstAccess token consumers should be configured like:
```ruby
InstAccess.configure(
  signing_key: public_signing_key
)
```

And the `private_encryption_key` is only known to the API Gateway.

## How do I decrypt tokens?

Unless you're the API Gateway, you shouldn't be asking!

As noted earlier, clients only get to handle encrypted tokens, while services
only accept decrypted ones.  Esablishing this asymmetry along with a single
decrypter in between -- the API Gateway -- gives us a few benefits.

1. It forces clients to go through the API Gateway whenever they use an
   InstAccess token, even if they only need to interact with one underlying
   service.  This reduces the amount of responsibility individual services
   have, allowing them to rely on the gateway for things like throttling and
   token verification.

2. It reduces the surface area for an attack on the private decryption key.  If
   every service needed to be able to accept encrypted keys, then they'd each
   need access to the private decryption key to do so.

Since this gem isn't intended to be used by the API Gateway, it provides no
functionality for decrypting tokens.  But there's no special sauce here -- the
tokens are encrypted according to the open [JWE
standard](https://datatracker.ietf.org/doc/html/rfc7516), for which there exist
[many libraries](https://jwt.io/#libraries-io) that make decryption easy.
