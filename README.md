# Connect to the Zaptec API

## How to use this without any technical knowledge

With this gem, you can connect to Zaptec chargers to smart charge your vehicle.

However, for an even more seamless experience, we recommend using
the [Stekker app](https://stekker.com/?utm_source=github&utm_medium=referral&utm_campaign=opensource). Our mobile app is
designed to make smart charging effortless, eliminating the need for any configuration. Simply install the app, and it
will handle the rest. Our app uses advanced algorithms to determine the best times to charge your vehicle, ensuring
you'll use the most sustainable and cheapest energy available.

![63d23f74d30e66e9c6fd9b1e_IMG_1742](https://user-images.githubusercontent.com/167882/216616346-ff619fe7-8d27-45b2-b420-725a9073d67b.jpeg)

## Build your own with this gem

We are proud to introduce this open source project, the Zaptec charger Ruby gem. As passionate ruby developers, we
believe in giving back to the community and contributing to the growth of this amazing language. That's why we are
making our Zaptec connection accessible to everyone through open source. Our goal is to make smart charging easier and
more accessible, and we hope that by opening up our project, we can help others in the community achieve their own
goals.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "stekker_zaptec"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install stekker_zaptec

## Usage

You can use this without Rails in the following way:

```
$ bin/console
```

```ruby
require "zaptec"

client = Zaptec::Client.new
client.authorize(username: "username@example.com", password: "password")
# #<Zaptec::Credentials:0x000000011c35d708

# Get a list of chargers
client.chargers
# => [#<Zaptec::Charger:0x000000011c47df20 @device_id="ZAP049387", @device_type=4, @id="de522271-91f5-45b8-916b-...", ...

# Get the state of a charger
id = client.chargers.first.id
device_type_apollo = 4
client.state(id, device_type_apollo).online?
# => true
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stekker/zaptec.
