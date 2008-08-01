class TestSingleAlert < Scout::Plugin
  def run
    {:report=>{"fish" => "sticks"}, 
     :alert=>{:subject => "A single Alert", :body => "This is a single alert."},
     :error=>{:subject => "The roof", :body => "The roof is on fire."}}
  end
end
