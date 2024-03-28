---Carter's Delay

function add_parameters()
    onoff = {"off", "on"}
    params:add_option("input_passthrough_onoff", "input passthru", onoff, 2)
    params:set_action("input_passthrough_onoff",function(value)
        osc.send({"localhost","57120"},"/receiver",{1,params:get("input_passthrough")*(value-1)})
    end
    )
    params:add_option("delay_input_onoff", "delay input", onoff, 2)
    params:set_action("delay_input_onoff",function(value)
        osc.send({"localhost","57120"},"/receiver",{2,params:get("delay_input")*(value-1)})
    end
    )
    params:add_option("delay_output_onoff", "delay output", onoff, 2)
    params:set_action("delay_output_onoff",function(value)
        osc.send({"localhost","57120"},"/receiver",{3,value})
    end
    )
    params:add_group("levels",2)
    params:add_control("input_passthrough","input passthru level",controlspec.AMP)
    params:set_action("input_passthrough",function(value)
        osc.send({"localhost","57120"},"/receiver",{1,value})
    end
    )
    params:set("input_passthrough",0.5)
    params:add_control("delay_input","delay input level",controlspec.AMP)
    params:set_action("delay_input",function(value)
        osc.send({"localhost","57120"},"/receiver",{2,value})
    end
    )
    params:set("delay_input",0.5)
    params:bang()
end

function init()
    add_parameters()
end