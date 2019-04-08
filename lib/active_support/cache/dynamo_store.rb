# frozen_string_literal: true

require 'active_support/cache'
require 'aws-sdk'

module ActiveSupport
  module Cache
    class Dynamo < Store
      DEFAULT_HASH_KEY = 'CacheKey'
      DEFAULT_TTL_KEY = 'TTL'
      CONTENT_KEY = 'item_value'

      attr_reader :data, :dynamodb_client, :hash_key, :ttl_key, :table_name

      # Instantiate the store.
      #
      # Example:
      #   ActiveSupport::Cache::Dynamo.new(table_name: 'CacheTable')
      #     => hash_key: 'CacheKey', ttl_key: 'TTL', table_name: 'CacheTable'
      #
      #   ActiveSupport::Cache::Dynamo.new(
      #     table_name: 'CacheTable',
      #     dynamo_client: client,
      #     hash_key: 'name',
      #     ttl_key: 'key_ttl'
      #   )
      #
      def initialize(
        table_name:,
        dynamo_client: nil,
        hash_key: DEFAULT_HASH_KEY,
        ttl_key: DEFAULT_TTL_KEY,
        **opts
      )
        super(opts)
        @table_name      = table_name
        @dynamodb_client = dynamo_client || Aws::DynamoDB::Client.new
        @ttl_key         = ttl_key
        @hash_key        = hash_key
      end

      protected

      def read_entry(name, _options = nil)
        result = dynamodb_client.get_item(
          key: { hash_key => name },
          table_name: table_name
        )

        return if result.item.nil?

        Marshal.load(result.item[CONTENT_KEY]) # rubocop:disable Security/MarshalLoad
      rescue TypeError
        nil
      end

      def write_entry(name, value, _options = nil)
        item = { hash_key => name, CONTENT_KEY => Marshal.dump(value) }

        item[ttl_key] = value.expires_at.to_i if value.expires_at

        dynamodb_client.put_item(item: item, table_name: table_name)

        true
      end

      def delete_entry(name, _options)
        dynamodb_client.delete_item(
          key: { hash_key => name },
          table_name: table_name
        )
      end
    end
  end
end
