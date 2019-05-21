module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end


    def take
<<<<<<< HEAD
      #Collection.where(first_name: 'Jim').take
=======
>>>>>>> 7fb29ae72b59dd336f8528f388d5db619bd9c6a0
      self.any? ? self.class.take : false
    end


    def not(attributes)
<<<<<<< HEAD
      #Person.where.not(first_name: 'John');
=======
>>>>>>> 7fb29ae72b59dd336f8528f388d5db619bd9c6a0
      attributes["NOT #{attributes.keys.first}"] = attributes.delete attributes.keys.first
      self.class.where(attributes)
    end


    def where(attributes)
<<<<<<< HEAD
      #Collection.where(first_name: 'Jim').where(last_name: 'Halpert')
=======
>>>>>>> 7fb29ae72b59dd336f8528f388d5db619bd9c6a0
      self.any? ? self.first.class.where(attributes) : false
    end
  end
end
