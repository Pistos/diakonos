class Hash
  # path is an array of hash keys
  # This method deletes a path of hash keys, with each step in the path
  # being a recursively deeper key in a hash tree.
  # Returns the possibly modified hash.
  def delete_key_path( path )
    if path.length > 1
      subtree = self[ path[ 0 ] ]
      if subtree.respond_to?( :delete_key_path )
        subtree.delete_key_path( path[ 1..-1 ] )
        if subtree.empty?
          delete( path[ 0 ] )
        end
      end
    elsif path.length == 1
      delete( path[ 0 ] )
    end

    self
  end

  def set_key_path( path, leaf )
    if path.length > 1
      node = self[ path[ 0 ] ]
      if ! node.respond_to?( :set_key_path )
        node = self[ path[ 0 ] ] = Hash.new
      end
      node.set_key_path( path[ 1..-1 ], leaf )
    elsif path.length == 1
      self[ path[ 0 ] ] = leaf
    end

    self
  end

  def get_node( path )
    node = self[ path[ 0 ] ]
    if path.length > 1
      if node && node.respond_to?( :get_node )
        return node.get_node( path[ 1..-1 ] )
      end
    elsif path.length == 1
      return node
    end

    nil
  end

  def get_leaf( path )
    node = get_node( path )
    if node.respond_to?( :get_node )
      # Only want a leaf node
      nil
    else
      node
    end
  end

end

