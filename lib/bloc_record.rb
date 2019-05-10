module BlocRecord

  def self.connect_to(filename)
    @datatbase_filename = filename
  end

  def self.datatbase_filename
    @datatbase_filename
  end
end
