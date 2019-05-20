module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end


    def take
      #Person.where(first_name: 'John').take
      self.any? ? self.class.take : false
      
    end


    def where(attributes)
      #Person.where(first_name: 'John').where(last_name: 'Smith')
      self.any? ? self.first.class.where(attributes)

    end


    def not(args)
      #Person.where.not(first_name: 'John')

      self.any? ? self.class.where()
    end
  end
end
