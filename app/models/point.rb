class Point
  include Mongoid::Document

  field :x,     type: Float
  field :y,     type: Float
  
  validates :x, presence: true
  validates :y, presence: true
  validates :x, uniqueness: {scope: :y} # validates the uniqueness on x and y
  
  has_many :values
  
  def to_hash
    {_id: id, x: x, y: y}
  end

  def full
    "x: #{x} y: #{y}"
  end

end