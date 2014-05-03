# Canvas Breach Mitigation

This is a fork of the breach-mitigation-rails gem: http://rubygems.org/gems/breach-mitigation-rails

TODO: Ideally this should be replaced with the gem

Makes Rails applications less susceptible to the BREACH /
CRIME attacks. See [breachattack.com](http://breachattack.com/) for
details.

## How it works

This implements one of the suggestion mitigation strategies from
the paper:

*Masking Secrets*: The Rails CSRF token is 'masked' by encrypting it
with a 32-byte one-time pad, and the pad and encrypted token are
returned to the browser, instead of the "real" CSRF token. This only
protects the CSRF token from an attacker; it does not protect other
data on your pages (see the paper for details on this).

## Warning!

BREACH and CRIME are **complicated and wide-ranging attacks**, and this
gem offers only partial protection for Rails applications. If you're
concerned about the security of your web app, you should review the
BREACH paper and look for other, application-specific things you can
do to prevent or mitigate this class of attacks.


## Gotchas

* If you have overridden the verified_request? method in your
  application (likely in ApplicationController) you may need to update
  it to be compatible with the secret masking code.
