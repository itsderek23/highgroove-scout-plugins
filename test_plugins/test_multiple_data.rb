class TestMultipleAlerts < Scout::Plugin
  def run
    {:reports=>[{"fish" => "sticks"},
                {"hot" => "dog"}], 
     :alerts=>[{:subject => "One of Multiple Alerts", :body => "This is one of multiple alerts."},
               {:subject => "Two of Multiple Alerts", :body => "This is another one of multiple alerts."}],
     :errors=>[{:subject => "Oh my gawd, an Error", :body => "Everybody hold on."},
               {:subject => "Holy smokes batman", :body => "Your serer is on fire."}]}
  end
end
