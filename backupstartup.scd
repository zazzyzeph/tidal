/*
This is an example startup file. You can load it from your startup file
(to be found in Platform.userAppSupportDir +/+ "startup.scd")
*/

(
s.reboot { // server options are only updated on reboot
// configure the sound server: here you could add hardware specific options
// see http://doc.sccode.org/Classes/ServerOptions.html
s.options.numBuffers = 1024 * 256; // increase this if you need to load more samples
s.options.memSize = 8192 * 32; // increase this if you get "alloc failed" messages
s.options.numWireBufs = 64; // increase this if you get "exceeded number of interconnect buffers" messages
s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
s.options.numOutputBusChannels = 2; // set this to your hardware output channel size, if necessary
s.options.numInputBusChannels = 2; // set this to your hardware output channel size, if necessary
// boot the server and start SuperDirt
s.waitForBoot {
~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels
		~dirt.loadSoundFiles("~/tidal/samples/*");   // load samples (path containing a wildcard can be passed in)
// for example: ~dirt.loadSoundFiles("/Users/myUserName/Dirt/samples/*");
// s.sync; // optionally: wait for samples to be read
~dirt.start(57120, 0 ! 12);   // start listening on port 57120, create two busses each sending audio to channel 0

// optional, needed for convenient access from sclang:
(
~d1 = ~dirt.orbits[0]; ~d2 = ~dirt.orbits[1]; ~d3 = ~dirt.orbits[2];
~d4 = ~dirt.orbits[3]; ~d5 = ~dirt.orbits[4]; ~d6 = ~dirt.orbits[5];
~d7 = ~dirt.orbits[6]; ~d8 = ~dirt.orbits[7]; ~d9 = ~dirt.orbits[8];
~d10 = ~dirt.orbits[9]; ~d11 = ~dirt.orbits[10]; ~d12 = ~dirt.orbits[11];

MIDIClient.init;
~midiOut = MIDIOut.newByName("Midi Through", "Midi Through Port-0");
~dirt.soundLibrary.addMIDI(\m8, ~midiOut);

);
};

s.latency = 0.3; // increase this if you get "late" messages


// custom synthdefs
SynthDef(\test, {
    | out, sustain=1, freq=440, speed=1, begin=0, end=1, pan, accelerate, offset, volume|
    var env    = Line.ar(1, 0, sustain, doneAction: Done.freeSelf);
    var osc    = SinOsc.ar(freq);
    OffsetOut.ar(out,DirtPan.ar(osc, ~dirt.numChannels, pan, env));
}).add;

// custom synthdefs
SynthDef(\klang, {
    | out, sustain=1, freq=440, speed=1, begin=0, end=1, pan, accelerate, offset, volume=1.0, direction=0.0, envtime=2.0, env1amt = 1.0, env2amt = 1.4, spacing=1.25 |
	var attack = LinLin.kr(direction, 0, 1, 0, 1);
	var decay = LinLin.kr(direction,  0, 1, 1, 0);
	var env1 = EnvGen.kr(Env.adsr(envtime*attack, envtime*decay, 0.01, 0.01)) * env1amt;
	var env2 = EnvGen.kr(Env.adsr(envtime*attack*2, envtime*decay*2, 0.01, 0.01)) + 0.2 * 0.8 * env2amt;
	var pitch = freq;
	var ratio = [11/8, 5/4, 4/3, 3/2, 5/3, 15/8];
	var base = ratio*freq;
	var beater, sig, trig;
	beater = PinkNoise.ar(0.03)*Env.perc(0,0.01).kr;
	sig = DynKlank.ar(`[
			Array.geom(12, (freq * 0.09) + (env1 * 300), ratio -(ratio*(env2 * 0.2))).postln,
		0.4
	],beater, 1.0, spacing, envtime);
	trig = 1 - DetectSilence.ar(sig, -60.dbamp);
   /* var env    = Line.ar(1, 0, sustain, doneAction: Done.freeSelf);
    var osc    = SinOsc.ar(freq);*/
    OffsetOut.ar(out,DirtPan.ar(sig*volume, ~dirt.numChannels, pan, Env.cutoff.ar(2, trig)));
}).add;

~bus = Bus.audio(s, numChannels:2); // assuming stereo, expand if needed

~dirt.orbits[0].outBus = ~bus; // play into that bus.


(
Ndef(\x, {
	var control = InBus.ar(~dirt.orbits[1].dryBus, 2).sum;
	var dirt = InBus.ar(~bus, 2);
	Compander.ar(dirt, control, thresh:0.05, slopeBelow:1, slopeAbove: 0.5, clampTime:0.05, relaxTime:0.03)
	//dirt * (1 - (Amplitude.kr(control) > 0.007).poll.lag(0.01));
}).play;
)



};
);

