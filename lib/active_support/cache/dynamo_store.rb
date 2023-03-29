# frozen_string_literal: true

require 'active_support'
require 'active_support/cache'
require 'active_support/notifications'

begin
  require 'aws-sdk-dynamodb'
rescue LoadError
  require 'aws-sdk'
end

module ActiveSupport
  module Cache
    class DynamoStore < Store
      DEFAULT_HASH_KEY = 'CacheKey'
      DEFAULT_TTL_KEY = 'TTL'
      CONTENT_KEY = 'b_item_value'

      attr_reader :data, :dynamodb_client, :hash_key, :ttl_key, :table_name, :error_handler

      DEFAULT_ERROR_HANDLER = lambda { |method:, returning:, exception:|
        logger&.error { "DynamoStore: #{method} failed, returned #{returning.inspect}: #{exception.class}: #{exception.message}" }
      }

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
        error_handler: DEFAULT_ERROR_HANDLER,
        **opts
      )
        super(opts)
        @table_name      = table_name
        @dynamodb_client = dynamo_client || Aws::DynamoDB::Client.new
        @ttl_key         = ttl_key
        @hash_key        = hash_key
        @error_handler = error_handler
      end

      protected

      def read_entry(name, _options = nil)
        result = failsafe :read_entry do
          dynamodb_client.get_item(
            key: { hash_key => name },
            table_name: table_name,
          )
        end

        return if result.nil? || result.item.nil? || result.item[CONTENT_KEY].nil?

        Marshal.load(result.item[CONTENT_KEY]) # rubocop:disable Security/MarshalLoad
      rescue TypeError
        nil
      end

      def write_entry(name, value, _options = nil)
        item = {
          hash_key => name,
          CONTENT_KEY => StringIO.new(Marshal.dump(value)),
        }

        item[ttl_key] = value.expires_at.to_i if value.expires_at

        failsafe(:write_entry, returning: false) do
          dynamodb_client.put_item(item: item, table_name: table_name)
        end

        true
      end

      def delete_entry(name, _options = nil)
        failsafe :delete_entry do
          dynamodb_client.delete_item(
            key: { hash_key => name },
            table_name: table_name,
          )
        end
      end

      private

      def failsafe(method, returning: nil)
        yield
      rescue Aws::DynamoDB::Errors::ServiceError => e
        error_handler&.call(method: method, exception: e, returning: returning)
        returning
      end
    end
  end
end
