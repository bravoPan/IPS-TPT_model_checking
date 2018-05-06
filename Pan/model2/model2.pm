ctmc

const int MAX_COUNT;
const int MIN_SENSOR = 1;
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
const double delta_r = 1/60;//1 second
const double bs_rate = 1/(15*24*60*60);
const double br_rate = 1/(15*24*60*60);


// ant1
module ant1
	a1: [0..1] init 1;
	[] a1 > 0 -> a1 *  lambda_y: (a1'=a1-1);
endmodule

// processor1
module pos_pro1
	pr1 : [0..2] init 2; // 2 = ok, 1 = transient, 0 = fail
	[] pr1 > 0 & (a1 < MIN_SENSOR | m < MIN_SERVER) -> (pr1' = 0);
	[] pr1 = 2 & (a1 >= MIN_SENSOR & m >= MIN_SERVER) -> delta_r: (pr1' = pr1 - 1);
	[pr1_reboot] (pr1 = 1) & (a1 >= MIN_SENSOR) & (m >= MIN_SERVER) -> delta_d : (pr1' = 2);
endmodule

// ant2
module ant2=ant1[a1=a2]
endmodule

// processor2
module pos_pro2=pos_pro1[pr1=pr2, a1 = a2, pr1_reboot = pr2_reboot]
endmodule

// ant3
module ant3=ant1[a1=a3]
endmodule

// processor3
module pos_pro3 = pos_pro1[pr1=pr3, a1=a3, pr1_reboot = pr3_reboot]
endmodule

// ant4
module ant4=ant1[a1=a4]
endmodule

// processor4
module pos_pro4=pos_pro1[pr1=pr4, a1=a4, pr1_reboot=pr4_reboot]
endmodule

// positioning server
module pos_server
	m : [0..1] init 1;
	[] m > 0 -> m * lambda_y : (m' = m - 1);
endmodule

// application server
module app_server = pos_server[m=t]
endmodule

// bluetooth sende
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

// connection between devices and application server
module dis_rad
	x : [0..2] init 2;
	[] x > 0 & (d < MIN_DEVICE | t < MIN_SERVER ) -> (x' = 0);
	[] x = 2 & (d >= MIN_DEVICE & t >= MIN_SERVER ) -> lambda_m : (x' = x - 1);
	[dis_rad_reboot] (x = 1 & m >= MIN_SERVER) ->  delta_d: (x' = 2);
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

	// first reboot
	[pr1_reboot] true -> 1:
	(comp' = (comp | mp=1 & !redr))
	&(repa'=true)
	& (redr' = !((pr1 > 0  & (pr2 > 0) & (pr3 > 0) & (pr4 > 0)) & a1 >= MIN_SENSOR & x = 2 & d >= MIN_DEVICE & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER) & (redr | mp = 1));

	// second reboot
	[pr2_reboot] true -> 1:
	(comp' = (comp | mp=1 & !redr))
	&(repa'=true)
	& (redr' = !((pr1 > 0  & (pr2 > 0) & (pr3 > 0) & (pr4 > 0)) & a2 >= MIN_SENSOR & x = 2 & d >= MIN_DEVICE & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER) & (redr | mp = 1));

	// third reboot
	[pr3_reboot] true -> 1:
	(comp' = (comp | mp=1 & !redr))
	&(repa'=true)
	& (redr' = !((pr1 > 0  & (pr2 > 0) & (pr3 > 0) & (pr4 > 0)) & a3 >= MIN_SENSOR & x = 2 & d >= MIN_DEVICE & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER) & (redr | mp = 1));

	// fourth reboot
	[pr4_reboot] true -> 1:
	(comp' = (comp | mp=1 & !redr))
	&(repa'=true)
	& (redr' = !((pr1 > 0  & (pr2 > 0) & (pr3 > 0) & (pr4 > 0)) & a4 >= MIN_SENSOR & x = 2 & d >= MIN_DEVICE & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER) & (redr | mp = 1));

	[dis_rad_reboot] true -> 1:
	// perform a computation if true or output is clear
	(comp' = (comp | (repa & mp = 1)))
	& (repa' = ((pr1 > 0  & (pr2 > 0) & (pr3 > 0) & (pr4 > 0)) & x=2 & m >= MIN_SERVER & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER & d >= MIN_DEVICE) | (repa & mp=0))
	& (redr' = false);

	[timeout] true -> 1:
	(comp'=(repa & !redr & mp=1))
	& (repa' = (x=2 & (pr1 > 0  & (pr2 > 0) & (pr3 > 0) & (pr4 > 0)) & m >= MIN_SERVER & t >= MIN_SERVER & b >= MIN_BLESENDER & r >= MIN_BLERECEIVER & d >= MIN_DEVICE) | (repa & (redr | mp=0)))
	& (redr'=!(x=2 & b >= 1) & (redr | (repa & mp=1)));
endmodule

formula down = (m < MIN_SERVER) | (t < MIN_SERVER) | (b < MIN_BLESENDER) | (r < MIN_BLERECEIVER) | (d < MIN_DEVICE) | (pr1 = 0)  | (pr2 = 0) | (pr3 = 0) | (pr4 > 0) | (x = 0) | (count = MAX_COUNT + 1);

formula danger = !down & (pr1 = 1 | pr2 = 1 | pr3 = 1 | pr4 = 1| x = 1);

formula up = !down & !danger;
