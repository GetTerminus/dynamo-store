# Actual Dynamo DB calls need to go here
#
class Dynamo
  class Store < self
    def initialize
    end

    def get(key)
      Dynamo::Model.find(cache_key: key).cache_value
    end

    def write(key, item)
      Dynamo::Model.new(cache_key: key,cache_value: item).save
    end
  end
end