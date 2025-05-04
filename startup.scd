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
s.options.numWireBufs = 128; // increase this if you get "exceeded number of interconnect buffers" messages
s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
s.options.numOutputBusChannels = 2; // set this to your hardware output channel size, if necessary
s.options.numInputBusChannels = 2; // set this to your hardware output channel size, if necessary
// boot the server and start SuperDirt
s.waitForBoot {
    ~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels

    // load mi-ugens
    load("/home/zazzy/.local/share/SuperCollider/synthdefs/mi-ugens.scd");
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

    ~bus = Bus.audio(s, numChannels:2); // assuming stereo, expand if needed

    ~dirt.orbits[0].outBus = ~bus; // play into that bus.

    // general dirtifying, 

    (
    Ndef(\x, {
	    var control = InBus.ar(~dirt.orbits[1].dryBus, 2).sum;
	    var dirt = InBus.ar(~bus, 2);
	    // AnalogDegrade.ar(AnalogTape.ar(Compander.ar(dirt, control, thresh:0.2, slopeBelow:1, slopeAbove: 0.5, clampTime:0.1, relaxTime:0.1)), 0.1, 0.1, 0.9, 0.9);
	    AnalogTape.ar(Compander.ar(dirt, control, thresh:0.2, slopeBelow:1, slopeAbove: 0.5, clampTime:0.1, relaxTime:0.1));
	    //dirt * (1 - (Amplitude.kr(control) > 0.007).poll.lag(0.01));
	}).play;
    )

    );

    // define global effects for mutable instruments effects
    ~dirt.orbits.do { |x|
	var clouds = GlobalDirtEffect(\global_mi_clouds, [\cloudspitch, \cloudspos, \cloudssize, \cloudsdens, \cloudstex, \cloudswet, \cloudsgain, \cloudsspread, \cloudsrvb, \cloudsfb, \cloudsfreeze, \cloudsmode, \cloudslofi]);
	var verb = GlobalDirtEffect(\global_mi_verb, [\verbwet, \verbtime, \verbdamp, \verbhp, \verbfreeze, \verbdiff, \verbgain]);
	x.globalEffects = x.globalEffects
	  .addFirst(clouds)
	  .addFirst(verb); 
	x.initNodeTree;    
    };                     
    // end define global effects for mutable instruments effects

    };

    s.latency = 0.3; // increase this if you get "late" messages

    // custom synthdefs
    SynthDef(\harmon, {
	| out, sustain=1, freq=440, speed=1, begin=0, end=1, pan, accelerate, offset, volume, spacing=0.0625|
	var env    = Line.ar(1, 0, sustain, doneAction: Done.freeSelf);
	    var amps   = Array.geom(16, 1, spacing);
	var osc    = HarmonicOsc.ar(freq: freq, firstharmonic: 1, amplitudes: amps);
	OffsetOut.ar(out,DirtPan.ar(osc, ~dirt.numChannels, pan, env));
    }).add;

    // custom synthdefs
    SynthDef(\test, {
	| out, sustain=1, freq=440, speed=1, begin=0, end=1, pan, accelerate, offset, volume|
	var env    = Line.ar(1, 0, sustain, doneAction: Done.freeSelf);
	var osc    = SinOsc.ar(freq);
	OffsetOut.ar(out,DirtPan.ar(osc, ~dirt.numChannels, pan, env));
    }).add;

    // custom synthdefs
    SynthDef(\klang, {
	| out, sustain=1, freq=440, speed=1, begin=0, end=1, pan, accelerate, offset, volume=1.0, direction=0.0, envtime=2.0, env1amt = 1.0, env2amt = 1.0, spacing=0.2 |
	    var attack = LinLin.kr(direction, 0.01, 1, 0.01, 1) * envtime;
	    var decay = LinLin.kr(direction,  1, 0.01, 001, 1) * envtime;
	    var env1 = EnvGen.kr(Env.adsr(envtime*attack, envtime*decay, 0.01, 0.01));
	    var instrenv = EnvGen.kr(Env.adsr(envtime*attack, envtime*decay, 0.05, 0.01)) * env2amt;
	    var base = spacing*freq;
	    var beater, sig, trig;
	    spacing = spacing * instrenv;
	    beater = PinkNoise.ar(0.05)*Env.perc(0,0.01).kr;
	    sig = DynKlank.ar(`[
			    Array.geom(10, freq, spacing*(15/8)),
			    Array.exprand(10, instrenv+0.2, 0.5),
			    Array.exprand(10, instrenv+0.1, 9.0)
	    ],beater);
	    trig = 1 - DetectSilence.ar(sig, -60.dbamp);
       /* var env    = Line.ar(1, 0, sustain, doneAction: Done.freeSelf);
	var osc    = SinOsc.ar(freq);*/
	OffsetOut.ar(out,DirtPan.ar(sig*volume, ~dirt.numChannels, pan, Env.cutoff.ar(2, trig)));
    }).add;

    SynthDef(\mpanalog, {
	| out, sustain=1, freq=440, speed=1, begin=0, end=1, pan, accelerate, offset, volume, fc=5000.0, fr=0.0, fe=1.0, fea=0.01, fed=1.0 |
	var env    = Line.ar(1, 1, 4, doneAction: Done.freeSelf);
	    var filtenv = EnvGen.kr(Env.adsr(fea, fed, 0.0, 0.001, 1.0));
	var osc    = BLOsc.ar(freq: freq, pulsewidth: 0.5, waveform: 1);
	    var filter = VADiodeFilter.ar(osc*0.5, fc * (filtenv * fe), fr, 0.0);
	OffsetOut.ar(out,DirtPan.ar(filter, ~dirt.numChannels, pan, env));
    }).add;

    
    StageMaster.activate(numChannels: 2, compThreshold: 0.7, limiterLevel: 1.0, highEndDb: 3.0);

    };
);

