class Person
  include Mongoid::Document

  field :email, type: String

  has_and_belongs_to_many :leaders, class_name: 'Person', inverse_of: :followers
  has_and_belongs_to_many :followers, class_name: 'Person', inverse_of: :leaders

  def follow(user)
    if self.id != user.id && !self.leaders.include?(user)
      self.leaders << user
    end
  end

  def unfollow(user)
    self.leaders.delete(user)
  end

  belongs_to :campaign
end
