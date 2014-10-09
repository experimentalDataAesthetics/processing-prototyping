s.boot;
s.scope(2);

(
SynthDef("grain", { |out, amp=0.1, freq=440, sustain=0.01, pan|
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(Env.sine(sustain, amp2), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;
)

(
SynthDef("noiseburst", { |out, amp=0.1, sustain=0.01, pan|
	var snd = PinkNoise.ar(1.0);
	var amp2 = amp * AmpComp.ir(1.max(50)) * 0.5;
	var env = EnvGen.ar(Env.sine(sustain, amp2), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;
)



(
SynthDef("grain2", { |out, amp=0.1, freq=440, sustain=0.01, pan|
	var snd = FSinOsc.ar(freq);
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.5;
	var env = EnvGen.ar(Env.perc(0.01, 0.09), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;
)


(
SynthDef("grain3", { |out, amp=0.1, freq=440, sustain=0.01, pan|
	var snd = LFSaw.ar(freq)*0.3*AmpCompA.kr(freq);
	//Basic psychoacoustic amplitude compensation (ANSI A-weighting curve).
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.1;
	var env = EnvGen.ar(Env.perc(sustain, 0.09), doneAction: 2);
	OffsetOut.ar(out, Pan2.ar(snd * env, pan));
}, \ir ! 5).add;
)

(
SynthDef("grain4", { |out=0.0, amp=0.1, freq=440, sustain=0.01 |
	var snd = LFSaw.ar(freq)*0.3*AmpCompA.kr(freq);
	//Basic psychoacoustic amplitude compensation (ANSI A-weighting curve).
	var amp2 = amp * AmpComp.ir(freq.max(50)) * 0.1;
	var env = EnvGen.ar(Env.perc(sustain, 0.09), doneAction: 2);
	OffsetOut.ar(out, snd * env);
}, \ir ! 5).add;
)