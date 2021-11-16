# frozen_string_literal: true

require 'spec_helper'
require 'dynamo-store'

RSpec.describe ActiveSupport::Cache::DynamoStore do
  let(:key) { SecureRandom.uuid }
  let(:client) do
    Aws::DynamoDB::Client.new(
      region: 'us-east-1',
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
        store.write(key, [1,2,3])
      }.to change {
        store.read(key)
      }.from(nil).to([1,2,3])
    end

    it 'allows setting of expiration' do
      store.write(key, [1,2,3], expires_in: 5.minutes)
      item = client.get_item(key: {CacheKey:key}, table_name: standard_table_name).item
      expect(item['TTL']).to eq(5.minutes.from_now.to_i)
    end

    it 'survives if the field is unset' do
      client.put_item(item: {CacheKey: key}, table_name: standard_table_name)
      expect(store.read(key)).to eq nil
    end

    describe '.delete' do
      it 'removes an existing item' do
        store.write(key, 1)

        expect {
          store.delete(key)
        }.to change { store.read(key) }.from(1).to(nil)
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
        store.write(key, [1,2,3])
      }.to change {
        store.read(key)
      }.from(nil).to([1,2,3])
    end

    it 'allows setting of expiration' do
      store.write(key, [1,2,3], expires_in: 5.minutes)
      item = client.get_item(key: {foo:key}, table_name: standard_table_name).item
      expect(item['baz']).to eq(5.minutes.from_now.to_i)
    end
  end
end
