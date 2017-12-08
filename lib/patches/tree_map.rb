module TreeMapPatch
  def each_node
    super unless empty? && block_given?
  end
end

class TreeMap
  prepend TreeMapPatch
end
