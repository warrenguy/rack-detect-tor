# Rack::DetectTor

Rack middleware for detecting Tor exits.

Rack::DetectTor determines whether a user is connecting via a Tor exit
relay. It adds an environment variable `tor_exit_user` to the
`request.env` object with a value of `true` or `false`.

## Usage

Add the gem to your Gemfile:

```ruby
gem 'rack-detect-tor'
```

and add it to your middleware stack. In `config.ru`:

```ruby
require 'rack-detect-tor'

use Rack::DetectTor, 'external_ip' => [ip],
                     'external_port' => [port],
                     'update_frequency' => 3600
```

It is *recommended* to provide `external_ip` and `external_port` (see
below). `update_frequency` is how often Rack::DetectTor will update its
list of Tor exits. It defaults to one hour (3600 seconds).

### Note on `external_ip` and `external_port`

You are not *required* to provide these. However:

It's important to provide the `external_ip` and `external_port` values,
corresponding with the external IP and port of your web server. Many Tor
relays are configured not to allow connections on port 80/443/etc. If you
don't provide or are unable to provide the external IP of your web server,
the value added to `request.env['tor_exit_user']` will tell you only that
the IP corresponds with **A** Tor exit, not necessarily one that is
configured to relay connections to your website.

## License

MIT license. See [LICENSE](https://github.com/warrenguy/sinatra-rate-limiter/blob/master/LICENSE).

## Author

Warren Guy <warren@guy.net.au>

https://warrenguy.me
