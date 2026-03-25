# Zaptec

Ruby gem for the [Zaptec](https://zaptec.com) EV charger API. Built and maintained by [Stekker](https://stekker.com).

## Installation

```ruby
gem "stekker_zaptec"
```

## Usage

```ruby
client = Zaptec::Client.new(username: "you@example.com", password: "secret")
```

Token caching and encryption are supported via `token_cache:` and `encryptor:` options.

### Chargers

```ruby
chargers = client.chargers
charger = chargers.first
charger.id              # => "de522271-91f5-..."
charger.device_id       # => "ZAP049387"
charger.installation_id # => "8a3b1c2d-..."
```

### Charger state

```ruby
state = client.state(charger.id, charger.device_type)
state.online?                   # => true
state.charging?                 # => true
state.disconnected?             # => false
state.total_charge_power        # => 7.36 (kW)
state.max_phases                # => 3
state.total_charge_power_session # => 12.4 (kWh)
state.meter_reading             # => #<Zaptec::MeterReading reading_kwh=1234.56>
```

### Charging commands

```ruby
client.pause_charging(charger.id)
client.resume_charging(charger.id)
client.deauthorize_and_stop(charger.id)
```

### Current control

```ruby
client.update_installation(installation_id,
  AvailableCurrentPhase1: 16,
  AvailableCurrentPhase2: 16,
  AvailableCurrentPhase3: 16
)

client.update_charger(charger.id, MaxChargeCurrent: 10)
```

### Installations

```ruby
installation = client.get_installation(installation_id)
installation.address      # => "Keizersgracht 100"
installation.city         # => "Amsterdam"
installation.country_code # => "NL"

hierarchy = client.get_installation_hierarchy(installation_id)
hierarchy.network_type # => "TN_3_Phase"
hierarchy.circuits.each do |circuit|
  circuit.max_current # => 25
  circuit.chargers    # => [#<Zaptec::Charger ...>]
end
```

### Access grant

```ruby
url = client.grant_access_url(
  lookup_key: "user@example.com",
  partner_name: "My App"
)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stekker/zaptec.

## Publishing

```bash
# - bumps the gem version to the next major, minor or patch version.
# - creates commit for the version bump
# - tags the commit
# - pushes the commit and tag
# - publishes the gem to Rubygems
bin/release [major|minor|patch]
# See also https://github.com/svenfuchs/gem-release#gem-bump
```
