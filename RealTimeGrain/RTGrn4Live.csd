<CsoundSynthesizer>
<CsOptions>
-odac -d
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 8
nchnls = 2
0dbfs = 1

giCosine ftgen 0,0,8193,9,1,1,90
giSigmoRise ftgen 0,0,8193,19,0.5,1,270,1
giSigmoFall ftgen 0,0,8193,19,0.5,1,90,1

; UDO for interpolated upsampling of time pointer
 gikr = kr

opcode UpsampPhasor, a,k
 kval xin
 setksmps 1
 kold init 0
 if (abs(kold-kval)<0.5) && (abs(kold-kval)>0) then
 reinit interpolator
 elseif abs(kold-kval)>0.5 then; when phasor restarts
 kold = kold-1
 reinit interpolator
 endif
 interpolator:
 aval linseg i(kold), 1/gikr, i(kval), 1/gikr, i(kval)
 rireturn
 kold = kval
 xout aval
endop
 
; audio buffer table for granular effects processing
 giLiveFeedLen = 524288 ; 11.8 seconds buffer at 44.1 
 giLiveFeedLenSec = giLiveFeedLen/sr
 giLiveFeed ftgen 0, 0, giLiveFeedLen+1, 2, 0


instr 1
kFeed chnget "grainFb"
 a1 inch 1
 aFeed chnget "partikkelFeedback"
 a1 = a1 + (aFeed*kFeed)
 iLength = ftlen(giLiveFeed)
 gkstartFollow tablewa giLiveFeed, a1, 0
 ; reset kstart when table is full
 gkstartFollow = (gkstartFollow > (giLiveFeedLen-1) ?
       0 : gkstartFollow)
 ; update table guard point (for interpolation)
 tablegpw giLiveFeed
endin
 
instr 2
kGrainRate chnget "grainRate"
; grain clock
 async  = 0.0
; grain shape
kGrainDur chnget "grainDur" 
kduration = (kGrainDur*1000)/kGrainRate;not sure this is the best way to do it
; different pitch for each source waveform
 kwavfreq chnget "tranScaling"
 kfildur1 = tableng(giLiveFeed) / sr
 kwavekey1 = 1/kfildur1
kwavekey2 = semitone(-5)/kfildur1
 kwavekey3 = semitone(4)/kfildur1
 kwavekey4 = semitone(9)/kfildur1
 awavfm = 0
 ; grain delay time, more random deviation
 ksamplepos1 = 0
 kpos1Deviation randh 0.03, kGrainRate
 ksamplepos1 = ksamplepos1 + kpos1Deviation
 ; use different delay time for each source waveform
 ; (actually same audio, but read at different pitch)
 ksamplepos2 = ksamplepos1+0.05
 ksamplepos3 = ksamplepos1+0.1
 ksamplepos4 = ksamplepos1+0.2
 ; Avoid crossing the record boundary
#define RecordBound(N)#
 ksamplepos$N. limit ksamplepos$N.,
       (kduration*kwavfreq)/(giLiveFeedLenSec*1000),1
 ; make samplepos follow the record pointer
 ksamplepos$N.  =
       (gkstartFollow/giLiveFeedLen) - ksamplepos$N.
 asamplepos$N. UpsampPhasor ksamplepos$N.
 asamplepos$N. wrap asamplepos$N., 0, 1
#
$RecordBound(1)
$RecordBound(2)
$RecordBound(3)
$RecordBound(4)
 ; activate all 4 source waveforms
 iwaveamptab ftgentmp 0, 0, 32, -2, 0, 0, 1,1,1,1,0
 a1 partikkel kGrainRate, 0, -1, async, 0, -1,
  giSigmoRise, giSigmoFall, 0.5, 0.5, kduration, 0.5, -1,
  kwavfreq, 0.5, -1, -1, awavfm,
  -1, -1, giCosine, 1, 1, 1,
  -1, 0, giLiveFeed, giLiveFeed, giLiveFeed, giLiveFeed,
  iwaveamptab, asamplepos1, asamplepos2,
  asamplepos3, asamplepos4,
  kwavekey1, kwavekey2, kwavekey3, kwavekey4, 100
 ; audio feedback in granular processing
 aFeed dcblock a1
 chnset aFeed, "partikkelFeedback"
 outch 1, a1*ampdbfs(-6), 2, a1*ampdbfs(-6)
endin
</CsInstruments>
<CsScore>
i1 0 60000
i2 0 60000

</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
