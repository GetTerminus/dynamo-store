# DynamoDB Adapter for [ActiveSupport Cache](https://github.com/rails/rails/tree/master/activesupport/lib/active_support/cache.rb)

## Installation

Add this line to your application's Gemfile:

```
gem 'dynamo-store'
```

And then execute:

```
bundle
```

Or install it yourself as:

```
gem install dynamo-store
```

## Usage

DynamoStore provides an adapter layer ActiveSupport::Cache to DynamoDB. A
serverless key-value store offering millisecond recall and write time.

DynamoStore leverages to the DynamoDB TTL column to automatically remove items
as they reach expiration time, this feature should be enabled, as this adapter
does not implement any manual cleanup steps.

### Configuration
All configuration options are passed during construction of the store. You may
also provide the arguments given to the superclass
[ActiveSupport::Cache::Store](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-c-new).


| Configuration   | Type                   | Default                | Description
| --------------- | -------------------    | ----------------       | ------------
| table_name      | string                 | None. Required         | The name of the DynamoDB Table
| dynamo_client   | Aws:::DynamoDB::Client | Default AWS SDK Client | The client to use for connections. Useful for directing the cache at a local installation
| hash_key        | string                 | 'CacheKey'             | The name of the hash key for the cache table
| ttl_key         | string                 | 'TTL'                  | The colum to use for auto-ttling items


### Rails

```ruby
# in config/application.rb

config.cache_store = :dynamo_store, {table_name: 'AppCache'}
```

### Outside of Rails

```ruby
require 'dynamo-store'

cache = ActiveSupport::Cache::Dynamo.new(table_name: 'AppCache')
```

