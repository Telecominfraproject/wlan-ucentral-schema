{%-
	let enable = length(gps);
	services.set_enabled("umdns", enable);
        if (!enable)
                return;
%}

# Configure GPS
set gps.@gps[-1].disabled=0
set gps.@gps[-1].adjust_time={{ b(gps.adjust_time) }}
set gps.@gps[-1].baudrate={{ s(gps.baud_rate) }}
