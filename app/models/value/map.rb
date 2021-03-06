class Value::Map < Value
  
  # matrices methods
  
  def self.mapval_var params
    values = get_values(params)
    data = {}
    data[params[:variable]] = grid(values)
    output_hash("val", params, data)
  end
  
  def self.mapval_all params
    data = {}
    Variable.all.each do |var|
     values = get_values(params, var.id)
     data[var.name] = grid(values)
    end
    output_hash("val", params, data)
  end
  
  def self.mapvalaggr_var params
    f = params[:function]
    data = {}
    data[params[:variable]] = []
    
    parameters = {out: "aggr_var", query: get_query(params)} 
    parameters.merge!({finalize: finalize}) if f == "avg"
    
    # map, reduce_avg, reduece_min, reduce_max functions are below and private
    result = Value.collection.map_reduce(map, send("reduce_#{f}"), parameters)
    result = Point.collection.map_reduce(map_point, reduce_point, {out: {reduce: "aggr_var"}});
    
    data[params[:variable]] = grid2(result)

    output_hash("val", params, data)
  end
  
  def self.mapvalaggr_all params
    f = params[:function]
    data = {}
    Variable.all.each do |var|
      data[var.name] = []
      
      parameters = {out: "aggr_all", query: get_query(params, var.id)} 
      parameters.merge!({finalize: finalize}) if f == "avg"
      
      result = Value.collection.map_reduce(map, send("reduce_#{f}"), parameters)
      result.find().each do |hash|
        data[var.name] << hash["value"]
      end
      
    end
    output_hash("val", params, data)
  end
  
  def self.mapdiff_var params
    data = {}
    data[params[:variable]] = []
    
    values1 = get_values(params, false, 1)
    hash1 = values1.group_by(&:point_id)
    
    values2 = get_values(params, false, 2)
    hash2 = values2.group_by(&:point_id)
    
    hash1.each do |key1,values1|
      hash2.each do |key2, values2|
        if key1 == key2
          values1.each_with_index do |val1, index|
            data[params[:variable]] << val1.number - values2[index].number
          end
        end
      end
    end
    output_hash("diff", params, data)
  end

  def self.mapdiff_all params
    data = {}

    Variable.all.each do |var|
      data[var.name] = []
      values1 = get_values(params, var.id, 1)
      hash1 = values1.group_by(&:point_id)
      
      values2 = get_values(params, var.id, 2)
      hash2 = values2.group_by(&:point_id)
    
      hash1.each do |key1,values1|
        hash2.each do |key2, values2|
          if key1 == key2
            values1.each_with_index do |val1, index|
              data[var.name] << val1.number - values2[index].number
            end
          end
        end
      end
    end
    output_hash("diff", params, data)
  end
  
  def self.mapdiffaggr_var params
    data = {}
    data[params[:variable]] = []
    
    values1 = get_values(params, false, 1)
    hash1 = values1.asc(:number).group_by(&:point_id)
    
    values2 = get_values(params, false, 2)
    hash2 = values2.asc(:number).group_by(&:point_id)

    hash1.each do |key1,values1|
      hash2.each do |key2, values2|
        if key1 == key2
          number1 = get_aggr(params[:function1], values1)
          number2 = get_aggr(params[:function2], values2)
          data[params[:variable]] << number1 - number2
        end
      end
    end
    output_hash("diff", params, data)
  end

  def self.mapdiffaggr_all params
    data = {}

    Variable.all.each do |var|
      data[var.name] = []
      
      values1 = get_values(params, var.id, 1)
      hash1 = values1.asc(:number).group_by(&:point_id)
    
      values2 = get_values(params, var.id, 2)
      hash2 = values2.asc(:number).group_by(&:point_id)
      
      hash1.each do |key1,values1|
        hash2.each do |key2, values2|
          if key1 == key2
            number1 = get_aggr(params[:function1], values1)
            number2 = get_aggr(params[:function2], values2)
            data[var.name] << number1 - number2
          end
        end
      end
    end
    output_hash("diff", params, data)
  end
  
  
  private
  
  def self.map_point
    "function() {emit(this._id, {x: this.x, y: this.y});}"
  end
  
  def self.reduce_point
    "function(key, values) {return {point: values};}"
  end
  
  def self.map
    "function() {emit(this.point_id, this.number);}"
  end
  
  def self.reduce_avg
    "function(key, values) {
      var sum = 0;
      values.forEach(function(number) {
        sum += number;
      });
      return {sum: sum, count: values.length};
    }"
  end
  def self.reduce_min
    "function(key, values) {
      var min = values[0];
      values.forEach(function(number) {
        if (number < min) min = number;
      });
      return min;
    }"
  end
  def self.reduce_max
    "function(key, values) {
      var max = values[0];
      values.forEach(function(number) {
        if (number > max) max = number;
      });
      return max;
    }"
  end
  
  def self.finalize
    "function (point, value) {
      return value.sum / value.count;
    }"
  end

end