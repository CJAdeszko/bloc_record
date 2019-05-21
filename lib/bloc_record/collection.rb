module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end


    def take
      self.any? ? self.class.take : false
    end


    def not(attributes)
      attributes["NOT #{attributes.keys.first}"] = attributes.delete attributes.keys.first
      self.class.where(attributes)
    end


    def where(attributes)
      self.any? ? self.first.class.where(attributes) : false
    end
  end
end
