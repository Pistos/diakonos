# A Hash which is iterated in insertion order.
# Keys are assumed to be paths; these paths are expanded on read and write.
class BufferHash < Hash
  def initialize
    @keys_ = []
  end

  def [] ( key )
    super File.expand_path( key.to_s )
  end

  def []= ( key, value )
    key = File.expand_path( key.to_s )
    if ! @keys_.include?( key )
      @keys_ << key
    end
    super key, value
  end

  def each
    @keys_.each do |key|
      yield key, self[ key ]
    end
  end

  def each_key
    @keys_.each do |key|
      yield key
    end
  end

  def each_value
    @keys_.each do |key|
      yield self[ key ]
    end
  end

  def clear
    @keys_ = []
    super
  end

  def delete( key )
    @keys_.delete key
    super
  end

  def keys
    @keys_.dup
  end

  def values
    @keys_.map { |key| self[ key ] }
  end

  def length
    @keys_.length
  end
end

