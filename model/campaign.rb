class Campaign
  include Mongoid::Document

  field :name, type: String

  has_many :people
end
