# Dynamo Store Cache for Rails


## Usage
 https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html

## Install in Rails

#### Add Gem
```ruby
gem 'dynamo-store', git: 'https://github.com/GetTerminus/dynamo-store.git'
```

#### config/initializers/dynamo_store.rb
```ruby
require 'dynamo'
DynamoCache = ActiveSupport::Cache::Dynamo.new
```





