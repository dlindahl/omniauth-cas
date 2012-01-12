# OmniAuth CAS Strategy [![Build Status](https://secure.travis-ci.org/dlindahl/omniauth-cas.png)](http://travis-ci.org/dlindahl/omniauth-cas)

A CAS Strategy for OmniAuth.

I didn't really want to do this, but no one else has, so I might as well give it a stab.

This is highly experimental, use at your own risk!

Having said that, please let me know if you discover any problems or
have any feature requests by opening an Issue on the GitHub page. I will try to address
them as fast as I can.

Thanks in advance for trying this out!

## Installation

Add this line to your application's Gemfile:

    gem 'omniauth-cas'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-cas

## Usage

Use like any other OmniAuth strategy:

    Rails.application.config.middleware.use OmniAuth::Builder do
        provider :cas, :host => 'cas.yourdomain.com'
    end

OmniAuth CAS requires at least one of the following two configuration options:

  * `host` - Defines the host of your CAS server. A default login URL of `/login` will be assumed.
  * `login_url` - Defines the URL used to prompt users for their login information.
    If no `host` is configured, the host application's domain will be used.

Other configuration options:

  * `port` - The port to use for your configured CAS `host`
  * `ssl` - TRUE to connect to your CAS server over SSL.
  * `service_validate_url` - The URL to use to validate a user. Defaults to `'/serviceValidate'`
  * `logout_url` - The URL to use to logout a user. Defaults to `'/logout'`
  * `uid_key` - The user data attribute to use as your user's unique identifier. Defaults to `'user'` (which usually contains the user's login name)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
