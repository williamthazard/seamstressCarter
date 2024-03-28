//verison 0.0.1
(
Task(
	{
		Server.default = Server.local;
		o = Server.default.options;
		o.memSize_(2.pow(20));
		ServerOptions.devices;
		o.inDevice_("Scarlett 4i4 USB");
		o.outDevice_("External Headphones");
		s.reboot;
		s.latency_(0.5);
		2.wait;
		~timer = LinkClock.new(2).latency_(Server.default.latency).quantum_(0);
		b = Buffer.alloc(s, s.sampleRate * (~timer.beatDur*512), 1);
		2.wait;
		~micBus = Bus.audio(s, 1);
		~ptrBus = Bus.audio(s, 1);
		2.wait;
		Window.closeAll;
		w = Window("Carter's Delay",Rect(0,Window.availableBounds.height/2,1028,512))
		.background_(Color.black)
		.front
		.onClose_({~topScope.stop; ~bf.free; ~fb.free});
		~color_vals = Array.fill(3,{Array.fill(3,{rrand(0,255)})});
		~bf = Buffer.alloc(s,4096,2);
		~fb = Bus.audio(s,2);
		~topScope = ScopeView(w,
			Rect(0,
				0,
				w.view.bounds.width,
				w.view.bounds.height))
		.bufnum_(~bf.bufnum)
		.server_(Server.default)
		.style_(2)
		.xZoom_(10)
		.yZoom_(10)
		.waveColors_(
			[
				Color.new255(
					~color_vals[0][0],
					~color_vals[1][0],
					~color_vals[2][0]
				),
				Color.new255(
					~color_vals[0][1],
					~color_vals[1][1],
					~color_vals[2][1]
				)
			]
		)
		.background_(Color.black)
		.start;
		Task({
			var delta = ~timer.beatDur/2;
			loop {
				3.do({
					arg i;
					3.do({
						arg j;
						if(
							~color_vals[i][j] == 255,
							{
								~color_vals[i][j] = ~color_vals[i][j]-[0,1].choose
							}
						);
						if(
							~color_vals[i][j] == 0,
							{
								~color_vals[i][j] = ~color_vals[i][j]+[0,1].choose
							}
						);
						if(
							(~color_vals[i][j] < 255) && (~color_vals[i][j] > 0),
							{
								~color_vals[i][j] = ~color_vals[i][j]+[0,1,-1].wchoose([0.5,0.25,0.25])
							}
						);
					});
				});
				~topScope.waveColors_(
					[
						Color.new255(
							~color_vals[0][0],
							~color_vals[1][0],
							~color_vals[2][0]
						),
						Color.new255(
							~color_vals[0][1],
							~color_vals[1][1],
							~color_vals[2][1]
						)
					]
				);
				delta.yield;
			}
		},AppClock
		).play;
		SynthDef.new(\mic, {
			arg in = 0, out = 0, amp = 1;
			var sig;
			sig = SoundIn.ar(in) * amp;
			Out.ar(out, sig);
		}).add;
		SynthDef.new(\micOut, {
			arg in = 0, out = 0, amp = 1;
			var sig;
			sig = SoundIn.ar(in) * amp;
			Out.ar(out, sig);
		}).add;
		SynthDef(\ptr, {
			arg out = 0, buf = 0, rate = 1;
			var sig;
			sig = Phasor.ar(0, BufRateScale.kr(buf)*rate, 0, BufFrames.kr(buf));
			Out.ar(out, sig);
		}).add;
		SynthDef.new(\rec, {
			arg ptrIn = 0, micIn = 0, buf = 0;
			var ptr, sig;
			ptr = In.ar(ptrIn, 1);
			sig = In.ar(micIn, 1);
			BufWr.ar(sig, buf, ptr);
		}).add;
		SynthDef(\gran, {
			arg amp = 0.5, buf = 0, out = 0,
			atk = 1, rel = 1, gate = 1,
			sync = 1, dens = 40,
			baseDur = 0.05, durRand = 1,
			rate = 1, rateRand = 1,
			pan = 0, panRand = 0,
			grainEnv = (-1), ptrBus = 0, ptrSampleDelay = 20000,
			ptrRandSamples = 5000, minPtrDelay = 1000;
			var sig, env, densCtrl, durCtrl, rateCtrl, panCtrl,
			ptr, ptrRand, totalDelay, maxGrainDur;
			env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction: 2);
			densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
			durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand, durRand);
			rateCtrl = rate.lag3(0.5) * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
			panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);
			ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
			totalDelay = max(ptrSampleDelay - ptrRand, minPtrDelay);
			ptr = In.ar(ptrBus, 1);
			ptr = ptr - totalDelay;
			ptr = ptr / BufFrames.kr(buf);
			maxGrainDur = (totalDelay / rateCtrl) / SampleRate.ir;
			durCtrl = min(durCtrl, maxGrainDur);
			sig = GrainBuf.ar(
				2,
				densCtrl,
				durCtrl,
				buf,
				rateCtrl,
				ptr,
				4,
				panCtrl,
				grainEnv
			);
			sig = MoogFF.ar(
				sig * env * amp,
				freq: \cutoff.kr(12000),
				gain: \resonance.kr(1)
			);
			Out.ar(out, sig);
		}).add;
		2.wait;
		~micGrp = Group.new;
		~ptrGrp = Group.after(~micGrp);
		~recGrp = Group.after(~ptrGrp);
		~granGrp = Group.after(~recGroup);
		2.wait;
		a = Synth(\mic, [\in, 0, \out, ~micBus, \amp, 0.5], ~micGrp);
		c = Synth(\micOut, [\in, 0, \out, 0, \amp, 0.5], ~granGrp);
		d = Synth(\micOut, [\in, 0, \out, 1, \amp, 0.5], ~granGrp);
		e = Synth(\micOut, [\in, 0, \out, ~fb.index, \amp, 0.5], ~micGrp);
		f = Synth(\micOut, [\in, 0, \out, ~fb.index+1, \amp, 0.5], ~granGrp);
		h = Synth(\ptr, [\buf, b, \out, ~ptrBus], ~ptrGrp);
		i = Synth(\rec, [\ptrIn, ~ptrBus, \micIn, ~micBus, \buf, b], ~recGrp);
		~panLFOs = Array.fill(16, {0});
		~ampLFOs = Array.fill(16, {0});
		~cutoffLFOs = Array.fill(16, {0});
		~resonanceLFOs = Array.fill(16, {0});
		2.wait;
		16.do({
			arg i;
			~panLFOs.put(i,
				Ndef(i.asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(-1,1)
				})
			);
			~ampLFOs.put(i,
				Ndef(i+16.asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(1,3)
				})
			);
			~cutoffLFOs.put(i,
				Ndef((i+32).asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(500,15000)
				})
			);
			~resonanceLFOs.put(i,
				Ndef((i+48).asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(0,2)
				})
			)
		});
		~af = SynthDef("duoscope", { arg bus, bufnum;
			var z;
			z = In.ar(bus, 2);
			ScopeOut2.ar(z, bufnum);
			Out.ar(0, z);
		}).play(
			target: RootNode(Server.default),
			args: [\bus, ~fb.index, \bufnum, ~bf.bufnum],
			addAction: \addToTail
		);
		~timer.beatDur*4.wait;
		~rates = [1/4,2/6,3/8,4/10,1/2,2/3,3/4,4/5,1,5/4,4/3,3/2,2/1,10/4,8/3,6/2].scramble;
		~durs = 16.collect({arg i; ~timer.beatDur*(i+1)}).scramble;
		~delays = 16.collect({arg i; s.sampleRate*(~timer.beatDur*(i+1))*16}).scramble;
		~g = 16.collect({
			arg n;
			Synth(\gran, [
				\amp, ~ampLFOs[n],
				\buf, b,
				\out, ~fb.index,
				\atk, 1,
				\rel, 1,
				\gate, 1,
				\sync, 1,
				\dens, 1/(~durs[n]*~rates[n]),
				\baseDur, ~durs[n],
				\durRand, 1,
				\rate, ~rates[n],
				\rateRand, 1,
				\pan, ~panLFOs[n],
				\panRand, 0,
				\grainEnv, -1,
				\ptrBus, ~ptrBus,
				\ptrSampleDelay, ~delays[n],
				\ptrRandSamples, s.sampleRate*(~timer.beatDur*((n%8)+1))*2,
				\minPtrDelay, ~delays[n],
				\cutoff, ~cutoffLFOs[n],
				\resonance, ~resonanceLFOs[n]
			], ~granGrp;
			)
		});
		16.do({arg i; ~g[i].set(\amp,~ampLFOs[i])});
		OSCdef(
			\receiver,
			{
				arg msg;
				var voice;
				msg.postln;
				if(
					msg[1] == 1,
					{
						c.set(\amp,msg[2]);
						d.set(\amp,msg[2]);
						e.set(\amp,msg[2]);
						f.set(\amp,msg[2])
					}
				);
				if(
					msg[1] == 2,
					{
						a.set(\amp,msg[2])
					}
				);
				if(
					msg[1] == 3,
					{
						if(
							msg[2] == 1,
							{
								16.do(
									{
										arg i;
										~g[i].set(\amp,0);
									}
								)
							},
							{
								16.do(
									{
										arg i;
										~g[i].set(\amp,~ampLFOs[i])
									}
								)
							}
						)
					}
				);
			},
			\receiver
		);
}).play(AppClock)
)