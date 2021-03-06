class Value
  include Mongoid::Document

  field :year,    type: Integer
  field :month,   type: Integer
  field :number,  type: Float
  index :year
  index :month

  validates :year,      presence: true
  validates :month,     presence: true
  validates :number,    presence: true
  validates :model,     presence: true
  validates :scenario,  presence: true
  validates :variable,  presence: true
  validates :point,     presence: true
  
  belongs_to :model, index: true
  belongs_to :scenario, index: true
  belongs_to :variable, index: true
  belongs_to :point, index: true
  
  index([
    [ :model, Mongo::ASCENDING ],
    [ :scenario, Mongo::ASCENDING ],
    [ :variable, Mongo::ASCENDING ]
  ])
   
  private
  
  # if there is an var_id passed then we want that id, if not the params[:variable] is used
  # if there is a number (no) passed then we have params[:year1] and params[:year2] (used for diff values)
  def self.get_values params, var_id=false, no=""
    model_id = Model.find_id_by_name(params[:model])
    scenario_id = Scenario.find_id_by_name(params[:scenario])
    var_id = Variable.find_id_by_name(params[:variable]) if params[:variable]
    
    year = params["year#{no}"]
    month = params["month#{no}"]
        
    v = Value.only(:number, :point_id)
    v = v.where(year: year.to_i) if year # for /propval/Mo/Sc/all/all/Var.Out
    v = v.where(month: month.to_i) if month # for aggregated values
    v.where(model_id: model_id, scenario_id: scenario_id, variable_id: var_id)
  end
  
  def self.get_query params, var_id=false, no=""
    model_id = Model.find_id_by_name(params[:model])
    scenario_id = Scenario.find_id_by_name(params[:scenario])
    var_id = Variable.find_id_by_name(params[:variable]) if params[:variable]
    
    year = params["year#{no}"]
    month = params["month#{no}"]
    
    q = {model_id: model_id, scenario_id: scenario_id, variable_id: var_id}
    q.merge!({year: year.to_i}) if year
    q.merge!({month: month.to_i}) if month
    q
  end
  
  def self.avg(array)
    array.collect(&:number).sum.to_f/array.length
  end
  
  def self.get_aggr(function, values)
    case function
      when "min"
        values.first.number
      when "max"
        values.last.number
      when "avg"
        avg(values)
    end
  end

  def self.grid(values)
    result = Array.new(259) { Array.new(229)}
    values.each do |value|
      result[value.point.x][value.point.y] = value.number
    end
    result
  end
  
  # "value"=>{"point"=>[{"x"=>1.0, "y"=>2.0}, 2.0]}
  def self.grid2(values)
    result = Array.new(259) { Array.new(229)}
    values.find().each do |hash|
      if hash = hash["value"]["point"]
        x = hash.first["x"]
        y = hash.first["y"]
        value = hash.last
        result[x][y] = value
      end
    end
    result
  end
  
  def self.output_hash info, params, data, what="map"
    hash = {}
    hash[what] = info
    hash.merge!({model_name: params[:model], scenario_name: params[:scenario]})
    hash.merge!({ year: params[:year]}) if params[:year]
    hash.merge!({ month: params[:month] }) if params[:month]
    hash.merge!({ function: params[:function] }) if params[:function]
    hash.merge!({ year1: params[:year1], function1: params[:function1], year2: params[:year2], function2: params[:function2]}) if params[:year1] && params[:function1]
    hash.merge!({ year1: params[:year1], month1: params[:month1], year2: params[:year2], month2: params[:month2]}) if params[:year1] && params[:month1]
    hash.merge!({ year1: params[:year1], year2: params[:year2]}) if params[:year1] && params[:year2] && !params[:month1] && !params[:function1]
    hash.merge!({data: data})
  end

end