module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end


    def take
      #Collection.where(first_name: 'Jim').take
      self.any? ? self.class.take : false
    end


    def not(attributes)
      #Person.where.not(first_name: 'John');
      attributes["NOT #{attributes.keys.first}"] = attributes.delete attributes.keys.first
      self.class.where(attributes)
    end


    def where(attributes)
      #Collection.where(first_name: 'Jim').where(last_name: 'Halpert')
      self.any? ? self.first.class.where(attributes) : false
    end
  end
end
