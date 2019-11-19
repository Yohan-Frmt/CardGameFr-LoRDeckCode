<h1 align="center">CardGameFr-LoRDeckCode</h1>

Ruby version of the [**RiotGames/LoRDeckCodes**](https://github.com/RiotGames/LoRDeckCodes/) library, used to encode and decode [**Legends of Runeterra**](http://playruneterra.com) decks

## Install

base32 gem from [**stesla/base32**](https://github.com/stesla/base32/) is required. 
```
gem install base32
```
## Simple Usage
```ruby
require_relative 'LorDeckCode'

# Get an Array of Hashes from String
deck = LorDeckCode.decode 'CEBAKAIAAMEQWIBNAQAQEEZAG44QEAYBAIGBEMICAEAAOGQBAMAQADY5GQ
=begin
[
  {:code=>"01DE003", :count=>3},
  {:code=>"01DE009", :count=>3},
  {:code=>"01DE011", :count=>3},
  {:code=>"01DE032", :count=>3},
  {:code=>"01DE045", :count=>3},
  {:code=>"01IO019", :count=>3},
  {:code=>"01IO032", :count=>3},
  {:code=>"01IO055", :count=>3},
  {:code=>"01IO057", :count=>3},
  {:code=>"01IO012", :count=>2},
  {:code=>"01IO018", :count=>2},
  {:code=>"01IO049", :count=>2},
  {:code=>"01DE007", :count=>2},
  {:code=>"01DE026", :count=>2},
  {:code=>"01DE015", :count=>1},
  {:code=>"01DE029", :count=>1},
  {:code=>"01DE052", :count=>1}
]
=end

# Get String from Array of Hashes
deck_code = LorDeckCode.encode deck
# CEBAKAIAAMEQWIBNAQAQEEZAG44QEAYBAIGBEMICAEAAOGQBAMAQADY5GQ
```