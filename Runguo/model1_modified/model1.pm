ctmc

const int MAX_COUNT;
const int MIN_SENSORS = 3;
const int MIN_POSITIONMING_PROCESSOR = 1;
const int MIN_BLESENDER = 1;
const int MIN_BLERECEIVER = 1;
const int MIN_DEVICE = 1;
const int MIN_SERVER = 1;


const double lambda_y = 1 / (365*24*60*60); //1 year
const double lambda_m = 1 / (30 * 24 * 60 * 60); //1 month
const double lambda_tm = 1 / (2*30*24*60*60); //2 months
const double tau = 1 / 60; //1 min
const double delta_d = 1/(24*60*60);//1 day
const double delta_r = 1/30;//1 second
const double bs_rate = 1/(15*24*60*60);
const double br_rate = 1/(15*24*60*60);

// sensors
module pa
	s : [0..4] init 4; //number of sensors
	[]s>1 -> s * delta_d * 10: (s'=s-1);//failure of a single sensor
endmodule


// positioning server
module pos_server
	m : [0..1] init 1;
	[] m > 0 -> m * lambda_y : (m' = m - 1);
endmodule

// application server
module app_server = pos_server[m=t]
endmodule

// bluetooth sender
module ble_sender
	b : [0..1] init 1;
	[] b > 0 -> b * lambda_tm : (b' = b - 1);
endmodule

// bluetooth receiver
module ble_receiver
	r : [0..3] init 3;
	[] r > 1 -> r * lambda_m : (r' = r - 1);
endmodule

// device
module device
	d : [0..3] init 3;
	[] d > 0 -> d * lambda_tm : (d' = d -1);
endmodule

// connection between sensors and positioning server layer
module pos_pro
	e : [0..2] init 2;
	[] e > 0 & (s < MIN_SENSORS | m < MIN_SERVER ) -> (e' = 0);
	[] e  = 2 & (s >= MIN_SENSORS & m >= MIN_SERVER ) -> lambda_m : (e' = e - 1);
	[pos_pro_reboot] e = 1 & m >= MIN_SERVER-> delta_d: (e' = 2);
endmodule


// connection between acturators and application server
module dis_rad
	x : [0..2] init 2;
	[] x > 0 & (d < MIN_DEVICE | t < MIN_SERVER ) -> (x' = 0);
	[] x = 2 & (d >= MIN_DEVICE & t >= MIN_SERVER ) -> lambda_m : (x' = x - 1);
	[dis_rad_reboot] e = 1 & s >= MIN_SENSORS & m >= MIN_SERVER-> delta_d: (x' = 2);
endmodule


// entralized controller for taking data from pv and then passes to application
module main_pro
	mp : [0..1] init 1;
	count : [0..MAX_COUNT+1] init 0;
	[] mp = 1 ->  delta_d : (mp' = 0);
	// processor completes before time expires
	[timeout] comp -> tau : (count' = 0);
	// before time expires, it does not finish yet
	[timeout] !comp -> tau : (count' = min(count+1, MAX_COUNT+1));
endmodule

// bus connects all
module bus
	// centrailzed processor has been processed data and ready to compute
	comp : bool init true;
	// input processor has been processed data and ready to send
	repa : bool init true;
	// dispatch radio has been processed data and ready to send
	redr : bool init false;

	[pos_pro_reboot] true -> 1:
	// perform a computation if it has already done or
	// it is up and output clear
	(comp' = (comp | (mp=1 & !redr)))
	& (repa' = true)
	// something is malfunction and redr can not function
	& (redr' = !(x = 2 & d >= MIN_DEVICE & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER) & (redr | mp = 1));


	[dis_rad_reboot] true -> 1:
	// perform a computation if true or output is clear
	(comp' = (comp | (repa & mp = 1)))
	& (repa' = (x=2 & s >= MIN_SENSORS & m >= MIN_SERVER & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER & d >= MIN_DEVICE) | (repa & mp=0))
	& (redr' = false);

	[timeout] true -> 1:
	(comp'=(repa & !redr & mp=1))
	&(repa' = (x=2 & s >= MIN_SENSORS & m >= MIN_SERVER & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER & d >= MIN_DEVICE) | (repa & (redr | mp=0)))
	&(redr'=!(x=2 & b >= 1) & (redr | (repa & mp=1)));
endmodule

formula down = (m < MIN_SERVER) | (t < MIN_SERVER) | (b < MIN_BLESENDER) | (r < MIN_BLERECEIVER) | (d < MIN_DEVICE) | (e = 0) | (x = 0) | (s < MIN_SENSORS) | (count = MAX_COUNT + 1);

formula danger = !down & (e = 1 | x = 1);

formula up = !down & !danger;
