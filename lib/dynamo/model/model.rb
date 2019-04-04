# frozen_string_literal: true

class Dynao
  class Model
    DEFAULT_TTL = 60 * 10 # 10 minutes
    include Dynamoid::Document

    table name: ENV['DYNAMO_TABLE_DYNAMO_CACHE'], key:  :cache_key

    # Dynamo default field type is string

    field :cache_key
    field :ttl
    field :cache_value

    after_initialize  :set_ttl, unless: :persisted?

    private

    def set_ttl
      self.ttl = Time.now.to_i + (ENV['DYNAMO_TABLE_DYNAMO_CACHE_TTL'] || DEFAULT_TTL).to_i
    end

  end

end
