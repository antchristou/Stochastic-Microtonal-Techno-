// a aleotoric microtonal self-assembling techno music generator.
// For each output, it will play a full track with varying musical elements, keys, melodic and percussive elements, etc
(
s.waitForBoot {


// roll dice to determine which of the following components of an section are present:
// for intro:
// 1-2 drum elements + one drum fill per 8 bar repetition
// one melodic component
// how many 8 bar repetitions (2-3)
// for chorus/main section: ~3 melodic parts/drum parts
var generateSection = {

		arg minPercElements,maxPercElements,minMelodicElements,maxMelodicElements,bpm;
		var percPbinds;
		var melodicPbinds;
		var totalPbinds;
		var numPercussionElements = rrand(minPercElements,maxPercElements);
		var numMelodicElements = rrand(minMelodicElements,maxMelodicElements);
		var percussionElements = chooseNFromList.value(numPercussionElements,auxPercussion);
		var melElements = chooseNFromList.value(numMelodicElements,melodicElements);
		var tonic = generateTonicFreq.value();
		var fill = ~fills.choose();
		// kick is always present

		percussionElements = percussionElements.add(\k);
		percPbinds = parsePercussion.value(percussionElements,fill);


		melodicPbinds = parseMelodies.value(melElements,tonic,bpm);

		totalPbinds = melodicPbinds ++ percPbinds;
		totalPbinds;

	};
// each drop section has unique drum pattern+riser+other random usual elements
var generateDrop = {

		arg bpm;
		var percPbinds;
		var melodicPbinds;
		var totalPbinds;
		var dropPerc;
		var riser;
		var numPercussionElements = rrand(0,1);
		var numMelodicElements = rrand(2,3);
		var percussionElements = chooseNFromList.value(numPercussionElements,auxPercussion);
		var melElements = chooseNFromList.value(numMelodicElements,melodicElements);
		var tonic = generateTonicFreq.value();


		// kick is always present
		percussionElements = percussionElements.add(\k);
		dropPerc = Pbind(\instrument, \playBuf, \dur, Pseq(~drop_pattern), \buffer, ~clap_sample, \amp, 0.2);

		melodicPbinds = parseMelodies.value(melElements,tonic,bpm);
		// add a riser
		riser = Pbind(\instrument, \riser, \amp, Pseq([0.9]), \bpm,140);

		melodicPbinds = melodicPbinds.add(riser);

		percPbinds = parsePercussion.value(percussionElements,nil);
		percPbinds = percPbinds ++ dropPerc;

		totalPbinds = melodicPbinds ++ percPbinds;
		totalPbinds;

	};

// generates song based upon variable possiblities for sections, etc
// intro: 1-2 8 bar repeats
// then the following structure loops 2-3 times:
// ----
// drop 1 8 bar repeat
// main section: 2-3 8 bar repeats
//
// ----
// followed by outro 1-2 repeats
var generateSong = {
		arg bpm;
		var sections = [];
		var introRepeats = rrand(1,2);
		var dropRepeats = rrand(2,3);
		var mainRepeats;
		var val;
		var runningOffset = 0; // keeps track of length of song for allignment in Ptpar
		// generate intro
		introRepeats.do{
			sections = sections ++ [runningOffset,Ppar(generateSection.value(1,2,0,1,bpm))];
			runningOffset = runningOffset+32;
		};

		dropRepeats.do
		{
			// drop
			mainRepeats = rrand(2,3);
			sections = sections ++ [runningOffset,Ppar(generateDrop.value(2,3,2,3,bpm))];
			runningOffset = runningOffset+32;
			// main section
			mainRepeats.do {
				sections = sections ++ [runningOffset,Ppar(generateSection.value(2,3,3,3,bpm))];
				runningOffset = runningOffset+32;
			}


		};

		introRepeats.do{
			sections = sections ++ [runningOffset,Ppar(generateSection.value(1,2,0,1,bpm))];
			runningOffset = runningOffset+32;
		};


		Ptpar(sections);


	};

var parsePercussion;
var parseMelodies;

// possible elements for perc and melody that get randomly selected via dice rolls
var auxPercussion = [\h,\cl,\glitch];

var melodicElements = [\pad,\bass,\pluck];

// used to choose N random elements from set of possiblities
var chooseNFromList = {

	arg numSelections, listToSearch;
	var listCopy = listToSearch.copy;
	var selectedElements = [];
	numSelections.do {
		var randomElement;

		randomElement = listCopy.choose;
		selectedElements = selectedElements.add(randomElement);
		listCopy.remove(randomElement);
		};

	selectedElements;

	};

var genClapPattern = {
		var clapPattern = [];
		// create basic clap pattern
		(16).do {clapPattern = clapPattern.add(Rest(1));clapPattern = clapPattern.add(1);};

		// corrupt each clap: 1/6 chance of each clap being shifted by one beat forward
		clapPattern.do({
			arg item,i;
			if ((rrand(1,6) == 1) && (i !== 1) && (i % 2 !== 0)) {
				clapPattern.swap(i,i-1);
			}

		});

		clapPattern;

	};


// roll a number 0-23. Even numbers represent normal 12TET keys, odd are microtonal keys and are half way in between. 0 represents C (48 in midi)
var generateTonicFreq = {
		var c_Midi = 48;
		var key = rrand(0,23);
		var tonicFreq;
		var nearest12TET;

		if((key % 2) == 0) {tonicFreq = (c_Midi+(key/2)).midicps}
		// microtonal keys lie half way between the 12TET keys above and below it
		{
			nearest12TET = c_Midi+(key-1);
			tonicFreq = nearest12TET+(((nearest12TET.midicps-((nearest12TET+1).midicps)).abs)/2);

		};
		tonicFreq;


	};

// generates random arpeggio pattern in some key
var generateRandomArp = {
		arg tonicFreq;
		var possiblePitches = [Scale.minor.degreeToFreq(0, tonicFreq, 1),Scale.minor.degreeToFreq(1, tonicFreq, 1),Scale.minor.degreeToFreq(2, tonicFreq, 1),Scale.minor.degreeToFreq(4, tonicFreq, 1),Scale.minor.degreeToFreq(7, tonicFreq, 1)];
		var randArp = Array.fill(4,{possiblePitches.choose});
		randArp;

	};
// samples, pre-composed drum fills are loaded here
~kick_sample = Buffer.read(s, thisProcess.nowExecutingPath.dirname++"/A_Kick_08.wav");
~hhats_sample = Buffer.read(s, thisProcess.nowExecutingPath.dirname++"/A_Hihat_01.wav");
~snare_sample = Buffer.read(s, thisProcess.nowExecutingPath.dirname++"/A_Snare_16.wav");
~clap_sample = Buffer.read(s,thisProcess.nowExecutingPath.dirname++"/TH_Clap_14.wav");
~open_hhats_sample = Buffer.read(s,thisProcess.nowExecutingPath.dirname++"/PMAL_Open_hihat_let_me_know.wav");

~clap_fill_1 = [Rest(7*4),Rest(2.5),0.25,Rest(0.25),0.25,0.25,Rest(0.5)];
~open_hat_fill_1 = [Rest(4*7.75), 0.25,0.25,0.25,0.25];
~open_hat_fill_2 = [Rest(4*7.75), Rest(0.5),0.25,0.25];
~clap_fill_2 = [Rest(4*7.5), 0.25,0.25,0.25,0.25,0.5,0.5];
~clap_fill_3 = [Rest(4*7.75), 0.5,0.5,0.5];

~fills = [~clap_fill_1,~open_hat_fill_1,~open_hat_fill_2,~clap_fill_2,~clap_fill_3];

~drop_pattern = Array.fill(6*8,{0.5})++Array.fill(1.75*16,{0.25})++[1];



/* --- SynthDefs and other asynchronous stuff ---*/
s.sync;


SynthDef(\playBuf,
		{ |buffer, start = 0, dur = 0.25, amp = 1|
	var sig = PlayBuf.ar(2,buffer,startPos: start, loop: 0);
	var env = EnvGen.kr(Env.linen(0.01,dur,0.01,level:amp),doneAction:2);
	Out.ar(0,(sig*env) !2);
	}).add;


SynthDef("riser",
	{ |amp = 1,bpm=140, pan=1|
	var timeFor8Bars = 32/bpm*60;
	var env1 = Env.new([0,1,0.1,0],[timeFor8Bars-1,0.5,1]);
	var riser = WhiteNoise.ar(mul: (env1.kr(doneAction: 2))) * amp;

	// filter
	riser = LPF.ar(riser,Line.kr(0,4000,timeFor8Bars+5));
    Out.ar(0, FreeVerb.ar(in: riser, mix: 0.8, room: 0.8));
}).add;


// SynthDef taken from: "https://www.youtube.com/watch?v=kuSI5MXDPNw"
SynthDef(\glitchRandom, {
	var snd, duration;
	duration = Rand(0.01, 0.04);
	snd = (
		SinOsc.ar(XLine.kr(ExpRand(100,8000), ExpRand(100,8000), duration*ExpRand(0.1,1)))
		*  SinOsc.ar(XLine.kr(ExpRand(100,8000),ExpRand(100,8000),duration*ExpRand(0.1,1)))
	);
	snd = Latch.ar(snd,Impulse.ar(ExpRand(4000,16e3)));
	snd = snd*Env.perc(0.001,duration,curve:Rand(-4,4)).ar(Done.freeSelf);
	snd = snd* -9.dbamp;
	snd = Pan2.ar(snd,Rand(-1,1.0));
	Out.ar(\out.kr(0),snd);
}).add;

SynthDef("sawbass",
	{
		|note=35, amp=0.8,cutoff=350,decay=1|
		var env, audio;
		env = EnvGen.kr(Env.new([0,1,0],[0.001,2],[3,-50]),doneAction:2);
		audio = RLPF.ar(Saw.ar(note,amp),cutoff)*env;
		Out.ar([0,1],audio);
	}
).add;


// synth adapted and changed from bass version here: "https://truthindustri.es/supercollider/2019/01/05/supercollider-track.html"

SynthDef("padSynth", { arg freq_note, gate = 1;
	var ampEnv, freq, gen, fmod, rqmod, snd;
	ampEnv = EnvGen.ar(
		envelope: Env.adsr(3, 3, 0.8, 5, 0.5),
		gate: gate,
		doneAction: 2);

	freq = {freq_note * LFNoise2.kr(1,0.01,1) }!12;
	gen = LFSaw.ar(freq: freq, mul: ampEnv);
	fmod = LFCub.kr(1/12, mul: ampEnv).range(1, rrand(2,16));
	rqmod = LFNoise2.kr(1/8, mul: ampEnv).range(0.1,1.0);
	snd = RLPF.ar(gen, freq * fmod, rqmod, ampEnv);
	Out.ar(0, Splay.ar(snd * ampEnv * 0.3));
}).add;




SynthDef("randomPluck", { arg note, gate = 1;
  var ampEnv, freq, gen, fmod, rqmod, snd;
  ampEnv = EnvGen.ar(
	envelope: Env.adsr(0.1, 0.2, 0, 0.5, 0.4),
    gate: gate,
    doneAction: 2);

  freq = { note * LFNoise2.kr(1,0.01,1) }!12;
 gen = LFSaw.ar(freq: freq, mul: ampEnv);
 fmod = LFCub.kr(1/12, mul: ampEnv).range(1, rrand(1,16));
  rqmod = LFNoise2.kr(1/8, mul: ampEnv).range(0.1,1.0);
  snd = RLPF.ar(gen, freq * fmod, rqmod, ampEnv);
  Out.ar(0, Splay.ar(snd * ampEnv ));
}).add;


parseMelodies = {
		arg melodicElements,tonic,bpm;
		var pad,bass,pluck,melodicPbinds = [];
		var bassPitch;
		var randomArp;
		var rootPitch,thirdPitch,fifthPitch;

		if(melodicElements !== nil)
		{
		melodicElements.do({
			arg item,i;
			// pad chord in key of section
			if(item.asString == "pad") {pad=[1,3,5]}{};
			// random pluck arp
			if(item.asString == "pluck") {pluck=Array.fill(64,{0.5})}{};
			// classic techno rolling bass
			if(item.asString == "bass"){32.do{
				bass = bass.add(Rest(0.25));
				bass = bass.add(0.25);
				bass = bass.add(0.25);
				bass = bass.add(0.25);}}{};

		});
		}{};

		if(pad !== nil) {
			rootPitch = Scale.minor.degreeToFreq(0, tonic, 1);
			thirdPitch = Scale.minor.degreeToFreq(2, tonic, 1);
			fifthPitch = Scale.minor.degreeToFreq(4, tonic, 1);
			melodicPbinds = melodicPbinds.add(
			Pbind(\instrument, "padSynth",\freq_note, Pseq([[rootPitch, thirdPitch, fifthPitch]], 1),
					\amp, 0.5,
					\dur, 30,
					\lfowidth, 0.025,
					\lforate, 2,
					\rq, 0.9))}{};
		if(bass !== nil) {
			bassPitch = Scale.minor.degreeToFreq(0, tonic, -1);
			melodicPbinds = melodicPbinds.add(
			Pbind(\instrument, \sawbass, \dur, Pseq(bass), \note, Pseq([bassPitch],inf), \amp, 0.55);
		)}{};
		if(pluck !== nil) {
			randomArp = generateRandomArp.value(tonic);
			melodicPbinds = melodicPbinds.add(
				Pbind(\instrument, \randomPluck, \dur, Pseq(pluck), \note, Pseq(randomArp,inf), \amp, 0.85);
		)}{};

		melodicPbinds;

	};


parsePercussion = {
		arg percussionElements,fill;
		var kick,clap,glitch,hat,percPbinds = [];
		var fillCoinFlip = rrand(1,3);

		percussionElements.do({
			arg item,i;
			if(item.asString == "k") {kick=Array.fill(8*4,{1})}{};
			// random glitch percussion
			if(item.asString == "glitch"){
				(8*4*4).do {if ([0,1].choose == 0, {glitch = glitch.add(0.25)}, {glitch = glitch.add(Rest(0.25))})};}{};
		    // high hats
			if(item.asString == "h") {(8*4).do{hat = hat.add(Rest(0.5));hat=hat.add(0.5)}}{};
			if(item.asString == "cl"){clap = genClapPattern.value()}{};
		});

		if(kick !== nil) {percPbinds = percPbinds.add(
			Pbind(\instrument, \playBuf, \dur, Pseq(kick), \buffer, ~kick_sample, \amp, 0.20);
		)}{};
		if(glitch !== nil) {percPbinds = percPbinds.add(
			Pbind(\instrument, \glitchRandom, \dur, Pseq(glitch),\amp, 0.5);
		)}{};
		if(hat !== nil) {percPbinds = percPbinds.add(
			Pbind(\instrument, \playBuf, \dur, Pseq(hat), \buffer, ~hhats_sample, \amp, 0.30);
		)}{};
		if(clap !== nil) {percPbinds = percPbinds.add(
			Pbind(\instrument, \playBuf, \dur, Pseq(clap), \buffer, ~clap_sample, \amp, 0.20);
		)}{};

		if(fill !== nil)
		{
		// flip coin if fill will be played in either clap, snare, or open hat
		switch (fillCoinFlip)
		{1} {fill  = Pbind(\instrument, \playBuf, \dur, Pseq(fill), \buffer, ~clap_sample, \amp, 0.2)}
		{2} {fill  = Pbind(\instrument, \playBuf, \dur, Pseq(fill), \buffer, ~snare_sample, \amp, 0.2)}
		{3} {fill  = Pbind(\instrument, \playBuf, \dur, Pseq(fill), \buffer, ~open_hhats_sample, \amp, 0.2)}
		{};

		percPbinds = percPbinds.add(fill);

		}{};
		percPbinds;


	};

/* --- Pattern classes to play your music --- */

t = TempoClock.default; // the default clock
t.tempo = 140/60; // 140 beats per minute


// put on a limiter to prevent generative output from getting too loud (if needed...)
// StageLimiter.activate()
generateSong.value(t.tempo*60).play;
};

"Playing song..".postln;

)