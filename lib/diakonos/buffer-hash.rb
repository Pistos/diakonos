class BufferHash < Hash
  def [] ( key )
    super File.expand_path( key.to_s )
  end
  
  def []= ( key, value )
    super File.expand_path( key.to_s ), value
  end
end

