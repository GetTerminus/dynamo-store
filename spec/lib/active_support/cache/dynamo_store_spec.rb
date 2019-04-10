# frozen_string_literal: true

require 'spec_helper'
require 'dynamo-store'

RSpec.describe ActiveSupport::Cache::DynamoStore do
  let(:client) do
    Aws::DynamoDB::Client.new(
      region: 'us-east-1',
      endpoint: ENV['DYNAMODB_ENDPOINT'],
      access_key_id: 'a',
      secret_access_key: 'b',
    )
  end

  context 'using the default configuration' do
    let(:standard_table_name) do
      SecureRandom.uuid.tap do |name|
        client.create_table(
          attribute_definitions: [
            { attribute_name: 'CacheKey', attribute_type: 'S' },
          ],
          key_schema: [{ attribute_name: 'CacheKey', key_type: 'HASH' }],
          provisioned_throughput: { read_capacity_units: 5, write_capacity_units: 5 },
          table_name: name
        )
      end
    end

    let(:store) do
      ActiveSupport::Cache::DynamoStore.new(
        table_name: standard_table_name,
        dynamo_client: client
      )
    end

    it 'round trips an object' do
      expect {
        store.write('some_cache', [1,2,3])
      }.to change {
        store.read('some_cache')
      }.from(nil).to([1,2,3])
    end

    it 'allows setting of expiration' do
      store.write('some_cache', [1,2,3], expires_in: 5.minutes)
      item = client.get_item(key: {CacheKey: 'some_cache'}, table_name: standard_table_name).item
      expect(item['TTL']).to eq(5.minutes.from_now.to_i)
    end

    describe '.delete' do
      it 'removes an existing item' do
        store.write('key1', 1)

        expect {
          store.delete('key1')
        }.to change { store.read('key1') }.from(1).to(nil)
      end

      it 'succeeds if a key is not found' do
        expect { store.delete(SecureRandom.uuid) }.not_to raise_error
      end
    end
  end

  context 'using a custom configuration' do
    let(:standard_table_name) do
      SecureRandom.uuid.tap do |name|
        client.create_table(
          attribute_definitions: [
            { attribute_name: 'foo', attribute_type: 'S' },
          ],
          key_schema: [{ attribute_name: 'foo', key_type: 'HASH' }],
          provisioned_throughput: { read_capacity_units: 5, write_capacity_units: 5 },
          table_name: name
        )
      end
    end

    let(:store) do
      ActiveSupport::Cache::DynamoStore.new(
        table_name: standard_table_name,
        hash_key: 'foo',
        ttl_key: 'baz',
        dynamo_client: client
      )
    end

    it 'round trips an object' do
      expect {
        store.write('some_cache', [1,2,3])
      }.to change {
        store.read('some_cache')
      }.from(nil).to([1,2,3])
    end

    it 'allows setting of expiration' do
      store.write('some_cache', [1,2,3], expires_in: 5.minutes)
      item = client.get_item(key: {foo: 'some_cache'}, table_name: standard_table_name).item
      expect(item['baz']).to eq(5.minutes.from_now.to_i)
    end
  end
end
