require 'socket'
require 'strings'
require'format/printf'
sdcleanup_jsocket_ =: 3 : '0[(sdclose ::0:"0@[ shutdownJ@(;&2)"0)^:(*@#)SOCKETS_jsocket_'
SWREV =: 108  NB. Current EC level

NB. Todo:
NB. allow look at wds from previous round
NB. sizing the screen for smaller screens: put screensize in the mix (ask Chris)


NB. Game states
GSHELLO =: 0  NB. Initial login at station: clear username, clear incrhwmk
GSLOGINOK =: 1  NB. OK to log in
GSAUTH =: 2  NB. Authenticating credentials
NB. All the rest require a login to enable any buttons
GSWORDS =: 3  NB. waiting for words to be entered
GSWACTOR =: 4  NB. waiting for an actor.  Time has not started
GSWSCORER =: 5   NB. Waiting for a scorer.  Time may have started
GSWAUDITOR =: 6
GSWSTART =: 7   NB. Waiting for Start button
GSACTING =: 8  NB. Acting words
GSPAUSE =: 9   NB. Clock stopped during a round
GSSETTLE =: 10  NB. Final scoring actions
GSCONFIRM =: 11  NB. last chance to go back
GSCHANGE =: 12   NB. Changing the round
GSCHANGEWACTOR =: 13  NB. Waiting for actor to decide whether they want a scorer
GSCHANGEWSCORER =: 14   NB. Changing the round in the middle of a turn, waiting for scorer
GSCHANGEWAUDITOR =: 15
GSCHANGEWSTART =: 16   NB. Changing the round in the middle of a turn, waiting to restart
GSGAMEOVER =: 17

NB. Commands from FE/server
0 : 0
HELLO    FE only
LOGIN {name ''}  FE only
DEAL    FE only
TEAMS 'names' ; 'names'
WORDS name ; 5!:5 'words'
RDTIME rnd nsec
AWAYSTATUS name [012] 
TIMERADJ {01} incr name  stop/start, adj
NEXTWORD {-1 0 1} {01}   score, count wd as played
PREVWORD
COMMIT
SCOREADJ incr name
START name
ACT name
ACTOR name {01}  0 to undo
SCORER name {01}  0 to undo
LOGINREQ name gend by BE
LOGINREJ name gend by BE
TICK    gend by BE
SHOWWORD word  gend by BE
)

NB. Info from BE
0 : 0
state
score
actor
scorer
teamup
teams
wordqueue
wordundook
timedisp
roundno
roundtimes
awaystatus  list ; list   status1 status2
wordstatus  table of word ; dqlist
logtext
login
)




FORMBON =: 0 : 0
pc formbon escclose closeok;pn "Bag Of Nouns";
menupop Away;
menu fmawaybrb "Be right back";
menu fmawaygone "Continue without me";
menupopz;
menupop Timer;
menu fmtimerp5 "Add 5 seconds";
menu fmtimerp15 "Add 15 seconds";
menusep;
menu fmtimerm5 "Remove 5 seconds";
menu fmtimerm15 "Remove 15 seconds";
menupopz;
menupop Manage;
menu fmteamdeal "Deal random teams";
menusep;
menu fmstart "Start playing";
menusep;
menupop "Time for taboo...";
menu fmtaboo60 "60 seconds";
menu fmtaboo90 "90 seconds";
menu fmtaboo120 "120 seconds";
menupopz;
menupop "Time for charades...";
menu fmcharades60 "60 seconds";
menu fmcharades90 "90 seconds";
menu fmcharades120 "120 seconds";
menupopz;
menupop "Time for password...";
menu fmpassword60 "60 seconds";
menu fmpassword90 "90 seconds";
menu fmpassword120 "120 seconds";
menupopz;
menupopz;
bin g;
grid shape 1 2;
grid colwidth 0 50; grid colwidth 1 20;
grid colstretch 0 5; grid colstretch 1 2;
 rem left side: the display;
 bin g;
 grid shape 6 1;
 grid rowheight 0 20; grid rowheight 1 10; grid rowheight 2 2; grid rowheight 3 50; grid rowheight 4 50; grid rowheight 5 10;
 grid rowstretch 0 0; grid rowstretch 1 0; grid rowstretch 2 3; grid rowstretch 3 0; grid rowstretch 4 0; grid rowstretch 5 1;
  rem top row: scores & login;
  bin h;
   bin h;
    bin s1;cc fmscoreadj0 edit center;set fmscoreadj0 wh 20 20;bin s1;
    bin v;
     cc fmtmname0 static center;set fmtmname0 minwh 20 20;set fmtmname0 sizepolicy expanding;
     cc fmscore0 static center;set fmscore0 minwh 20 20;set fmscore0 sizepolicy expanding;
    bin z;
   bin z;
   bin s;
   bin v;
     cc fmslowconn static center;set fmslowconn minwh 80 30;set fmslowconn sizepolicy expanding fixed;set fmslowconn text "";
     cc fmlogin combobox;set fmlogin minwh 80 20;;set fmlogin sizepolicy expanding fixed;
     cc fmloggedin static center;set fmloggedin minwh 80 30;set fmloggedin sizepolicy expanding fixed;
   bin z;
   bin s;
   bin h;
    bin v;
     cc fmtmname1 static center;set fmtmname1 minwh 20 20;set fmtmname1 sizepolicy expanding;
     cc fmscore1 static center;set fmscore1 minwh 20 20;set fmscore1 sizepolicy expanding;
    bin z;
    bin s1;cc fmscoreadj1 edit center;set fmscoreadj1 wh 20 20;bin s1;
   bin z;
  bin z;
  rem row 2: progress bar;
  cc fmprogress progressbar 0 60 60;set fmprogress minwh 50 10;set fmprogress sizepolicy ignored fixed;
  rem row 3: general display;
  cc fmgeneral edith;set fmgeneral edit 0;set fmgeneral sizepolicy ignored;
  rem row 4: move to the next word;
  bin h;
   cc fmretire4 button;set fmretire4 sizepolicy expanding;
   bin s;
   cc fmretire3 button;set fmretire3 sizepolicy expanding;set fmretire3 text "Time Expired";
   bin s;
   cc fmretire0 button;set fmretire0 sizepolicy expanding;set fmretire0 text "Don't Know It"; 
   bin s;
   cc fmretire1 button;set fmretire1 sizepolicy expanding;set fmretire1 text "Pass";
   bin s;
   cc fmretire2 button;set fmretire2 sizepolicy expanding;set fmretire2 font "Courier New" 24;set fmretire2 text "Got It";
   bin z;
  rem row 5: general purpose buttons;
  bin h;
   cc fmsieze0 button;set fmsieze0 sizepolicy expanding;set fmsieze0 text "";
   cc fmbagstatus static center;set fmbagstatus text "";
   cc fmsieze1 button;set fmsieze1 sizepolicy expanding;set fmsieze1 font "Courier New" 24;set fmsieze1 text "";
  bin z;
  rem row 6: status line;
  cc fmstatus editm readonly;rem set fmstatus sizepolicy preferred;
 bin z;
 rem right side: event log;
 cc fmlog edith;set fmlog wrap;set fmlog sizepolicy preferred;
bin z;
pas 0 0;
)

formbon_run =: 3 : 0
sdcleanup_jsocket_''
conntoback 4000
NB. Init
loggedin =: 0

wd :: 0: 'psel formbon;pclose'
wd FORMBON
wd 'set fmretire0 text *Don''t',LF,'Know It'
wd 'set fmretire2 text *Got',LF,'It'
wd 'set fmretire3 text *Time',LF,'Expired'
NB. We have to shadow the away buttons ourselves, since we can't query them
screenwh =: ''  NB. 
awaybrb =: awaygone =: 0
winresize 1
wd 'pshow'
smoutput 'screeninfo: ' , wd 'qscreen'
smoutput 'forminfo: ' , wd 'qform'

NB. Start a heartbeat
nextheartbeat =: 6!:1''
wd 'ptimer 50'
NB.?lintsaveglobals
''
)

NB. Called from time to time
NB. y is forcefrac
winresize =: 3 : 0
forcefrac =. y
NB. Remember screensize
oldwh =: screenwh
'screenpx screenwh' =: (4 5,:2 3) { 0 ". wd 'psel formbon;qscreen'
NB. if forcefrac, set frac to 80% (keep width unchanged)
if. forcefrac do. screenfrac =: 0.5 0.8 end.
NB.?lintonly  screenfrac =: 0.5 0.8
NB. if screensize changes, set wh to same proportion of screen as before
if. screenwh -.@-: oldwh do.
smoutput 'screen resized with pmove ' , ": <. (,~ screenwh) * (-:@:-. , ]) screenfrac  NB. scaf
  wd 'pmove ' , ": <. (,~ screenwh) * (-:@:-. , ]) screenfrac
  NB. Set the font size based on screen size
  12 setfont 'set fmtmname0 font "Courier New" * bold'
  64 setfont 'set fmscore0 font "Courier New" * bold'
  24 setfont 'set fmslowconn font "Courier New" * bold'
  10 setfont 'set fmloggedin font "Courier New" *'
  12 setfont 'set fmtmname1 font "Courier New" * bold'
  64 setfont 'set fmscore1 font "Courier New" * bold'
  32 setfont 'set fmgeneral font "Courier New" * bold'
  24 setfont 'set fmretire4 font "Courier New" *'
  24 setfont 'set fmretire3 font "Courier New" *'
  24 setfont 'set fmretire0 font "Courier New" *'
  24 setfont 'set fmretire1 font "Courier New" *'
  24 setfont 'set fmsieze0 font "Courier New" *'
  24 setfont 'set fmbagstatus font "Courier New" *'
  32 setfont 'set fmstatus font "Courier New" * bold'
  10 setfont 'set fmlog font "Arial" *'
end.
NB. remember the proportion
screenfrac =: (2 3 { 0 ". wd 'qform') % screenwh
NB.?lintsaveglobals
''
)

NB. x is desired pointsize when logperinch=72
setfont =: 4 : 0
pts =. 8 >. <. <.@(0.5&+)&.(%&4) x * 72 % {: screenpx
wd y rplc '*';":pts
''
)


formbon_close =: 3 : 0
wd 'ptimer 0;pclose'
)
formbon_cancel =: formbon_close

NB. Here when the background died.  We will keep trying to connect.  Clear the socket to indicate no connection  y is message ID to form, empty to suppress msg
backdied =: 3 : 0
if. sk do.
  sdclose_jsocket_ sk
  sk =: 0
NB. obsolete   if. #y do. wd 'psel formbon;set fmslowconn text *Comm to background failed (',(":y),').' end.
end.
''
)

NB. Try to establish connection to bg.  Return 0 if successful, and set sk.  y is connto in msec
conntoback =: 3 : 0
NB. Connect to the background
sk =: 1 {:: sdsocket_jsocket_ ''
thismachine =: sdgethostbyname_jsocket_ 'localhost'
NB. sdioctl_jsocket_ sk , FIONBIO_jsocket_ , 1  NB. Make socket non-blocking
rc =. sdconnect_jsocket_ sk;(}.thismachine),<8090  NB. start connecting
if. sk e. 2 {:: sdselect_jsocket_ '';sk;'';y do.
  NB. Start with a message to say we arrived.  The response must set all our globals
  Gstate =: GSHELLO  NB. initial state to help ignoring one-shots
  backcmd 'HELLO ', ": {.!.0 ". 'cleargame'
  cleargame=:0  NB. Don't do it again accidentally
  backcmd 'SWREV ' , ": SWREV  NB. Indicate our level
  0
else.
  backdied 0  NB. Indicate no connection
  1
end.

)

heartbeatrcvtime =: _  NB. time previous heartbeat was received
formbon_timer =: 3 : 0
try.
NB. Handle changes to screen size or form position
winresize 0  
if. sk=0 do.
  NB. No bg connection yet, or connection lost - establish one
  if. conntoback 4000 do.
    smoutput 'cannot connect to background, retrying'
  end.
end.
if. sk do.
  if. nextheartbeat < 6!:1'' do.
    backcmd ''   NB. Send heartbeat msg every second
    nextheartbeat =: nextheartbeat + 1.   NB. schedule next heartbeat
  end.
  if. sk e. 1 {:: sdselect_jsocket_ sk;'';'';0 do.
    cmdqueue =. 0$a:   NB. list of commands in this batch
    hdr =. ''   NB. No data, no bytes of header
    while. do.   NB. Read all the commands that are queued
      NB. There is data to read.  Read it all, until we have the complete message.  First 4 bytes are the length
      while. 4>#hdr do.
        'rc data' =. sdrecv_jsocket_ sk,(4-#hdr),00   NB. Read the length, from 2 (3!:4) #data
        if. (rc~:0) +. (0=#data) do. backdied 1 return. end.
        hdr =. hdr , data
        if. 4=#hdr do. break. end.
        if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';4000 do. backdied 2 return. end.
      end.
      hlen =. _2 (3!:4) hdr   NB. Number of bytes to read
      if. 0=hlen do. break. end.  NB. 0-length message is a heartbeat, skip it
NB. obsolete smoutput'data from BE '  NB. scaf
      readdata =. ''
      while. do.
        'rc data' =. sdrecv_jsocket_ sk,(4+hlen),00   NB. Read the data
        if. (rc~:0) +. (0=#data) do. backdied 3 return. end.
        hlen =. hlen-#data  NB. decr count left
        if. hlen <: 0 do. cmdqueue =. cmdqueue , < readdata , hlen }. data break. end.
        readdata =. readdata , data
        if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';4000 do. backdied 4 return. end.
      end.
      if. hlen=0 do. break. end.
      hdr =. hlen {. data
    end.
    wd 'psel formbon'
    heartbeatrcvtime =: 6!:1''  NB. Indicate when we received a heartbeat
    if. #cmdqueue do. proccmds cmdqueue end.  NB. Ignore empty heartbeat
  end.
  NB. See if the connection is slow
end.
catch.
  wd'psel formbon;ptimer 0'
  nextheartbeat =: _
  smoutput'error in timer handler'
  smoutput (<: 13!:11'') {:: 9!:8''
  smoutput 13!:12''
  backdied''   NB. Wait for restart
end.
i. 0 0
)

NB. Send the command in y, prefixed by length
backcmd =: 3 : 0
NB. obsolete if. #y do. smoutput 'backcmd: ' , y end. NB. scaf
NB. Skip this is background is dead
if. sk do.
  senddata =. (2 (3!:4) #y) , y   NB. prefix the data with 4-byte length
  while. #senddata do.
    if. -. sk e. 2 {:: sdselect_jsocket_ '';sk;'';1000 do. backdied 5 return. end.
    rc =. senddata sdsend_jsocket_ sk,0
    if. 0~:0{::rc do. backdied 6 return. end.
    senddata =. (1 {:: rc) }. senddata
  end.
end.
''
)

NB. Decorate string y to attract attention if Glogin is the Actor (0)/Scorer (1)/anybody (2) as flagged in x 
actcolor =: 3 : 0
0 1 2 actcolor y
:
if. ((Gactor;Gscorer) i. <Glogin) e. x do. y =. '<font color=red>' , y , '</font>' end.
y
)

NB. Order of processing state info
statepri =: (;: 'Gswrev Gteamnames Glogin Gawaystatus Groundtimes Gturnblink Gdqlist Gstate Gteams Groundno Gactor Gscorer Gteamup Gwordstatus Glogtext Gwordundook Gbagstatus Gturnwordlist Gwordqueue Gbuttonblink Gscore Gtimedisp')
NB. Process the command queue, which is a list of boxes.  Each box contains
NB. the 5!:5 of a table of state information, as
NB. infotype ; value
NB. We convert the values to internal form and assign them to the names Ginfotype; then
NB. we drive handlers for all the changed values.  We visit the handlers in a priority order.
NB. We collect all the changed values for all commands before we drive any of the handlers
NB. y cannot be empty
proccmds =: 3 : 0
initing =. Gstate=GSHELLO  NB. set if this is the very first call
NB. Turn each input into a boxed table of name ; value
NB. Run the tables together, keep the latest of each
cmds =. ((~.@[ ,. ({:/. {:"1))~ {."1) ; ".&.> y
NB. Assign values to names
({."1 cmds) =: {:"1 cmds
if. initing do. Gbuttonblink =: '' [ Gturnblink =: 0 end.  NB. turn off one-shots, which are sticky, if in initial state

NB. Start with the lowest modified state, and then all handlers till the end.  May be none
wd 'psel formbon'
for_h. statepri (<./@:i. }. [) {."1 cmds do. ('hand',>h)~ '' end.
''
)

handGswrev =: 3 : 0
if. Gswrev > SWREV do.
  wd 'mb info mb_ok "Update your software" *Your code is out of date.  Go to Tools|Package Manager to update it, then restart Bag of Nouns'
  backdied''
  wd :: 0: 'psel formbon;pclose'
end.
)

handGteamnames =: 3 : 0
wd '01' ('set fmtmname',[,' text *',])&> Gteamnames
''
)


NB. The handlers, in priority order.  They all return empty
handGlogin =: 3 : 0
loggedin =: 3 <: #Glogin
if. Glogin -: '*' do.
  wd 'set fmloggedin text *Login in progress...'
elseif. loggedin do.
  wd 'set fmloggedin text *' , Glogin , ' is logged in here'
else.
  wd 'set fmloggedin text *Login by selecting' , ((Gstate=GSWORDS) # ' or entering') , ' your name'
end.
''
)

handGawaystatus =: 3 : 0
''
)

handGroundtimes =: 3 : 0
(3 # 'taboo';'charades';'password') ([: wd 'set fm' , >@[ , ":@{.@] , ' checked ' , ":@{:@])"_1 ,/ Groundtimes (]"0/ ,"0 =/) 60 90 120
''
)

handGturnblink =: 3 : 0
if. Gturnblink do.
  NB. Play an attention-getting animation
  for_color. '0123456789ABCDEF' {~ 20 6 ?@$ 16 do.
    fsize =. 192 + ? 64
    wlen =. 4 + ?5
    wchars =. 'RING' [^:(?2) wlen ((?@$ #) { ]) '!@#$%^&*()AgdrwTGdfsvDFHJYTSIGFTBSDL'
    wd 'set fmgeneral font "Courier New" ' , (":fsize) , ' bold;set fmgeneral text *<font color=#' , color , '>',wchars,'</font>'
    wd 'msgs'
    6!:3 (0.06)
  end.
  32 setfont 'set fmgeneral font "Courier New" * bold'  NB. Reset for normal use
  Gturnblink =: 0  NB. It shouldn't come twice, but take no chances
end.
''
)

handGdqlist =: 3 : 0
''
)

NB. Button-enable based on state
NB. rows are buttons, columns are state. c1 is always 1, l1 only if logged in. a is 'not actor', A is 'actor', la is 'logged in not actor', S01 is 'scorer in rds 0&1' 
NB.             HELLO LOGINOK AUTH WORDS WACTOR WSCORER WAUD WSTART ACTING PAUSE SETTLE CONFIRM CHANGE CHANGEWACT CHANGEWSCO CHANGWAUD CHANGEWSTART GAMEOVER
statetoenable =: ;:;._2 (0 : 0)
fmawaybrb        l0     l0     l0   l1     l1     l1      l1     l1    l1    l1     l1     l1     l1      l1          l1        l1     l1         c0
fmawaygone       l0     l0     l0   l1     l1     l1      l1     l1    l1    l1     l1     l1     l1      l1          l1        l1     l1         c0
fmtimerp5        l0     l0     l0   l0     l0     l0      l0     l0    l1    l1     l1     l0     l0      l0          l0        l0     l0         c0
fmtimerp15       l0     l0     l0   l0     l0     l0      l0     l0    l1    l1     l1     l0     l0      l0          l0        l0     l0         c0
fmtimerm5        l0     l0     l0   l0     l0     l0      l0     l0    l1    l1     l1     l0     l0      l0          l0        l0     l0         c0
fmtimerm15       l0     l0     l0   l0     l0     l0      l0     l0    l1    l1     l1     l0     l0      l0          l0        l0     l0         c0
fmteamdeal       l0     l0     l0   l1     l0     l0      l0     l0    l0    l0     l0     l0     l0      l0          l0        l0     l0         c0
fmcharades60     l0     l0     l0   l1     l0     l0      l0     l0    l0    l0     l0     l0     l0      l0          l0        l0     l0         c0
fmcharades90     l0     l0     l0   l1     l0     l0      l0     l0    l0    l0     l0     l0     l0      l0          l0        l0     l0         c0
fmscoreadj0      l0     l0     l0   l0     l0     l0      l0     l0    l0    l0     l1     l1     l0      l0          l0        l0     l0         c0
fmlogin          c0     l1     l1   c1     c1      a       a     as    as    as     as     as     as      as           a         a      a         c0
fmscoreadj1      l0     l0     l0   l0     l0     l0      l0     l0    l0    l0     l1     l1     l0      l0          l0        l0     l0         c0
fmretire0        l0     l0     l0   l0     l0     l0      l0     l0   S01   S01      A     l0     l0      l0          l0        l0     l0         c0
fmretire1        l0     l0     l0   l0     l0     l0      l0     l0   S01   S01      A     l0     l0      l0          l0        l0     l0         c0
fmretire2        l0     l0     l0   l0     l0     l0      l0     l0     S     S      A     l0     l0      l0          l0        l0     l0         c0
fmsieze0         l0     l0     l0   l1      T     A       A      S     l1     S      A      A      A       A           A         A      S         c0
fmsieze1         l0     l0     l0   l0      T     l1      la     AS    Sw    Sw     Aw     Aw     l0       A          l1        la     AS         c0
)

getawaystg =: 3 : 0
if. 2 = #Gteams do.
  awaystg =. , ; ('BRB for acting team: ';'Away for acting team: ') (*@#@] # '<br>' , [ , ])&.> Gawaystatus ;:^:_1@-.&.> (-. Gteamup) { Gteams   NB. Away players for the acting team
  awaystg =. awaystg , , ; ('BRB for inactive team: ';'Away for inactive team: ') (*@#@] # '<br>' , [ , ])&.> Gawaystatus ;:^:_1@-.&.> (Gteamup) { Gteams   NB. Away players for the acting team
  if. #awaystg do. awaystg =. '<font color=blue><br>' , awaystg , '</font>' end.
else. awaystg =. ''
end.
awaystg
)

NB. y is prefix string for nonempty
getoldwords =: 3 : 0
if. #Gturnwordlist do.
  rwords =. 'Words last turn: ', _2 }. ; ,&', '&.> <@(1&{:: , ('';' (late)';' (foul)') {::~ (1 1;0 2) i. 2&{)"1 Gturnwordlist  NB. word text, with late words indicated
  rwords =. y , '<small>' , rwords , '</small>'
else. rwords =. ''
end.
rwords
)

handGstate =: 3 : 0
NB. Set conditional enables
'c0 c1 l0 l1' =. ":"0 , (1,loggedin) *./ 0 1
'a s as la A S AS S01' =. ":"0 (3 5 # 1,loggedin) *. (Glogin -: Gactor) (-.@[ , -.@] , -.@[ , +: , [ , ] , +. , ((Groundno<2) *. ])) (Glogin -: Gscorer)
T =. ":"0 (<Glogin) e. Gteamup {:: Gteams
NB. Select the column; get mask to discard 'Sw', which we do later
enmsk =. ('Sw';'Aw') -.@:e.~ envals =. (>:Gstate) {"1 statetoenable
NB. Set all the enables
({."1 statetoenable) ([: wd 'set ',[,' enable ',".@])&>&(enmsk&#) envals
NB. Set display for the variable buttons
wd 'set fmsieze0 text *' , (1;((0{::buttoncaptions0) i. Gstate)) {:: buttoncaptions0
wd 'set fmsieze1 text *' , (1;((0{::buttoncaptions1) i. Gstate)) {:: buttoncaptions1
if. Gstate -.@e. GSSETTLE,GSCONFIRM do. wd 'set fmscoreadj0 text "";set fmscoreadj1 text ""' end.
NB. Get away-status string
awaystg =. getawaystg''
NB. Get the string to show the words from last turn, if we are in the states where that is meaningful
if. Gstate e. GSWACTOR,GSWSCORER,GSWAUDITOR,GSWSTART do. rwords =. getoldwords '' else. rwords =. '' end.
NB. Display the status line; if the general line is known from the state, do it too
select. Gstate
case. GSHELLO do. text =. 'Catching up'
case. GSLOGINOK do. text =. 'OK to login'
case. GSAUTH do. text =. 'Waiting for authorization'
case. GSWORDS do. text =. 'Players are entering words'
case. GSWACTOR do.
  upplrs =. 2 {. (Gteamup {:: Gteams) -. 1 {:: Gawaystatus  NB. top 2 from teamup, but not if away
  wd 'set fmgeneral text *Up for ',(Gteamup {:: Gteamnames),': ' , (actcolor^:(-:&Glogin) 0 {:: upplrs) , (' then '&,^:(*@#) (1 {:: upplrs)) , awaystg , '<br><br>' , rwords
  text =. 'Need player for ' , (Groundno {:: 'Taboo';'Charades';'Password'), ' from ' , Gteamup {:: Gteamnames
case. GSWSCORER do.
  upplr =. > {. ((-. Gteamup) {:: Gteams) -. 1 {:: Gawaystatus  NB. top from teamup, but not if away
  wd 'set fmgeneral text *Click to score' , ((*@#upplr) # ' (',(actcolor^:(-:&Glogin) upplr),' is up next for ',((-.Gteamup) {:: Gteamnames),')'),'.' , awaystg , '<br><br>' , rwords
  text =. 'Need someone to score for ' , Gactor
case. GSWAUDITOR do.
  if. Glogin-:Gactor do. wd 'set fmgeneral text *' , actcolor 'If you''re sure you won''t make a mistake, you can play without an auditor.'
  else.
    upplr =. > {. ((-. Gteamup) {:: Gteams) -. 1 {:: Gawaystatus  NB. top from teamup, but not if away
    wd 'set fmgeneral text *Click to audit' , ((*@#upplr) # ' (',(actcolor^:(-:&Glogin) upplr),' is up next for ',((-.Gteamup) {:: Gteamnames),')'),'.' , awaystg , '<br><br>' , rwords
  end.
  text =. 'Accepting an auditor for ' , Gactor , ' (optional)'
case. GSWSTART do.
  if. Glogin-:Gscorer do.
    if. Glogin-:Gactor do. wd 'set fmgeneral text *' , (actcolor 'Start the clock.') , awaystg
    else. wd 'set fmgeneral text *' , actcolor 'Start the clock when told to.'
    end.
  elseif. Glogin-:Gactor do. wd 'set fmgeneral text *' , (actcolor 'When you are ready, tell the scorer to start the clock.') , awaystg
  else. wd 'set fmgeneral text *' , awaystg , ((*@#awaystg) # '<br><br>') , rwords
  end.
  text =. Gscorer , ' starts the clock for ' , Groundno {:: 'Taboo';'Charades';'Password'
case. GSACTING do.
  text =. Gactor , ' is playing ' , (Groundno {:: 'Taboo';'Charades';'Password') , ' and ' , ((Gactor -.@-: Gscorer) # Gscorer , ' is ') , 'scoring'
case. GSPAUSE do. text =. 'Clock stopped - ' , Gactor , ' is playing ' , (Groundno {:: 'Taboo';'Charades';'Password')
case. GSSETTLE do. text =. Gactor , ' is finalizing scores'
case. GSCONFIRM do.
  text =. ((*Gtimedisp) {:: 'End of turn';'Round change') , '.  Remember the words.'
case. GSCHANGE do.
  wd 'set fmgeneral text *' , (Glogin-:Gactor) # 'Round change!  Next round: ',(Groundno {:: 'Taboo';'Charades';'Password'),'.  ' , actcolor 'Are you ready?'
  text =. 'Changing to ' , Groundno {:: 'Taboo';'Charades';'Password';'Scotch'
case. GSCHANGEWACTOR do.
  wd 'set fmgeneral text *' , (Glogin-:Gactor) # actcolor 'Do you want a scorer for the ',(Groundno {:: 'Taboo';'Charades';'Password'),' round?'
  text =. 'Does ' , Gactor , ' need a scorer for ',(Groundno {:: 'Taboo';'Charades';'Password'),'?' 
case. GSCHANGEWSCORER do.
  upplr =. > {. ((-. Gteamup) {:: Gteams) -. 1 {:: Gawaystatus  NB. top from teamup, but not if away
  wd 'set fmgeneral text *Click to score' , ((*@#upplr) # ' (',(actcolor^:(-:&Glogin) upplr),' is up next for ',((-.Gteamup) {:: Gteamnames),')'),'.' , awaystg
  text =. 'Need someone to score for ' , Gactor
case. GSCHANGEWAUDITOR do.
  if. Glogin-:Gactor do. wd 'set fmgeneral text *' , actcolor 'If you''re sure you won''t make a mistake, you can play without an auditor.'
  else.
    upplr =. > {. ((-. Gteamup) {:: Gteams) -. 1 {:: Gawaystatus  NB. top from teamup, but not if away
    wd 'set fmgeneral text *Click to audit' , ((*@#upplr) # ' (',(actcolor^:(-:&Glogin) upplr),' is up next for ',((-.Gteamup) {:: Gteamnames),')'),'.' , awaystg
  end.
  text =. 'Accepting an auditor for ' , Gactor , ' (optional)'
case. GSCHANGEWSTART do.
  if. Glogin-:Gscorer do.
    if. Glogin-:Gactor do. wd 'set fmgeneral text *' , actcolor 'Start the clock.'
    else. wd 'set fmgeneral text *' , actcolor 'Start the clock when told to.'
    end.
  elseif. Glogin-:Gactor do. wd 'set fmgeneral text *' , actcolor 'When you are ready, tell the scorer to start the clock.'
  else. wd 'set fmgeneral text *'
  end.
  text =. Gscorer , ' starts the clock for ' , Groundno {:: 'Taboo';'Charades';'Password'
case. GSGAMEOVER do. text =. 'Game Over'
case. do. text =. ''
end.

wd 'set fmstatus text *', text
''
)
buttoncaptions0 =: (<@;)`(<@(,&a:))`(<@(,&a:))"1 ".&.> |: ;:@(LF&(('*'&(I.@:=)@])}));._2 (0 : 0)
GSWORDS 'Enter Words*From Clipboard' 'W'
GSWACTOR 'I will play*and score' 'ACTOR '';1;0'
GSWSCORER 'Undo!  I don''t*want to play'    'ACTOR '';0;0'
GSWAUDITOR 'Play without*auditor'   'AUDITOR '''
GSWSTART 'Start the clock'  'ACT 0'
GSACTING 'Stop the clock'  'TIMERADJ 0;0;'''
GSPAUSE 'Start the clock'  'TIMERADJ 1;0;'''
GSSETTLE 'See all*the words'   'S'
GSCONFIRM 'Everyone*agrees'   'COMMIT 0'
GSCHANGE 'Yes, proceed' 'PROCEED 0'
GSCHANGEWACTOR 'I don''t need*a scorer'   'ACTOR '';1;0'
GSCHANGEWSCORER ''    ''
GSCHANGEWAUDITOR 'Play without*auditor'   'AUDITOR 0$a.'
GSCHANGEWSTART 'Start the clock'  'ACT 0'
)
buttoncaptions1 =: (<@;)`(<@(,&a:))`(<@(,&a:))"1 ".&.> |: ;:@(LF&(('*'&(I.@:=)@])}));._2 (0 : 0)
GSWACTOR 'I will play, but*need a scorer' 'ACTOR '';1;1'
GSWSCORER 'I will score'  'SCORER '';1'
GSWAUDITOR 'I will audit'  'AUDITOR '''
GSWSTART 'Undo'  'SCORER '';0'
GSACTING 'Undo last score' 'PREVWORD 0'
GSPAUSE 'Undo last score'  'PREVWORD 0'
GSSETTLE 'Undo last score'  'PREVWORD 0'
GSCONFIRM 'See all*the words'   'S'
GSCHANGE '' ''
GSCHANGEWACTOR 'I need*a scorer'   'ACTOR '';1;1'
GSCHANGEWSCORER 'I will score'  'SCORER '';1'
GSCHANGEWAUDITOR 'I will audit'  'AUDITOR '''
GSCHANGEWSTART 'Undo!  I don''t*want to score'  'SCORER '';0'
)

handGteams =: 3 : 0
wd 'set fmlogin items' , ;@:((' "' , ,&'"')&.>) (<'Logout'),~^:loggedin (/: tolower&.>) ; Gteams
wd 'set fmlogin select ' , ": >: # ; Gteams  NB. Make selection blank
wd 'set fmstart enable ' , ": loggedin *. (Gstate=GSWORDS) *. (2=#Gteams)
''
)

handGroundno =: 3 : 0
wd 'set fmprogress min 0;set fmprogress max *',": (1 >. #;Gteams) [^:(Gstate=GSWORDS) Groundno { Groundtimes  NB. Set progress limits depending on state
)

handGactor =: 3 : 0
''
)

handGscorer =: 3 : 0
''
)

handGteamup =: 3 : 0
''
)

handGwordstatus =: 3 : 0
if. Gstate=GSWORDS do.
  wd 'set fmprogress value *',": #Gwordstatus
  if. 0=#;Gteams do. wd 'set fmgeneral text *Waiting for first login'
  elseif. #missing =. (;Gteams) -. {."1 Gwordstatus do.
    wd 'set fmgeneral text *Players who have not entered words:<br>' , ;:^:_1 missing
  else. wd 'set fmgeneral text *All players have entered words'
  end.
end.
''
)

handGlogtext =: 3 : 0
wd 'set fmlog text *',Glogtext
''
)

handGbagstatus =: 3 : 0
wd 'set fmbagstatus text *', ": Gbagstatus
''
)


handGturnwordlist =: 3 : 0
if. Gstate = GSCONFIRM do.   NB. display words in CONFIRM state, where they might be changed by a SCOREMOD without changing state
  NB. See who is away
  awaystg =. ; ('BRB: ';'Away: ') (*@#@] # '<br>' ,~ [ , ;:^:_1@])&.> Gawaystatus
  if. #awaystg do. awaystg =. '<font color=blue>' , awaystg , '</font><br>' end.
  NB. Extract the words that are being retired
  rwords =. (#~ 1 <: (2;1)&{::"1) (#~ a: ~: 2&{"1) Gturnwordlist , Gwordqueue  NB. Remove unacted & unretired words.  wordqueue must be empty
  if. #rwords do.
    rwords =. <@(1&{:: , ('';' (late)';' (foul)') {::~ (1 1;0 1) i. 2&{)"1 rwords  NB. word text, with late words indicated
    wd 'set fmgeneral text *' , awaystg , ((*Gtimedisp)  # '<font color=green>Round change.</font><br>') , ((Glogin-:Gactor) # actcolor 'Click ''Everyone agrees'' when score agreed.<br>') , 'Words: ', _2 }. ; ,&', '&.> rwords
  else.
    wd 'set fmgeneral text *' , awaystg , ((*Gtimedisp)  # '<font color=green>Round change.</font><br>') , ((Glogin-:Gactor) # actcolor 'Click ''Everyone agrees'' when score agreed.<br>') , 'No words were scored.'
  end.
end.
''
)


APSinstructions =: _2 ]\ <;._2 (0 : 0)
<small>Play in order.  Word turns from red to blue when scored:</small>
<small>Play in order.  Word turns from red to blue when scored:</small>
Clock is stopped - wait
<font color=red>Clock is stopped - restart it when discussion is over</font>
<small>Handle the word in red (usually with Time Expired), or use big buttons to change scores.</small>
<small>Handle the word in red (usually with Time Expired), or use big buttons to change scores.</small>
)
handGwordqueue =: 3 : 0
if. Gstate e. GSACTING,GSPAUSE,GSSETTLE do.
  if. Glogin -: Gactor do.
    isscorer =. Glogin -: Gscorer  NB. scoring too?
    NB. Special display for the actor or actor/scorer.  Prefix it with instructions
    NB. Format the words we have acted this round (if any)
    if. #twds =. (<Groundno) (] #~ (= {."1)) Gturnwordlist do.
      ftwds =. 1 {"1 twds
      scoretag =. ((0 _1;_1 0;1 1;0 0;0 1;0 2) i. 2 {"1 twds) { ' (didn''t know it)';' (passed -1)';' (scored +1)';' (time expired)';' (guessed late)';' (foul)';''
      ftwds =. ('<small><font color=blue>' , ,&'</font></small>')&.> ftwds
      ftwds =. ftwds ,&.> scoretag
    else. ftwds =. 0$a:
    end.
    NB. Format the word queue (should always be some in an acting state)
    if. #wwds =. Gwordqueue do.
      fwwds =. 1 {"1 wwds
      scoretag =. ((0 _1;_1 0;1 1;0 0;0 1;0 2) i. 2 {"1 wwds) { ' (didn''t know it)';' (passed -1)';' (scored +1)';' (time expired)';' (guessed late)';' (foul)';''
      fwwds =. (Gstate~:GSPAUSE) (('<big><font color=red>' , ,&'</font></big>')&.>@{. , ('<small>' , ,&'</small>')&.>@}.) fwwds
      fwwds =. fwwds ,&.> scoretag
    else. fwwds =. 0$a:
    end.
    NB. Select words to show, format as list.  During turn leave space for one word from turnwordlist, possibly empty; when settling show all
    showwds =. ({:^:(Gstate~:GSSETTLE) ftwds) , fwwds
    showwds =. ('<ul>' , ,&'</ul>') ;@:(('<li>' , ,&'</li>')&.>) showwds  NB. Make each word a list element, and the whole thing a list
    instr =. (<((GSACTING,GSPAUSE,GSSETTLE) i. Gstate),isscorer) {:: APSinstructions
    wd 'set fmgeneral text *' , instr , showwds
    if. Gstate=GSSETTLE do. wd 'set fmgeneral scroll max' end.
  else.
    NB. For non-actors, indicate DQ status for the word, if there is still time
    if. Gstate e. GSACTING,GSPAUSE do.
      if. #Gwordqueue do.
        NB. See who is DQd from the acting team
        dqplrs =. (((<0;0 1) { Gwordqueue) -:"1 (2 {."1 Gdqlist)) # 2 {"1 Gdqlist 
        dqtext =. 'DQ: '&,^:(*@#) ;:^:_1 dqplrs -. ((-. Gteamup) {:: Gteams) , <Gactor 
      else. dqtext =. ''
      end.
      if. (Gstate=GSPAUSE) *. (Glogin -: Gscorer) do.
        dqtext =. dqtext , ((*@# dqtext) # '<br>') , (actcolor 'Start the clock when the discussion is over.') , '<br>'
      end.
      NB. Give the scorer/auditor a summary of the scoring actions performed this round
      if. (<Glogin) e. Gscorer;Gauditor do.
        if. #twds =. (<Groundno) (] #~ (= {."1)) Gturnwordlist do.
          ftwds =. 1 {"1 twds
          scoretype =. (0 _1;_1 0;1 1;0 0;0 1;0 2) i. 2 {"1 twds
          ftwds =. a: (I. scoretype e. 0 1 3 6)} ftwds
          scoretag =. scoretype { ' (didn''t know it)';' (passed -1)';' (scored +1)';' (time expired)';' (guessed late)';' (foul)';''
          ftwds =. ftwds ,&.> scoretag
        else. ftwds =. 0$a:
        end.
        showwds =. ('<ul>' , ,&'</ul>') ;@:(('<li>' , ,&'</li>')&.>) ftwds
      else. showwds =. ''
      end.
      wd 'set fmgeneral text *' , dqtext, showwds
      if. 0=#dqtext do. wd 'set fmgeneral scroll max' end.
    else.
      wd 'set fmgeneral scroll min;set fmgeneral text *' , (*Gtimedisp) {:: ('Turn is over.  ' , Gactor , ' is finishing the scoring.');'Scoring break, turn will continue'  NB. Reset scroll after scoring
    end.
  end.
end.
''
)

handGwordundook =: 3 : 0
if. Gstate e. GSACTING,GSPAUSE,GSSETTLE,GSCONFIRM do.
  en =. Gwordundook *. ((Gstate e. GSACTING,GSPAUSE) *. Glogin-:Gscorer) +. ((Gstate e. GSSETTLE,GSCONFIRM) *. Glogin-:Gactor)
  wd 'set fmsieze1 enable ',":loggedin*.en
end.
''
)

handGbuttonblink =: 3 : 0
NB. Turn off the blink in all states, to make sure it isn't left on
if. Gbuttonblink -: '' do.
  24 setfont 'p<set fmretire>q< font "Courier New" *;>'  (8!:2) i. 5
elseif. (Gstate e. GSACTING,GSPAUSE,GSSETTLE,GSCONFIRM) do.
  NB. Blink only in word-scoring states
  buttonno =. 0 1 2 3 4 4 {~ (_2 ]\ 0 _1  _1 0  1 1  0 0  0 1  0 2) i. Gbuttonblink
  NB. In case we have back-to-back blinks, turn off the first one
  24 setfont 'p<set fmretire>q< font "Courier New" *;>'  (8!:2) (i. 5) -. buttonno
  32 setfont 'p<set fmretire>q< font "Courier New" * bold;>' (8!:2) buttonno
end.
''
)

handGscore =: 3 : 0
wd 'set fmscore0 text ',(":0 { Gscore),';set fmscore1 text ',":1 { Gscore
''
)

handGtimedisp =: 3 : 0
if. Gstate e. GSWACTOR,GSWSTART,GSACTING,GSPAUSE,GSSETTLE,GSCHANGE do. wd 'set fmprogress value *',": Gtimedisp end.
wd 'set fmretire3 enable ' , ": (Gstate=GSSETTLE) *. (Glogin-:Gactor)
wd 'set fmretire4 enable ' , ": ((Gstate e. GSACTING,GSPAUSE) *. (Glogin-:Gscorer)) +. (Gstate=GSSETTLE) *. (Glogin-:Gactor)
wd 'set fmretire4 text *', (*Gtimedisp) {:: ('Foul/',LF,'Late');'Foul'

''
)

NB. Display modal dialog and then suppress slow msg
wdmodal =: 3 : 0
res =. wd y
heartbeatrcvtime =: _   NB. Stifle message while this form was displayed
res
)

NB. Button processors
LOGINCHARS =: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
formbon_fmlogin_select =: 3 : 0
if. 'Logout'-:fmlogin do. fmlogin=:''  NB. Convert Logout to empty
elseif. (Gstate -.@e. GSHELLO,GSLOGINOK,GSAUTH,GSWORDS) *. (<fmlogin) -.@e. ; Gteams do.
  wdmodal 'mb info mb_ok "Too Late" "The game has started.  Only old logins are allowed"'
  NB. Because an entry causes Qt to add the name to the list, refresh the list
  wd 'set fmlogin items' , ;@:((' "' , ,&'"')&.>) (<'Logout'),~^:loggedin (/: tolower&.>) ; Gteams
  wd 'set fmlogin select ' , ": >: # ; Gteams  NB. Make selection blank
  i. 0 0 return.
else.
  NB. Audit login name: >:3 chars, only valid alphas, no spaces
  if. (3>#fmlogin) +. (12<#fmlogin) +. # fmlogin -. LOGINCHARS do.
    wdmodal 'mb info mb_ok "Invalid Login" "Must be 3-12 letters and numbers, no spaces"'
    i. 0 0 return.
  end.
end.
backcmd 'LOGIN ''',fmlogin,''''
awaybrb =: awaygone =: 0
wd 'set fmawaygone value 0;set fmawaybrb value 0'
backcmd 'AWAYSTATUS ''' , fmlogin , ''';0'  NB. remove awaystatus on login
i. 0 0
)

NB. Return adjustment, 0 if none or invalid
auditscoreadj =: 3 : 0
sgn =. ('-' = {. y) { 1 _1
y =. (({.y) e. '+-') }. y  NB. discard sign
if. 1 ~: #y do. y=. 10
else. y =. '0123456789' i. y
end.
if. y = 10 do.
  wdmodal 'mb info mb_ok "Bad change" "Must be 1 digit with optional sign"'
  0
else.
  y * sgn
end.
)
formbon_fmscoreadj0_button =: 3 : 0
adj =. ": adjn =.  auditscoreadj fmscoreadj0
if. adjn do. backcmd 'SCOREADJ 0;',adj,';''',Glogin,'''' end.
i. 0 0
)
formbon_fmscoreadj1_button =: 3 : 0
adj =. ": adjn =.  auditscoreadj fmscoreadj1
if. adjn do. backcmd 'SCOREADJ 1;',adj,';''',Glogin,'''' end.
i. 0 0
)
formbon_fmawaybrb_button =: 3 : 0
awaygone =: 0 [ awaybrb =: -. awaybrb
wd 'set fmawaygone value 0;set fmawaybrb value ' , ": awaybrb
backcmd 'AWAYSTATUS ''' , Glogin , ''';' , ": awaybrb  NB. 0=here, 1=brb, 2=away
i. 0 0
)
formbon_fmawaygone_button =: 3 : 0
awaybrb =: 0 [ awaygone =: -. awaygone
wd 'set fmawaybrb value 0;set fmawaygone value ' , ": awaygone
backcmd 'AWAYSTATUS ''' , Glogin , ''';' , ": 2 * awaygone  NB. 0=here, 1=brb, 2=away
i. 0 0
)
formbon_fmtimerp5_button =: 3 : 0
backcmd 'TIMERADJ ',(":Gteamup),';5;''' , Glogin , ''''  NB. team#, #seconds, login
i. 0 0
)
formbon_fmtimerp15_button =: 3 : 0
backcmd 'TIMERADJ ',(":Gteamup),';15;''' , Glogin , ''''
i. 0 0
)
formbon_fmtimerm5_button =: 3 : 0
backcmd 'TIMERADJ ',(":Gteamup),';_5;''' , Glogin , ''''
i. 0 0
)
formbon_fmtimerm15_button =: 3 : 0
backcmd 'TIMERADJ ',(":Gteamup),';_15;''' , Glogin , ''''
i. 0 0
)
formbon_fmteamdeal_button =: 3 : 0
backcmd 'DEAL 0'
i. 0 0
)
formbon_fmstart_button =: 3 : 0
backcmd 'START ''' , Glogin , ''''
i. 0 0
)


formbon_fmtaboo60_button =: 3 : 0
backcmd 'RDTIME 0 60'  NB. rd#, # seconds
i. 0 0
)
formbon_fmtaboo90_button =: 3 : 0
backcmd 'RDTIME 0 90'
i. 0 0
)
formbon_fmtaboo120_button =: 3 : 0
backcmd 'RDTIME 0 120'
i. 0 0
)
formbon_fmcharades60_button =: 3 : 0
backcmd 'RDTIME 1 60'  NB. rd#, # seconds
i. 0 0
)
formbon_fmcharades90_button =: 3 : 0
backcmd 'RDTIME 1 90'
i. 0 0
)
formbon_fmcharades120_button =: 3 : 0
backcmd 'RDTIME 1 120'
i. 0 0
)
formbon_fmpassword60_button =: 3 : 0
backcmd 'RDTIME 2 60'  NB. rd#, # seconds
i. 0 0
)
formbon_fmpassword90_button =: 3 : 0
backcmd 'RDTIME 2 90'
i. 0 0
)
formbon_fmpassword120_button =: 3 : 0
backcmd 'RDTIME 2 120'
i. 0 0
)



formbon_fmretire0_button =: 3 : 0
backcmd 'NEXTWORD 0 _1'   NB. score, retirewd
i. 0 0
)
formbon_fmretire1_button =: 3 : 0
backcmd 'NEXTWORD _1 0'
i. 0 0
)
formbon_fmretire2_button =: 3 : 0
backcmd 'NEXTWORD 1 1'
i. 0 0
)
formbon_fmretire3_button =: 3 : 0
backcmd 'NEXTWORD 0 0'
i. 0 0
)
formbon_fmretire4_button =: 3 : 0
backcmd (*Gtimedisp){::'NEXTWORD 0 2';'NEXTWORD 0 1'
i. 0 0
)

formbon_fmsieze0_button =: 3 : 0
if. 1 < #capt =. buttoncaptions0 {::~ 2 ; (0{::buttoncaptions0) i. Gstate do.
  NB. Replace ' with 'login'
  backcmd (({.~ , ('''' , Glogin) , }.~) i.&'''')^:(''''&e.) capt
elseif. 1 = #capt do.
  ('formbon_sieze',capt)~''   NB. 1-character string is a local verb
end.
i. 0 0
)
formbon_fmsieze1_button =: 3 : 0
if. 1 < #capt =. buttoncaptions1 {::~ 2 ; (0{::buttoncaptions1) i. Gstate do.
  NB. Replace ' with 'login'
  backcmd (({.~ , ('''' , Glogin) , }.~) i.&'''')^:(''''&e.) capt
elseif. 1 = #capt do.
  ('formbon_sieze',capt)~''   NB. 1-character string is a local verb
end.
i. 0 0
)

NB. Get words from clipboard
DIRCHARS =: ''',-/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '
formbon_siezeW =: 3 : 0
try.
  wds =. , wd'clippaste'
  wds =. <;._2 LF ,~ wds -. CR
catch.
  wds =. 0$a:
end.
wds =. deb&.> (e.&DIRCHARS # ])&.> wds  NB. Remove weird characters, excess blanks
wds =. wds -. a:  NB. Remove empty words
if. 0=#wds do. wdmodal 'mb info mb_ok "No words" "You didn''t put any words on the clipboard."' return. end.
if. 15<#wds do. wdmodal 'mb info mb_ok "Too many words" "You have more than 15 words."' return. end.
if. 30 < >./ #@> wds do. wdmodal 'mb info mb_ok "Too long" "One of your words is longer than 30 characters."' return. end.
if. 'ok' -: wdmodal 'mb query mb_ok "Is this word list OK?" *', ; ,&LF&.> wds do.
  backcmd 'WORDS ''',Glogin,''' ,&< ' , 5!:5 <'wds'
end.
)

NB. The display for a single word
FORM1wd =: 0 : 0
cc fmwdrb?c0 radiobutton; set fmwdrb?c0 caption ""; cc fmwdrb?c1 radiobutton group; set fmwdrb?c1 caption ""; cc fmwdrb?c2 radiobutton group; set fmwdrb?c2 caption "";
cc fmwdrb?c3 radiobutton group; set fmwdrb?c3 caption "";cc fmwdrb?c4 radiobutton group; set fmwdrb?c4 caption "";cc fmwdrb?c5 radiobutton group; set fmwdrb?c5 caption ""; cc fmwdst? static; set fmwdst? font "Courier New" 16;
)
NB. The display for the grid
FORMSETTLE =: 0 : 0
pc formsettle escclose closeok owner;pn "Your words for this round";
bin vg;
grid shape 7;
cc st0 static; set st0 text "Late";cc st1 static; set st1 text "Foul";cc st2 static; set st2 text "Time";cc st3 static; set st3 text "???";
cc st4 static; set st4 text "Pass";cc st5 static; set st5 text "Got";cc wd static; set wd text "";
%2
bin z;
cc ok button; set ok caption "OK";
bin z;
)

NB. Display the scoring form at the end
BUTTdisps =: 0 1;0 2;0 0;0 _1;_1 0;1 1  NB. disp for Late Time ??? Pass Got
formbon_siezeS =: 3 : 0
NB. get the words of interest: turnwords and wordqueue, but only for the current round
if. #dispwds =. Gturnwordlist , Gwordqueue do.
  rdx =. I. (<Groundno) = 0 {"1 dispwds   NB. Indexes of modifiable words
  NB. Create the form
  buttons =. FORM1wd ;@:((rplc '?' ; ":)"_ 0) rdx
  wd FORMSETTLE rplc '%2';buttons
  NB. Based on the scoring (if any), create the form, for the scoring and the words
  wdbutt =. BUTTdisps i. (<rdx;2) { dispwds
  if. #wdbutt =. (#~  6 ~: {."1) wdbutt ,. rdx do. wd ;@:(('set fmwdrb',":@],'c',' value 1;' ,~ ":@[)/"1) wdbutt end.
  rdx ([: wd 'set fmwdst' , ":@[ , ' text *' , ])&>  (<rdx;1) { dispwds
  NB. Display the form
  wd 'pshow'
end.
)
formsettle_ok_button =: 3 : 0
NB. Extract the data from the form
if. #checks =. (#~ (<,'1') = {:"1) wdq do.
  buttsels =. (([: _9&". 6 }. _2 }. ]) , _9&".@{:)@> (#~  ('fmwdrb' -: 6&{.)@>) {."1 checks
  buttsels =. ({. ; BUTTdisps {~ {:)"1 buttsels  NB. convert to index ; disposition
  NB. Remove the values that have not changed
  if. #buttsels =. (2 {"1 Gturnwordlist , Gwordqueue) (] #~ ({:@] -.@-: ({~ {.))"_ 1) buttsels do.
    NB. Send the new values to the background
    backcmd 'SCOREMOD ' , 5!:5 <'buttsels'
  end.
end.
NB. Close the word form
formsettle_cancel''
)
formsettle_cancel =: 3 : 0
heartbeatrcvtime =: _   NB. Stifle message while this form was displayed
wd 'psel formsettle;pclose'  NB. selection may have been lost
)
formsettle_close_button =: formsettle_cancel

cocurrent 'z'
NB. language extensions

NB. Type y on the terminal
display =: (i.0 0)"_ ((1!:2) 2:)


NB. Conjunction: u unless y is empty; then v
butifnull =: 2 : 'v"_`u@.(*@#@])'
NB. Alternative form without gerund.  This turns out to be slower
NB. butifnull =: [. ^: ((] *@#) ` ((]."_) ^: ((] 0&=@#)`])))

NB. Conjunction: u unless x is empty; then v
butifxnull =: 2 : 'v"_`u@.(*@#@[)'

NB. Empties: select one according to context
NIL =: ''   NB. required argument to niladic function
NILRET =: ''   NB. return from function with no explicit result
NILRETQUIET =: i. 0 0  NB. return to J, without printing
NB. verb to return empty list, to discard the actual returned value
null =: ''"_

NB. Adverb.  Do u, but skip it if y is null
ifany =: ^: (*@#@])
NB. Same if x is nonnull
ifanyx =: ^: (*@#@[)

NB. bivalent =: [. ^: (1:`(].@]))  NB. u v y if monad, x u (v y) if dyad
NB. u v y if monad, x u (v y) if dyad
bivalent =: 2 : 'u^:(1:`(]v))'

NB. Logical connectives - evaluates right to left and avoids
NB.  unnecessary evaluations
and =: 2 : 'u@[^:] v'
or =: 2 : 'u@[^:(-.@]) v'

NB. Like e. dyadic, but using tolerant comparison.  Faster on lists with identical first elements
in0 =: e.!.0

NB. Like i. dyadic, but using tolerant comparison.  Faster on lists with identical first elements
index0 =: i.!.0

NB. Adverb.  Apply u and join the results end to end
endtoend =: 1 : ';@:(<@u)'
NB. Adverb.  Apply u on keys, join results end-to-end
keyetoe =: 1 : ';@:(<@u/.)'
NB. Conjunction, like Cut but put results end-to-end
cutetoe =: 2 : ';@:(<@u;.n)'

NB. Conjunctions to use for readability
xuvy =: 2 : 'u v'
yuvx =: 2 : '(u v)~'
uy_vx =: 2 : 'v~ u'
ux_vy =: 2 : '(v~ u)~'
vy_ux =: 2 : 'u~ v'
vx_uy =: 2 : '(u~ v)~'

NB. m is name of noun; n is default value; result is the value of
NB. the noun if it is defined, otherwise n
butifundef =: 2 : 'if. 0 > 4!:0 <m do. n else. ". m end.'

NB. y is anything; result is a ist of 0 y s
noneof =: ($0)&(]"0 _)

NB. Adverb.  Monad, converts y to rank u by adding axes
enrank =: 1 : ',: ^: ((0&>.)@(m&-)@#@$)'

NB. x is column number; we open column x of y
ocol =: >@:({"1)

NB. like {., but limited to the length of y
leading =: ((<. #) {. ])"0 _
NB. like - ux_vy {., but limited to the length of y
trailing =: (-@(<. #) {. ])"0 _

NB. Adverb.  Install x in the path given by m
store =: 1 : 0
:
if. #m do. (< x (}.m)store ({.m){::y) ({.m)} y else. x end.
)

NB. Adverb.  Applies u within boxes of y, without changing boxing of x
iny =: 1 : '<@(u xuvy >)"_ 0'

NB. Atomic-representation utilities
NB. y is string name of verb, result is AR of verb
arverb =: <@,
NB. y is noun, result is AR of noun
arnoun =: <@((,'0')&(,&<))
NB. (adverb) m is conjunction (in string form), x is AR, y is AR
NB. Result is AR of x m y
arconj =: 1 : '<@((,&<~ ,)&m)@,"0'
NB. y is a list of 3 ARs, result is AR of their fork
arfork =: <@((,'3')&(,&:<))
NB. x is AR, y is AR, result is AR for (x y)
arhook =: <@((,'2')&(,&:<))@,"0

NB. Adverb.  m describes an item to be fetched, as
NB. spec[!spec]...[!]
NB.  where spec is
NB.  [prefix?]expr
NB.   where prefix is a character string which (boxed) becomes
NB.     the prefix, or a number, which tells how many trailing
NB.     items of the incoming prefix to keep.  Default is _, meaning
NB.     keep the whole prefix
NB.   and expr is an expression which is evaluated to give a selector.
NB.     This selector (after being boxed) is applied to the input at that
NB.     level.  All '^' and '^:' appearing in the input are replaced by the current
NB.     path, razed with '_' after each item.  If '^:' appears in the
NB.     input, the current path is cleared after all the replacements.
NB.     After that, the path is extended by adding the token following the
NB.     first '^' or '^:', if there is one.
NB.  The specs are processed left-to-right.  When '!' is encountered,
NB.  the result of the selection is unboxed (and subsequent selections are
NB.  applied to each atom after it is unboxed)
NB. Ex: 'IUNIT?^:ORDER!^:HISTORY!^STATUS!^STS' fstr

NB. x is one unboxed spec string, y is incoming path (a list of boxed strings), result is path to use here
inputpath =. ( ({.~ i.&'?') ux_vy ((<@[) ` (0&". ux_vy trailing) @. (*./@(e.&'0123456789')@[)) ) ^:('?'&e.@[)
NB. x is one unboxed spec string, y is path to use here, result is path to use at next level
outputpath =. ( ;: ux_vy ( -.@((<'^:')&e.) ux_vy #  ,  ({~ >:@(i.&1)@(e.&((,'^');'^:')))@[ ) ) ^: ('^'&e.@[)
NB. x is one boxed spec string, y is (accumulated path[;garbage])
NB. Result is (path for next level;path to use at this level)
accumpath =. ([ (outputpath ,&< ]) inputpath)&>  {.
NB. y is spec string (boxed in pieces), result is prefix string to use at each level
buildpaths =. ;@:(,&'_'&.>)&.>@:({:"1)@:((accumpath/\.)&.(,&(<0$a:)))&.|.
NB. x is boxed pieces of the spec string, y is list of boxed paths
NB. result is x with substitutions made for ^ and ^:
substpath =. (<;._2@(,&'^')@(#~ -.@(|.!.0)@('^:'&E.))@((}.~ >:@(i.&'?'))^:('?'&e.))@> ux_vy (<@;@}:@,@,.))"0
NB. y is the spec string, result is selection info, with substitutions
NB. performed (and '!' indicating unboxing)
brktospecs =. (substpath buildpaths) @ (<;.1~ (+. |.!.1)@('!'&=))
NB. y is the spec string.  Result is
NB. a list of ARs, one for each spec and one for each !
arofspecs =. ('&' arconj&(arverb '{')@arnoun@(".&.>))`((arverb '>')"_) @. ((<,'!')&-:) "0 @: brktospecs
NB. Convert each component to an AR, and then roll up the ARs.  We go from
NB. the right-hand end, but we add each element to the left of the accumulated
NB. AR, so this has the effect of reversing the order and left-grouping the
NB. result
fstrar =: ('@' arconj)~/ @: arofspecs f.
fstr =: 1 : '(fstrar m)`:6'


NB. Conjunction.  Apply u at the cell indicated by n
applyintree =: 2 : 0
if. #n do. ((u applyintree (}.n)) L:_1 ({.n){y) ({.n)} y else. u y end.
:
NB. The rank is s,0 where s is the surplus of x-rank over y-rank.  This causes
NB. the cells of y to be matched up with the largest appropriate blocks x  This
NB. is necessary because it is impossible to change the shape of the values being modified
if. #n do. (x u applyintree (}.n) L:_ _1"(0 (>.,[) x -&(#@$) a) (a =. ({.n){y)) ({.n)} y else. x u y end.
)

NB. y is character string list of entry-point names
NB. x is the level number at which we should publish the entry points (default _1, 'z')
NB. we publish these names in the locale at position x in the path
publishentrypoints =: 3 : 0
_1 publishentrypoints y
:
NB. The rhs of the assigment below interprets the names as gerunds
path =. '_' (,,[) x {:: (<,'z') ,~^:(-.@*@#@]) 18!:2 current =. 18!:5 ''
l =. ,&path^:('_'&~:@{:)&.> ;: y
r =. ,&('_' (,,[) > current)@(({.~ i:&'_')@}:^:('_'&=@{:))&.> ;: y
NB. The gerund assignment requires more than one name, so duplicate the last:
('`' , ;:^:_1 (, {:) l) =: (, {:) r
)

NB. 18!:4 without side effects
setlocale =: 18!:4

NB. Cuts
onpiecesbetweenm =: 2 : '(u ;._1)@:(n&,)'
onpiecesbetweend =: 2 : '(u>)"_1 <;._1@(n&,)'
onpiecesbetween =: 2 : '(u onpiecesbetweenm n) : (u onpiecesbetweend n)'
onpiecesusingtail =: 1 : 'u ;._2'

NB. Conjunction.  u is verb, n (or [x] v y) is arg to { to select s = desired portion of y
NB. The result of x u s (if dyad) or u s (if monad) replaces s
onitem =: 2 : '(u bivalent (n&{)) n} ]'
onitemm =: 2 : 'n}~ u@:(n&{)'
onitemd =: 2 : '(u (n&{)) n} ]'

NB. Debugging support
NB. conjunction: execute u after displaying n
afterdisplaying =: 2 : 'u [ display@(n"_)'

NB. Initialize a global, but not if it's already been initialized
NB. Example: 'name' initifundef 5
initifundef =: (, ('_'&([,],[))@(>@(18!:5)@(0&$)) ) ux_vy ((4 : '(x) =: y')^:(0:>(4!:0)@<@[))

NB. Timing
ts =: 6!:2 , 7!:2@]

NB. conjunction: execute u, counting time.  n is a descriptive string
showtime =: 2 : 0
display 'Starting ' , n
starttime =. 6!:0 NIL
u y
if. 0: display 'Exiting ' , n , ' time=' , ": 0 12 30 24 60 60 #. (6!:0 NIL) - starttime do. end.
:
display 'Starting ' , n
starttime =. 6!:0 NIL
x u y
if. 0: display 'Exiting  ' , n , ' time=' , ": 0 12 30 24 60 60 #. (6!:0 NIL) - starttime do. end.
)

NB. List the combinations of x things taken from y things
comb =: [: ; [: (,.&.> <@;\.)/  >:@-~ [\ i.@]

NB. associative power: like ^: but uses repeated doubling
NB. u is applied between v copies of y
NB. requires y > 0
apow =: 2 : 0
(v"_ y) u/@(u~@]^:(I.@|.@#:@[))"0 _ y
)

NB. Conjunction: we use this for things that may need to be 'rank' if J
NB. starts reexecuting frequently, but are " till then.  The nature of these things
NB. must be that they perform I/O, so we inhibit them if they are null
rnk =: 2 : 'u"v ifany'

NB. Conjunction: like ", but guarantees no reevaluation of cells
rank =: 2 : 0
ru =. 0 { v
if. ru < 0 do. ru =. 0 >. (# $ y) + ru end.
r =. ru <. # $ y
f =. (-r) }. $ y
fi =. 0
if. fl =. */ f do.
  r =. 0 $ a:
  while. fi < fl do.
    tx =. ,/ <"0 f #: fi   NB. index to frame
    r =. r , < u ( (< tx) { y)
    fi =. >: fi
  end.
  > f $ r
else.
  f $ ,: u ((-r) {. $y) $ head , y
end.
:
'lru rru' =. 1 2 { 3 $&.|. v
if. lru < 0 do. lru =. 0 >. (# $ x) + lru end.
if. rru < 0 do. rru =. 0 >. (# $ y) + rru end.
lr =. lru <. # $ x  NB. ranks to use
rr =. rru <. # $ y
lfs =. (-lr) }. $ x NB. frames
rfs =. (-rr) }. $ y
fr =. lfs <.&# rfs  NB. rank of common part of frame
if. -. lfs -:&(fr&{.) rfs do. 13!:8 (8) end.
f =. (fr {. lfs) , lfs ,&(fr&}.) rfs  NB. the longer of the frames
fi =. 0
if. fl =. */ f do.
  r =. 0 $ a:
  while. fi < fl do.
    tx =. ,/ <"0 f #: fi   NB. index to frame
    r =. r , < ( (< ($lfs) {. tx) { x) u ( (< ($rfs) {. tx) { y)
    fi =. >: fi
  end.
  > f $ r
else.
  if. -. */ lfs do. x =. ((-lr) {. $x) $ head , x end.
  if. -. */ rfs do. y =. ((-rr) {. $y) $ head , y end.
  f $ ,: x u y
end.
)

NB. Conjunction: x if y is nonzero, otherwise nullverb
butonlyif =: 2 : 0
if. n do. u else. ($0)"_ end.
:
if. n do. u else. ($0)"_ end.
)

FormalLevel =: 2 : 0
 m=. 0{ 3&$&.|. n
 ly=. L. y  if. 0>m do. m=.0>.m+ly end.
 if. m>:ly do. u y else. u FormalLevel m&.> y end.
   :
 'l r'=. 1 2{ 3&$&.|. n
 lx=. L. x  if. 0>l do. l=.0>.l+lx end.
 ly=. L. y  if. 0>r do. r=.0>.r+ly end.
 b=. (l,r)>:lx,ly
 if.     b-: 0 0 do. x    u FormalLevel(l,r)&.> y
 elseif. b-: 0 1 do. x    u FormalLevel(l,r)&.><y
 elseif. b-: 1 0 do. (<x) u FormalLevel(l,r)&.> y
 elseif. 1       do. x u y
 end.
)

FormalFetch =: >@({&>/)@(<"0@|.@[ , <@]) " 1 _
cocurrent 'z'
NB. Routines for keyed lists (lists of key ; data [, data])

NB. y is list of key ; data
NB. If x is given, it is the list of key indices
NB. Result is the (boxed) keys
keyskld =: ({"1"_)
keyskl =: 0&keyskld : keyskld f.

NB. y is list of key ; data
NB. If x is given, it is the list of data columns
NB. Result is the (boxed) data items only, using the shape of x for each row
datakld =: ({"1)
datakl =: 1&datakld : datakld f.

NB. x is set of keys, y is keyed list, u is key columns
NB. Records with those keys are deleted
delkl_colsu =: 1 : '-.@:((e.!.0)~ xuvy (m&keyskld)) # ]'
delkl =: 0 delkl_colsu f.

NB. x is set of keys, y is keyed list, u is column numbers of key
NB. Records with those keys are kept, the others are deleted
keepkl_colsu =: 1 : '(e.!.0)~ xuvy (m&keyskld)   #  ]'
keepkl =: 0 keepkl_colsu f. NB. default version with key in position 0

NB. x is set of keys, y is keyed list, u is column numbers of key
NB. Result is index of x into }: keys, but _1 if there is no match
indexkl_colsu =: 1 : '(#@])  (((_1"_)`(I.@:=)`])})  (m&keyskld uy_vx (i.!.0))'
indexkl =: 0 indexkl_colsu f. NB. default version with key in position 0

NB. x is set of keys, y is keyed list, u is column numbers of key
NB. Result is 1 if x is in the list
inkl_colsu =: 1 : '(e.!.0) xuvy (m&keyskld)'
inkl =: 0 inkl_colsu f.

NB. x is a (list of) boxed key value
NB. y is an n,m $ array of key ; data
NB. u is default value (verb or noun)
NB. v is (key columns;data columns)
NB. Result is BOXED requested columns, default if not found
getkl_defu_colsv =: 2 : '(<@{. n)&keyskld uy_vx (i.!.0) ((<@{: n)&{@{ :: (u"_)"0 _) ]'
getklu_defu_colsv =: 2 : '[: > u getkl_defu_colsv n'
NB. m is key column(s), n is data column(s).  x is key(s), y is kl.  x must be found
getkl =: 2 : '<@(;&n)@(m&{"1 uy_vx i.) { ]'
getklu =: 2 : '[: > u getkl v'
NB. Default value is {:y, key is column 0, return column 1 (items have rank 0)
getkl1 =: (<_1;1)&{@]  getkl_defu_colsv (0;1) f.
NB. Default value is u, key is column, return column 1
getkl1d =: getkl_defu_colsv (0;1)
getklu1d =: 1 : '[: > u getkl1d'
NB. Default value is u, key is column, return other columns
getkld =: getkl_defu_colsv (0;<<0)
getklud =: 1 : '[: > u getkld'

NB. x is a list of boxed key value (may be scalar if key is rank 1)
NB. y is an n,m $ array of key ; data
NB. u is key columns, v is columns to return
NB. Result is the list of all boxed lists matching the key
allgetkl_colsuv =: 2 : '(n&datakld)@(((e.!.0)~ xuvy (m&keyskld)) # ])'
allgetkl =: 0 allgetkl_colsuv (<<<0) f.

NB. y is a list of key ; data, x is list of key columns (default 0)
NB. Result is the input, with duplicate keys removed (first one of multiples survives)
nubkl =: (#~ ~:@:(0&keyskld)) : (] #~ ~:@:keyskld) f.

NB. y is list of key ; data, x is list of columns to return (default 1)
NB. result is raze of one column of the data with the keys removed.  Default is first column
razekl =: (1&$:) : (; @: ({"1)) f.

NB. Conjunction: apply u to column number n of y, but only in records with keys in x
applykl =: 2 : '(((u&.>) @: (n&{)@])`(n"_)`] }) ^: ({. uy_vx e.) "_ 1'

NB. Conjunction: u is a predicate, v is a (possibly list of) column numbers
NB. u is applied to the list of (boxed) selected elements of y and the entire x (if any)
NB. Result is only those items which produce a nonzero predicate
cullkl =: 2 : '(u bivalent (n&{"1)   #   ])   ifany'

require 'regex'
NB. require 'isigraph'
IFQT =: IFQT"_^:(0 <: 4!:0 <'IFQT') 0
require^:(-.IF64)'winapi'
require^:IF64 'format/printf'
require^:(-.IF64) 'printf'
cocurrent 'z'

NB. Make this early, since others need it
NB. x is list, y is default values, result is x extended to length of y
default =: [ , (}.~ #)~

NB. Times & Dates
nameisexp =: 3 : 0"0
if. 0 = L. ar =. > 5!:1 y do. if. 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' e.~ {. ar do. ar =. > 5!:1 <ar end.  end.
if. ({.ar) -: <,'4' do. 1 return. end.
if. -. ({.ar) -: <,':' do. 0 return. end.
if. ({.0{::1{::ar) -: <,'0' do. 1 return. end.
0
)
NB. y is name class, result is explicit names of that type
allexpnm =: -.@:nameisexp usedtocull @: nl

NB. Get time-of-day, hh mm ss only (no date).  y is immaterial
tod =: 13 : '6!:0 y'
todhms =: 13 : '3 }. tod y'
todymd =: 13 : '3 {. <. tod y'

NB. Convert time-of-day hh mm [ss] to HH:MM[:SS] character string
disphms =: 13 : '}. ; <@:('':''&,)@:(2&displdzero)"0 <. y'"1

NB. y is [yy] mm dd, result is string [yy/]mm/dd
NB. x is number of digits to use for each element of y; default 2
dispymd =: (2&$:) : (13 : '}. ; x <@:(''/''&,)@:displdzero"0 y') "1 1 1

NB. Display y with a timestamp prepended
dispwithts =: 3 : 'display (disphms todhms NIL) , '' '' , y'

NB. Timestamp stuff
NB. y is full 6-element timestamp, result is scalar timestamp
tstosts =: 10000 100 100 24 60 60&#. :. ststots
ststots =: 10000 100 100 24 60 60&#: :. tstosts
NB. y is scalar timestamp, result is daystamp,timestamp
dstosts =: (100000000,*/24 60 60)&#. :. ststods
ststods =: (100000000,*/24 60 60)&#: :. dstosts
NB. y is day, result is y m d
daytoymd =: 10000 100 100&#: "0 :. ymdtoday
ymdtoday =:  100&#."1 :. daytoymd
NB. y is time, result is h m s
timetohms =: 24 60 60&#: "0 :. hmstotime
hmstotime =: 24 60 60&#."1 :. timetohms
mintotime =: 60&*
hrtotime =: 3600&*
hrafter =: hrtotime ux_vy +
minafter =: mintotime ux_vy +
NB. y is scalar timestamp, result is the day (integer)
ststoday =: <.@:(*&(%*/24 60 60))
ststotime =: (*/24 60 60)&|
NB. y is sts, result is string
dispsts =: (2&$:) : ( ((dispymd (3&{.)) , ' '"_ , disphms@(_3&{.)@])   <.@ststots ) "_ _ 0
NB. current time as an sts
todsts =: tstosts@tod
todday =: ymdtoday@todymd
todtime =: hmstotime@todhms


NB. x is 0 to force dates to be integer, 1 to allow fraction (default 0)
NB. y is y m d
NB. Result is 1 if the y m d is valid (works only in 1997 - 2099)
ymdvalid =: (0&$:) : ((13 : '(1 13 brackets 1{y) *. ((1 , (1{y) { (29 + 0 = 4 | 0 { y) 2} 0 32 29 32 31 32 31 32 32 31 32 31 32) brackets 2{y) *. x +. (-: <.) y') :: 0:)

NB. Year 2000 correction, takes yy to yyyy, post-1990
yytoyyyy =: ((1990&+)@(100&|)@(10&+))

NB. Number of days in each month of year y
daysinmonth =: 13 : '(28 + 0 = 4|y) 1} 31 0 31 30 31 30 31 31 30 31 30 31'

NB. Adverb.  m is the component to modify
addtots =: 1 : '+ onitemd m "0 1'
NB. x is a number of minutes, y is a timestamp (ymdhms or hms)
NB. Result is a timestamp (possibly invalid) that is x minutes before y
minutesafterts =: _2 addtots
minutesbeforets =: - ux_vy minutesafterts

NB. Auditing utilities

NB. y is a string; result is 1 if all characters are numbers
NB. except first character which may be a sign
isallnumeric =: 13 : '*./ ((}.~ (e.&'' +-_'')@{.)y) e. ''0123456789''' "1

NB. Character Utilities

delblank =: 13 : '(-. *./\ '' ''=y) # y'
delnblank =: 13 : '(-. *./\ '' ''~:y) # y'
NB. slowest crtolf =: (]`(LF"_)) @. (CR&=) "0
NB. slow crtolf =: ((=&CR)`(,:&LF))} "1
crtolf =: LF&(([`(CR&(I.@:=)@])`])}) "1
crlftolf =: 13 : '(-. (CR,LF) E. y) # y'
lflftolf =: 13 : '(-. (LF,LF) E. y) # y'
lftocrlf =: ; @ (<@,&(CR,LF) onpiecesbetweenm LF)

NB. Verbs to convert strings and tables to tab format
NB. y is a list of words, or array of same
NB. result is unboxed TAB-delimited list, with x added after each line (default LF)
tabfmt =: LF&$: : (,~  [: }:@; (TAB ,~ ":)&.>)"1 endtoend

NB. y is either an array of words or a list of lists of boxed words
NB. Result is TAB-delimited with x (default LF) after each row.
NB. If empty, return ''
NB. This is something of a kludge.  If the boxes are at dissimilar levels, we ignore all
NB. but the deepest.  This is because naqtmon relies on this behavior
NB. obsolete tabfmtg =: (''"_)`tabfmt`(;@:(tabfmt&.>))`((;@:(tabfmtg&.>)))@.L.
tabfmtg =: ''"_`tabfmt`(;@:( <@tabfmt S:1  bivalent (#~  L. = L."0)@,))`(;@:(<@(tabfmtg bivalent >"0)))@.(3 <. L.)

NB. Adverb
NB. m is the domain of y
NB. Result is verb such that:
NB. 0{x is a list of items; 1{x is another list of the same length  (so 2 = #$x) 
NB. items of y matching 0{x are replaced by the corresponding element of 1{x
xlateindomain =: 1 : '(,"_1 _ & m) ux_vy ((0&{ ux_vy i.) { 1&{@[)'
NB. 0{x is a list of chars; 1{x is another list of the same length  (so 2 = #$x) 
NB. chars of y in 0{x are replaced by the corresponding element of 1{x
xlatechars =: a. xlateindomain

NB. x is string, y is string; result is 1 if x is in y
isinstring =: +./@:E."1

NB. u is a verb, v is a string, y is a string
NB. Result is u applied to pieces of y that start with v
onstringsstartingwith =: 2 : 'n&E. ux_vy (u;.1)'

NB. u is a verb, v is a string, y is a string
NB. Result is u applied to pieces of y that start with v
onstringsendingbefore =: 2 : 'n&E. ux_vy (u;._2)'

NB. x is source;target  y is string  result has source replaced by target
NB. NOTE the source must not have any self-overlaps, in any context!
stringrepl =: 1&{::@[   ;@({.@] , (,L:0"_ 0 }.))  0&{:: ux_vy (#@[  ({.@] , (}.L:0 }.)) E. (<@(i.&1@[ {. ]) , <;.1) ])

NB. Levenshtein distance between two strings
levdist=: 4 : 0"1
'a b'=. (/: #&>)x;y
z=. >: iz =. i.#b
for_j. a do.
  z=. <./\&.(-&iz) (>: <. (j ~: b) + |.!.j_index) z
end.
{:z
)

NB. *** Regular-expression utilities
NB. Adverb.  x is regexp, y is string, result is 1 if x is in y
stringhasregexp =: (0&<:)@:((<0 0)&{)@rxmatch

NB. y is a string.  Result is table of (start,length) for sections
NB. of y cut on the first character of y 
tableoffrets =: (I.@:= {.) ([ ,. (2&(-~/\))@:,) #

NB. x is a string.  y is a table of (start,length) selections from x
NB. Result is a string, with the selected parts of x run together.
NB. Each interval in y must start within the bounds of x, even if the length is 0
substrs =: (;@:(<;.0)~  ,."1)~ 

NB. Formatting Utilities

NB. y is value
NB. x is strings to use for 0, +, - (default ' +-')
NB. Result is string, according to sign of y
selsign =: (' +-'&$:) : (* uy_vx {::)

NB. x, y are as to ":
NB. Result uses - instead of _ for sign
formatminus =: (('';'';'-')&selsign@] , (": bivalent |))"0 butifnull ''
NB. Same, but uses plus for positive numbers
formatplus =: (' +-'&selsign@] , (": bivalent |))"0 butifnull ''

NB. x is field format as for ":   y is fractional value
NB. Result is string form of 100 * number
disppct =: ": (100&*)
NB. Signed version of the above.  Sign is placed right next to the number.
sdisppct =: 13 : '(- {. +. x) {.^:(0&~:@[) (selsign y) , (j. {: +. x) ": 100 * | y' "0 0 0

NB. x is field format as for ":   y is a numeric (must be nonnegative)
NB. Result is string form with leading zeros included
displdzero =: 13 : '(- {. +. x) {.!.''0'' (j. {: +. x) ": y' "0 0 0

NB. y is string, x is 2 (possibly boxed) strings to put y between
NB. If x is just 1 element, it is used for both ends
enclosing =: 13 : '(>{.x) , y , (>{:x)'

NB. Enclose in quotes
enquote =: '"'&enclosing

NB. Enclose in parens
enparen =: '()'&enclosing

NB. y is a string, result is string with multiple blanks replaced by one blank
removemultiplespaces =: (#~ -.@('  '&E.))
NB. y is a string, result is string with multiple whitespace replaced by one blank
removewhitespace =: (#~ -.@(1 1&E.)@(e.&(' ',TAB,CR,LF)))

NB. y is string, xx [yy/zz]    Result is numeric, with the fraction divided
fracval =: (_1&$:) : (13 : '> (#.~ % ])&>/ x (<@".) onpiecesbetweend ''/'' y')
NB. y is string mm/dd/yy   Result is int, yymmdd (yy*10000 + mm*100 + dd)
dateval =: 13 : '100 #. _1 |. ". onpiecesbetweenm ''/'' y'
NB. y is string.  If there are 16ths (i. e. '[yy]), convert 'yy to yy/16
fracto16 =: ;@:((,&' ')&.>)@:(,&(<'/16'))@:((({.&.".)@:(,&' 0'))&.>)@:(< onpiecesbetweenm '''') ^: (''''&e.)
NB. y is string, either in 16ths xx 'yy   or in fracval form
NB. x is value to use in case of error (default 0)
frac16val =: (0&$:) : ( (fracval @: fracto16 @ ]) :: [)

NB. Adverb. m is default value, y is string (supposedly representing a number)
NB. Result is a scalar
execscalar =: 1 : '({.!.m)@(m&".)'

NB. Return 1 if y is in the half-open interval [ x )
brackets =: >/"1 @: (<: "1 0)

NB. Return vector with 1 in position of each change in y
NB. Always a 1 in the first position.  y must be a rank-1 list and
NB. the first element must not be _1
changepos =: ~:   |.!._1

NB. Zero all but the first x  values in y
keepmsds =: (0:`(<@<@<@i.@(<.#))`])}

NB. x (default 1, max 9) is a scalar, y is a scalar
NB. Result is y rounded to x significant digits (base 10)
truncytox =: (1&$:) : (13 : 'x keepmsds&.(10&#.^:_1) y') "0 0 0

NB. y is a number
NB. result is y with one significant digit, which is
NB. rounded up to the nearest of 1 2 5
sig125 =: ( (({&0 2 5 10)@:(+/)@:(0.1 1.1 4.1&<)"0)@:(1&keepmsds) ) &. (10&#.^:_1) &. (*&1000)

NB. y is anything
NB. Result is 1 if all the elements of y are the same
allsame =: -:!.0 (1&|.)

NB. Adverb.  x is a verb, result is gerund form
asgerund =: ` ''

NB. y is a string, result is gerund form of string
gerundof =: 3 : '13 : y ` '''''

NB. Graphics stuff

NB. x is 2 $ interval   y is value(s) (any rank)
NB. Result is fractional position(s) within interval
NB. If interval has 0 length, we return position 0 regardless
invlerp =: ( ({.@[ - ]) (% * 0 ~: ]) -/@[ )"1 _ :. lerp

NB. x is 2 $ interval y is fractional position(s) within interval (any rank)
NB. Result is value(s)
lerp =: (+/@:* (,~ -.))"1 0"1 _ :. invlerp

NB. x is a list of points, in ascending order, y is value
NB. result is interval . fractional position  for the interval bracketing y
NB. If y is out of bounds, use the endpoint
NB. After the test for too low/too high, we keep the vector of items of x less than y, and
NB. the first item of x ge y .  The count of these, -2, is the integer part, and we invlerp
NB. within the last 2 to find the fraction
piecewiseinvlerp =: (( ( (] (-&2@#@]  +  (invlerp~ _2&{.)) >:@(i.&0)@:< {. [) ` (<:@#@[)) @. ((>: {:)~)) ` 0:) @. ((< {.)~) "1 0

NB. x is a list of vectors, representing data values, each vector at one point
NB. y is interval . fractional position within interval
NB. Result is value
piecewiselerp =: 13 : '((,~ -.) 1 | y) +/@:(*"_1)  ((#x) | (, >:) <. y) { x'"_ 0

NB. x is 2,n$list : abscissas ,: slopes
NB. The abscissas are abscissas of intervals; the ordinate of the first
NB. point is defined to be 0 and the ordinates of succeeding points
NB. are given by the slope values.  All ordinates corresponding to
NB. abscissas below the first one are 0, and the last interval extends
NB. to infinity.
NB. y is an abscissa
NB. Result is the corresponding ordinate by piecewise-linear lookup
piecewiseslopelookup =: 0&>. @: ({. ux_vy (-~"_ 0))   +/ . *    (- |.!.0)@{:@[

NB. y is 2 2 $ target interval , source interval
NB. Result is polynomial which maps from source to target
NB. We have to be careful to avoid precision problems; we figure the multiplier
NB. first, and then use that to get the constant
NB. schematically: -~/\ (lerp invlerp&0 1)/ y
lerppoly =: ( (({."1@[ p. -@]) , ]) %/@:(-/"1) )"2

NB. Resampling
NB. y is (x values),:(y values)
NB. x is new x values
NB. Result is new y values
resamp =: 4 : 0
NB. Intervals are numbered by the index of the sample that
NB. ends the interval.  So, interval 0 is before the first sample
NB. and interval {:$y is after the last.  We calculate the
NB. interval number for each x and then, if it is one of those
NB. off-the-end intervals, adjust to the nearest interior interval.
NB. This means we extrapolate out-of-range values using the slope
NB. of the outermost intervals.
ix =. 1 >. (<:{:$y) <. (0{y) I. x
NB. Calculate the interpolating polynomial for each interval.
NB. Here we use linear interpolation, so the polynomial is (y value),(dy/dx)
NB. Create a polynomial for the first interval (off the beginning),
NB. using the slope of the first internal interval
intpoly =. (1 { y) ,. (,~ {.)   %~/ 2 -/\"1 y
NB. The value to return is the interpolating polynomial, evaluated
NB. given the distance between the desired value and the origin point
NB. (i. e. right endpoint) of the interval
(ix { intpoly) p. ((<0;ix) { y) -~ x
)

NB. y is a fractional position in the display, range 0 to 1
NB. Result is in isigraph units
fractoisigraph =: (*&1000) @ (, -.)/

NB. Adverb.  u is boolean function number
NB. The boolean function is applied to the integer arguments x and y
bitfunc =: 1 : '(16 + u) b.'
bitor =: 7 bitfunc
bitand =: 1 bitfunc
bitxor =: 6 bitfunc
bitclr =: 4 bitfunc  NB. 1s in x are turned off in y
onint32 =: &. ((32$2)&#: :. ((_2 _2,30$2)&#.))

NB. x is two numbers  y is a number  result is 1 if y is in the [ )  interval
inhalfopeninterval =: ~:/ @: > "1 0

NB. Adverb.  If [x] u y is 1, keep that element of y
usedtocull =: 1 : 'u # ]'

NB. x is (starting position,length), y is list
NB. result is the selected portion
substr =: ,. ux_vy (];.0) "1 _

NB. y is a list, result is 1 if list is in sorted order
listissorted =: /: -: i.@#

NB. 0{::x is list of target keys
NB. 1{::x is list of source keys
NB. y is list of data
NB. Result is data, permuted so that items with matching keys match if possible.
NB.  Unmatched items are assigned in order from the beginning of the arrays.
NB.  If (0{::x) <&# (1{::x), y is truncated BEFORE matching elements are assigned.
NB.  If (0{::x) >&# (1{::x), the last element of y is repeated to fill the surplus.
NB. Ex: (0 1 2 ; 5 0) permuteytomatchkeys 'a' ; 'b'
NB. 'b' ; 'a' ; 'b'   (the second b is a default repeat)
pymkmatch =. #@[ {. i.!.0 , ((0&>.)@-&# $ #@[)  NB. vector, shaped like x, but giving for
												NB. each ele of y the position in x it goes to,
												NB. or #x if no match
pymkfill =. ( ((-.~ i.@#)@]) ` (I.@:(= #)@]) ` ] )}  NB. fill out the entries of pymkmatch
												NB. that were #x, assigning unique values
												NB. to them
pymkinvperm =. (/:@[ <. (<:@#@]) ) { ]  NB. Invert the permutation, to give a list of
											NB. elements of y to produce each x; clamp
											NB. the list to #y, then extract the elements
											NB. to produce the final result
permuteytomatchkeys =: ( (null pymkfill pymkmatch)&>/@[ pymkinvperm ] ) f.

NB. Progressive index - like x i. y, but each item of x matches only one y
progressiveindex =: #@[ ({. i.&(,.   i.~ (] - {) /:@/:) }.) [ i. ,

NB. x and y are arrays
NB. Each element of y is taken away from x, but only once (multiples in y
NB. take away matching items of x, but only up to the number of occurrences
NB. in y.
NB. obsolete xminusyonce =: (0&{::) @: ( ( ( (#~ -.@~:)@[ , -.&(~.!.0) ) ,&< (#~ -.@~:)@] ) &> / ^:_ ) @: (,&<)

NB. obsolete xminusyonce =: 4 : 'x #~ -. x e.&(x&i. ,. (i.~ (]-{) /:@/:)) y'
xminusyonce  =: [ #~ #@[ ({. -.@:e.&(,.   i.~ (] - {) /:@/:) }.) [ i. ,
NB. y is anything
NB. result is a (parenthesized) string that, when evaluated, equals y
nountostring =: 3 : 'enparen 5!:5 <''y'''

NB. Conjunction.  u is applied in each locale v
NB. Note: these define a local cocurrent so that cocurrent can run even if the
NB. locale destroyed itself
inlocales =: 2 : 0
cocurrent =. 18!:4
i =. 18!:5 ''
for_l. n do.
  NB.?lintonly l =. <''
  cocurrent l
  u y
end.
cocurrent i
''
:
cocurrent =. 18!:4
i =. 18!:5 ''
for_l. n do.
  NB.?lintonly l =. <''
  cocurrent l
  x u y
end.
cocurrent i
''
)
NB. same, but return result
inlocalesr =: 2 : 0
cocurrent =. 18!:4
i =. 18!:5 ''
r =. 0$a:
for_l. n do.
  NB.?lintonly l =. <''
  cocurrent l
  r =. r,u y
end.
cocurrent i
r
:
cocurrent =. 18!:4
i =. 18!:5 ''
r =. 0$a:
for_l. n do.
  NB.?lintonly l =. <''
  cocurrent l
  r =. r,x u y
end.
cocurrent i
r
)

NB. y is a value, result is 1 if it looks like a gerund
isgerund =: 0:`(2 32 e.~ 3!:0@>)@.(32=3!:0)"0

NB. Conjunction.  n is (max # retries);(list of retcodes to retry)
NB. [x] u y is executed; if the return code (which is >{.result)
NB. is in the retry list, we execute it again.
retry =: 2 : 0
if. (0 < 0{::n) *. (>{. result =. u y) e. 1{::n do. result =. u retry (<:&.> onitemm 0 n) y end.
result
:
if. (0 < 0{::n) *. (>{. result =. x u y) e. 1{::n do. result =. x u retry (<:&.> onitemm 0 n) y end.
result
)
 
NB. Adverb: y is anything, x is anything, (x&u) is applied to each infix of length #x
appliedtoinfixes =: 1 : 0
NB.?lintmsgsoff
[: y
NB.?lintmsgson
:
(#x) (x&u)\ y
)

NB. x is a boxed program string
NB. y is arguments to it
NB. x is converted to a function and executed with y as its argument
exex =: 4 : ' (3 : x) y '

NB. y is boxed locale name
NB. Result is 1 if locale exists
localeexists =: e.   (4!:1)@:6:

NB. Indicate which script defined unboxed name y
whichscript =: 13 : '((''Not from script''"_)`({ (4!:3)@(''''"_)))@.(0&<:) (4!:4) < > y'

NB. y is a string; expunge the variable of that name
expunge =: 13 : '4!:55 < y'

NB. y is a string; result is vector of boxed names beginning with y
NB. If x is present, only those name classes are searched (default 0 1 2 3)
NB. a: ,  required so s: doesn't think type is unboxed
listnameswithprefix =: (0 1 2 3&$:) : (13 : '(a: , ({.y) 4!:1 x) ( (] -: ({.~ #))S:0 _ # [ ) y ')

NB. y is a string.  We call the _close event for each subwindow (signified by
NB. existence of a variable with that prefix; we delete the prefix to get the window name)
closewindowswithprefix =: 13 : '(#y) (null@".@:(,&''_close 0'')@:(}. >)) rnk 0 (0 listnameswithprefix y)'

NB. y is a string
NB. x is list of name classes (default 6, meaning locale)
NB. Return the (deprefixed) locales that have y as a prefix
listnamesdroppingprefix =: (6&$:) : (13 : '(#y) }. L:0 x listnameswithprefix y')

NB. x and y are anything
NB. Result is 1 if y is lexicographically >= x (i. e. using /:)
lexygex =: 13 : '{: /: x ,&< y'
NB. Result is 1 if y is lexicographically > x (i. e. using /:)
lexygtx =: 13 : '{. \: x ,&< y'

NB. u is gerund, v is a verb.  [x] (k{u)`:0 &. v is applied to cell k of y
NB. The first cell is evaluated to get the shape of a cell, then all cells are reevaluated
respectively =: 2 : 0
a: (<@:((,'2')&(,&<))@:((<,']')&,) "0 u) respectively v y
:
z =. (#y) $ ,: x ({.m)`:0&.v {.y 
for_y. y do. z =. (x (((#m)|y_index){m)`:0 &.v y) y_index} z end.
)

NB. y is a character string; we add on the current locale name (if there is no locale already)
inthislocale =: (, '_'&enclosing@>@(18!:5)@(0&$))^:('_'&~:@{:)

NB. x is a (possibly boxed) string, default ', '
NB. y is a list of boxed strings
NB. Result is string, with the punctuation between the words
punctuatewords =: ', '&$: : (boxopen ux_vy (;@}:@,@,.~))"1

NB. Statistical functions

NB. x is new value, y is old value, result is % change (using the geometric mean as basis if going up)
NB. Value of _ cause trouble, so make result _ if x is _
pctchg =: - (*%) ] >. %:@:*
NB. x is new value, y is old value, result is % change (using the original value as basis)
pctchgo =: - (*%) ]
NB. x is new value, y is old value, result is % change (using the greater value as basis)
pctchgm =: - (*%) >.

NB. y is vector, result is median
median =: <.@-:@# { /:~

NB. y is vector of observations
NB. Result is mean
mean =: +/ % #

NB. y is a vector
NB. Result is rms value
rms =: mean&.(*:"_)

NB. y is vector of #observations , sum , sumsq
NB. Result is variance.  Because of roundoff this may become <0; we
NB. clamp to 0
variancepoly =: (0&>.) @: ({: - *:@{.) @ (}. % {.)

NB. y is vector of observations
NB. Result is vector of sum , sumsq % # observations
varianceinfo =: (# , +/ , +/@:*:)

NB. y is vector of observations (any rank)
NB. Result is mean,variance
moments =: (- *:)~/\ @ (# %~ +/ ,&,: +/@:*:)

NB. x and y are lists to be regressioned (x independent, y dependent)
NB. Result is 5 $ values to pass into regress
regressinfo =: (#@] , +/@[ , +/@] , +/@:* , +/@:*:@[)

NB. x is vector of 4 indices
NB. y is vector of data
NB. Result is the determinant of the selected indices of the data
fetchdet =. 13 : '-/ . * (2 2 $ x) { y' "1
NB. y is result from regressinfo (s,sx,sy,sxy,sxx)
NB. Result is regression coeffs a,b: multipliers of 1,independent
regress =: ((2 4 $ 2 1 3 4  0 2 1 3)&fetchdet % 0 1 1 4&fetchdet) "1 f.

NB. x and y are lists to be regressioned (x independent, y dependent)
NB. Result is a, b, standard error
regresssigma =: (regress@regressinfo ([ , rms@({:@] - (p. {.))) ,:)

NB. Quaternion support
NB. qtom converts quaternion to a matrix form in which matrix multiply corresponds
NB. to quaternion multiplication (mtx add=qadd, determinant=magnitudesq, mtx inv=reciprocal)
qtom =: j./"1  @: (,:"2 (_2]\_1 1 1 _1) *"2 |."2)  @: (_2&(]\)"1)  :.  (,"2@:+.@:({."2))

NB. unit quaternion to rotation matrix
NB. convert quaternion ABCD to 3 2x2 matrices ABCD ABCD ADBC
qto3mtx =. _2 ]\"1 {. ,. 0 1 2 |."0 1 }.
NB. main diagonal -CC-DD, -BB-DD, -BB-CC
qtorot0 =. -@:(+/)@:*:@{:"2
NB. next diagonal: -AD+BC, -AB+CD, -AC+BD
qtorot1 =. -@:(-/ . *)"2
NB. last diagonal: AC+BD, AD+BC, AB+CD
qtorot2 =. _1 |. +/ . * "2
NB. Roll it up, shift diagonals to proper position, double, add unit matrix
qtorot =: ((e.0 1 2) + [: +: 0 _1 _2 |."0 1 [: (qtorot0 ,. qtorot1 ,. qtorot2) qto3mtx) "1 f.


NB. *** FFT ***

cube =. ($~ q:@#) :. ,
roots=. ^@(0j2p1&%)@* ^ i.@-:@]
floop=. 4 : 'for_r. i.#$x do. (y=.{."1 y) ] x=.(+/x) ,&,:"r (-/x)*y end.'
fft  =: (] floop&.cube  1&roots@#) f. :. ifft
ifft  =: (# %~ ] floop&.cube _1&roots@#) f. :. fft

NB. *** Math ***

NB. Get sum of all divisors of a positive integer, including itself and 1
divisorsum =: (*/@:(((^ >:) %&:<: [)/)@:(__&q:))"0
NB. Sum of all divisors, but not including the number itself
properdivisorsum =: -~ divisorsum

NB. File searching

NB. make sure directory name ends with '\' and uses '\' between levels, and is boxed.
NB. strictly, 0 or more occurences of dir\
fmtdirname =: ('\' ,~^:(~:{:!.'\') '/\'&xlatechars)&.>@boxopen

NB. discard directory path, leaving filename.  If no slash, return entire input
filenameonly =: (}.~ >:@(i:&'\'))@('\'&,)"1

NB. discard filename, leaving directory path (with slash).  If no slash, return empty
dirnameonly =: ({.~ >:@(i:&'\'))&.('\'&,)"1

NB. discard the .extension from the name
dropfileext =: ({.~ (i:&'.'))"1

NB. See if file line from 1!:0 indicates directory
finfoisdir =: 'd' = (4;4)&{::"1

NB. y is (possibly boxed) filename search path
NB. Sample y is 'C:\j\system\*.ijs'
NB. Result is list of files in the path - qualified to the same level
NB. as given in y (i. e. relative to the same directory that y starts in)
searchdir =: 13 : '(({.~ >:@(''\:''&(i:&1@(e.~))))L:0 y) ,&.> butifnull (0$a:) 0 {"1 (1!:0) y'

NB. Adverb.  [x] u is applied on each file in the (boxed) search path y
NB. Sample y is 'C:/j/system/*.ijs'.  The filename supplied to u is
NB. boxed and qualified at the same level as y  The argument to u may be null
ondir =: 1 : 'u bivalent searchdir'

NB. y is boxed name of directory (no file specifier within the directory)
NB. Result is list of subdirectories, full name
subdir =: ( (, '\'&,)&.>   (keyskl @ (finfoisdir usedtocull) butifnull (0$a:)) @ (1!:0) @ (,&'\*.*'&.>) )"0

NB. y is boxed search path, e. g. <'C:/j/system/*.ijs'
NB. result has one level of subdirectory added, with the file specifier
NB.  unchanged, e. g. 'C:/j/system/winapi/*.ijs';...
subdirpath =: ( (subdir@({.&.>) ,&.> }.&.>)~ i:&'\'&.> )"0

NB. Adverb.  y is boxed filename search path (filename\extension).  Apply [x] u to each
NB. list of boxed filenames matching the extension, first in subdirectories (recursively) and then
NB. in the named directory.  Result is the results from u, with the
NB. results from this directory first, then subdirectories
NB. The part at the end creates a list of subdirectories with paths
NB. attached, i. e. 'c:/j/*.ijs' -> 'c:/j/system/*.ijs';'c:/j/user/*.ijs'
NB. NOTE: this adverb uses recursion, so it must be sequestered in a verb
NB.  of its own rather than being part of a train, i. e.
NB.  ] recursivelyonfiles @ (<@,&'\*.*')
NB.  is no good because the <@... is part of the recursion
recursivelyonfiles =: 1 : '( u ondir  ,~ifanyx~  $:"0 _ 0 endtoend ifany bivalent subdirpath)"0 _ 0'
NB. y is boxed filename search path (filename\extension)
NB. Files matching the extension are deleted in the subdirectories of the path, and
NB. then in the path itself (and recursively in those subdirectories)
recursivedeletefiles =: null@:((1!:55 :: null)"0) recursivelyonfiles @ boxopen
 
NB. x is character string, y is boxed filename search path
NB. Result is script file names containing x
findinscript =: 4 : 0
x ((isinstring  1!:1) rnk _ 0 usedtocull) searchdir y
)

NB. x is character string, y is filename search path
NB. files with the strings are opened
editinscript =: 4 : 0
(null @: wd @: ('smsel "'&,) @: (,&'";smopen') @: >) rnk 0 x findinscript y
)

NB. Adverb.  [x] u is applied to file(s) y
onfile =: 1 : '(u bivalent (1!:1))"0 _ 0 ifany'
NB. Adverb.  [x] u is applied to file(s) y, and the file is rewritten
modfile =: 1 : '((u bivalent (1!:1)) 1!:2 ])"0 _ 0 ifany'
NB. Adverb.  Applies [x] u to the data in files described by path y, without writing the file
applytofiles =: onfile ondir
NB. Adverb.  Applies [x] u to the data in files described by path y, write results to the file
modifyfiles =: modfile ondir

NB. Count words in file.  Returns #lines with string, # blank lines, #comment lines.  y is file data
NB. x, if given, is string to search for in lines, returning count containing it.  Default
NB. is '', which appears in all lines & gives a count of # lines
wcfile =: (''&$:) : (13 : '+/ x ( isinstring , (0&=)@#@] , (''NB.''&-:)@(3&{.)@] )S:_ 0 (}.~ <:@(i.&0)@('' ''&=)) L:0 < onpiecesbetweenm LF y')

NB. y is file descriptor, result is total wcfile in all files.  x, if given, is string to
NB. check for
wcfiles =: +/ @: (wcfile applytofiles)

NB. x is string, y is file data
NB. lines starting with x (after removing leading blanks) are deleted
NB. We add an LF and take it away when we're done
dellinesprefixed =: 13 : '}: ; x ( (,&LF@])`(''''"_) @. ( ([ -: (#@[ {. ]))  (}.~ (i.&0)@('' ''&=)) ) ) L:0 < onpiecesbetweenm LF y'

NB. examples:
NB. 'obsolete' wcfiles <'d:\trade\*.ijs'
NB. 'NB' wcfiles <'d:\trade\*.ijs'
NB. 'NB. obsolete' dellinesprefixed modifyfiles <'d:\trade\*.ijs'
NB. ('oldstring';'newstring') stringrepl modifyfiles <'d:\trade\*.ijs'
NB. ('K:';'F:') stringrepl modfile recursivelyonfiles <'f:\playlists\*.m3u'

NB. HTML stuff

NB. y is string, result has scripts removed.
NB.              tostring     remove betw start,end      s/e;s/e;string   strt/end+1  rmv any trail +, lead -     rmv multiples, keep 1st +, last -   sort           begs,end+1s         find tag positions 
removescripts =: > @ {. @ ( ({.ux_vy{. , {:ux_vy}.)&.>/ ) @ ( (,<)~     (_2&(<\))@:|@(}:^:({:>:0:))@(}.^:({.<0:))@,@(({.~ *@{.);.1~ (~: |.!.2)@(0&<:))@(/: |) ifany @((, _9&-)&>/)@((('<script';'<SCRIPT'),&<'</script>';'</SCRIPT>')&(> ux_vy (<@I.@(+./)@:(> ux_vy E. "0 _))"0 _)) )

NB. y is a string, result has html tags (paired <...>) removed.
NB. We don't handle nesting, because YAHOO had a bug that left a hanging <a tag.
NB. To restore nesting, change the (]`[@.(*@[))/\.&.|.  to  +/\
NB. The (0&>.@+/\.&.|.), rather than simple +/\, is to ignore > that is
NB. unmatched by a previous <
removehtml =: 13 : '(''&amp;'';''&'') stringrepl (''&quot;'';''"'') stringreplace (''&nbsp'';'' '') stringreplace (''&nbsp;'';'' '') stringreplace (#~ (+: |.!.0)@:*@:(0&>.@+/\.&.|.)@:(-/)@:(''<>''&(="0 _))) y'
NB. nest removehtml =: 13 : '(''&nbsp;'';'' '') stringreplace ( -. (+. |.!.0) 0 < +/\ -/ ''<>'' ="0 _ y ) # y'

NB. y is string, result is string with quotes around it if need be
NB. correct quoteHTTPhdr =: '"'&enclosing @: (2&}.@:;@:(<@('\'&,);.1)@:('"'&,)^:('"'&e.)) ^:(+./@:(('()<>@,;:\"/[]?={} ',(127,i.32){a.)&e.))
quoteHTTPhdr =: '"'&enclosing @: (2&}.@:(('\'&,) cutetoe 1)@:('"'&,)^:('"'&e.)) ^:(+./@:((' ',(127,i.32){a.)&e.))


NB. File utilities
NB. x and y are arguments to jreplace - the suffix (.jf default) must be present
NB. The file is locked before jreplace is run & unlocked afterwards
lockedjreplace =: 4 : 0
jf =. (<f =. 1!:21 {. y) 0} y
while. -. 1!:31 f , 0 , 1!:4 f do.
  wd 'mb "Lock failure" "Lock not granted on %j" mb_ok'&sprintf 0{y
end.
try.
NB.?lintmsgsoff
  x jreplace jf
NB.?lintmsgson
catch.
  1!:22 f
  sentence_debug_ =: 13!:12 ''
  emsg_debug_ =: (<: (13!:11) '') {:: 9!:8 ''
  lockedjreplacex_debug_ =: x
  lockedjreplacey_debug_ =: y 
  'Error in lockedjreplace' 13!:8 (3)
end.
1!:22 f
NILRET
)

NB. x is target drive ; source drive
NB. y is <drive_placeholder:fileid; the file is copied from drive to drive, in the same path
copydrive =: 4 : 'null (1!:1 (1{x) 0}L:0 y) 1!:2 (0{x) 0}L:0 y' rnk 1 0

NB. y is filename (boxed); x is default date.
NB. Result is last-modified date of file
filemoddate =: 13 : '> (<x) default~ (1&{"1) (1!:0) y' "1 0

NB. y is old file name, x is new file name (both boxed character lists)
NB. The file is renamed, and the result is 1 if successful
renamefile =: [: : ((0&{::) @ ('kernel32 MoveFileA i *c *c'&(15!:0)) @ , "0~ )

NB. Above didn't change the timestamp, so modify 1 byte
setfilemodified =: (1!:11 @ (,&(<0 1))   1!:12   ,&(<0))"0


NB. System utilities

NB. Read a specified number of bytes
NB. x is socket, y is number of bytes to read.  If error, fail
readexactly =: 4 : 0
NB.?lintonly sdrecv =. ]
reply =. ''
while. y > #reply do.
  'rc d' =. sdrecv x , (y-#reply) , 0
  NB. Fail if error or no bytes read (means the connection was closed)
  if. (rc~:0) +. (0=#d) do. 13!:8 (5) end.
  reply =. reply , d
end.
reply
)

NB. y is string to execute
NB. x is sw_show type, (default sw_showminimized)
NB. Use 11!:0 instead of wd because we may redefine wd to null
winexec =: ('sw_showminimized'&$:) : (13 : '11!:0 ''winexec '' , DEL , y , DEL , '' '' , x')

NB. Reboot Windows.  y is an option mask:
NB. 1=SHUTDOWN, 2=REBOOT, 4=FORCE, 8=POWEROFF
reboot =: ('user32 ExitWindowsEx i i'&(15!:0)) @ <

NB. y is window name (string)
NB. result is 1 if window is defined.  Changes the selected window
NB. Use 11!:0 in case wd is redefined
selwindowifdefined =: (1:@(11!:0)@('psel '&,)) :: 0:

NB. x is string, with name(s) of fields e. g. 'fld1' or 'fld1 fld2'
NB. y is data for the field(s)
NB. the form is filled in with the data
formset =: ;: ux_vy (wd@('set %j *%j' vsprintf)@,"0 <^:(L. = 0:))
NB. Same, but without the * (quoted string)
formsetq =: ;: ux_vy (wd@('set %j %j' vsprintf)@,"0 <^:(L. = 0:))
NB. similar, but set other elements.  Data must be numbers
formsetcolor =: ;: ux_vy (wd@('setcolor %j %j' vsprintf)@,"0 <^:(L. = 0:))
formsetscroll =: ;: ux_vy (wd@('setscroll %j %j' vsprintf)@,"0 <^:(L. = 0:))
formsetenable =: ;: ux_vy (wd@('setenable %j %j' vsprintf)@,"0 <^:(L. = 0:))
formsetselect =: ;: ux_vy (wd@('setselect %j %j' vsprintf)@,"0 <^:(L. = 0:))
NB. adverb.  m is form name; we do formset in that form
formselset =: (2 : ';: ux_vy (wd@v@(m&;)@,"0 <^:(L. = 0:))') ('psel %j;set %j *%j' vsprintf)
NB. Same, but without the * (quoted string)
formselsetq =: (2 : ';: ux_vy (wd@v@(m&;)@,"0 <^:(L. = 0:))') ('psel %j;set %j %j' vsprintf)

NB. y is a variable name
NB. result is 1 if name is defined
ifdefined =: 13 : '0 <: 4!:0 < y'

NB. x and y are sets; result is intersection, in the order given in x
setintersect =: e. # [

NB. y is n,2$ list of ranges (start,length).  Result is the ranges that are not
NB. wholly included in another range.
discardincludedranges =: (~. @: #~ ([: (>: >./\) +/"1))@:/:~

NB. Set box characters for email.  y is 1 to go to email, _1 to come out of email
setboxforemail =: 3 : 0
y =. {.y,1
9!:7 a. {~ (y=1){:: 16 17 18 19 20 21 22 23 24 25 26;43 43 43 43 43 43 43 43 43 124 45
)

NB. y is a string, x is (optional) boxing characters, result is string followed by paren matching
depth =. [: +/\ =/\@(''''&~:) * 1 _1 0 {~ '()' i. ]
levels=. i.@-@(>./) </ ]
i4    =. 2 #.\"(1) 0 ,. ]
paren2=. (' ',6 8 10{[) {~ i4@levels@depth@]
paren =: (9!:6 '')&$: : (],paren2) f.

NB. CRC calculation.  This builds the CRC by passing the bytes into the
NB. MSB of the shiftregister and shifting right, applying the polynomial
NB. (inverted) using the LSB.  Some other implementations seem to process bits in
NB. a different order.  CRC-32 of '123456789' is CBF43926
crc32poly =: |. 0 0 0 0  0 1 0 0  1 1 0 0  0 0 0 1  0 0 0 1  1 1 0 1  1 0 1 1  0 1 1 1
NB. Because the std definition init the shiftreg to 1s and XORs 1s at the
NB. end, we compensate by shifting in 1s here and reversing the result
NB. (in effect complementing the input)
crc32tbl =: |. (((|.!.1))`(~:&crc32poly@(|.!.1)))@.{:"1 ^:8 onint32 i. 256
NB. One calculation: y is shiftregister, x is new byte
calccrc32byte =: (({&crc32tbl)@(bitxor 255&bitand)  bitxor  _8&(33 b.)@])
NB. y is string or numeric vector; result is CRC-32
calccrc32 =: (calccrc32byte/@|.@(0&,)) @: ((a.&i.)^:(2:=3!:0))

NB. Extract variable-length records
NB. Conjunction.  u calculates record lengths.  (u y) must
NB. return a list of length y such that if a record starts at
NB. (i{y), (i{u y) gives the length of the entire record.
NB. v is applied to each record found in y
extractrecords =: 2 : 0
v;.1~    i.@# e. ((# <. (+ i.@#))@:u , _1:) {~^:a: 0:
)


NB. Initialization automation.
NB. Initialization routines are always named 'initialize' in
NB. the locale in which they reside.  They are registered
NB. here, along with a level at which they should be applied.
NB. (the level is system-dependent but generally 0=one-time
NB. initialization).  A call to initialize_z_ y runs all
NB. the initializations at y or above.
initialize_list =: 0 2$a:
registerinit =: 3 : 0
'initialize' registerinit y
:
initialize_list_z_ =: ~. initialize_list_z_ , y ; x , '_' , (>18!:5'') , '_'
NILRET
)
initialize =: 3 : 0
0:@(128!:2&y)@> ifany (y&<:@:(0&ocol) # 1&{"1) initialize_list
NILRET
)

NB. Adverb to test the internet connection before trying to do something.  Obsolete
NB. in the modern world.  The old dialup one is in netio.ijs
afterconnecting =: 1 : 'u'

NB. *** Color-space conversions ***
NB. y=RGB in range 0-255
NB. Result is h(0-360), s(0-1), v(0-1)
rgbtohsv =: 3 : 0"1 :. hsvtorgb
NB. difference, minimum, maximum
d =. -~/ nx =. (<./ , >./) y
NB. hsv.  Must divide by d last to avoid NaN if r=g=b
((360 | 60 * (d %~ y -/@}.@|.~ ]) + +:@]) (i. >./) y) , -.@%/\.@(%&255) nx
)

NB. y=h(0-360), s(0-1), v(0-1)
NB. Result is RGB in range 0-255
hsvtorgb =: 3 : 0"1 :. rgbtohsv
'h s v' =. y
'z d f' =. 3 2 60 #:!.0 h
255 * (-z+d) |. v * 1 , |.^:(-.d) -. */\ s , -.^:(-.d) f % 60
)


NB. File server
NB. Created when we get a connection on our listening socket
NB. This class does not return an object - the object runs itself &
NB. destroys itself when transaction is complete

NB. This class also includes the utilities to create file-server requests
NB. and responses, and decode same

coclass 'sockfileserver'
NB. the cache for INCR commands
incrfn =: ''
incrdata =: ''  NB. if incrfn is not empty, incrdata holds the last data written to the file
coinsert 'sockmux'
SERVERTO =: 5  NB. timeout in seconds
PASSWORDFN =: <'Passwords.txt'
LOGFILE =: <'Logfile.txt'
HIDDENFILES =: PASSWORDFN,LOGFILE  NB. Files we will not alter or disclose without execute privilege

NB. Create socket. x is the socket that has been created for this connection
NB. y is root of file system that is visible to this server
NB. Return 0 if successful
create =: 4 : 0
convstate =: 0  NB. 0=waiting for hdr 1=waiting for data 2=sending
recvdata =: senddata =: ''  NB. Init nothing received and no data to send in reply
filesystemroot =: fmtdirname {. y  NB. Root of the file system.  Set before first logadd
commactive =: 1   NB. Set socket active
NB.?lintonly 'sock errto recvdata' =: 0;0;''
if. 0 ~: r =. x create_sockmux_ f. SERVERTO + todsts NIL do.
  destroy 'create failed'  NB. Couldn't create socket object, abort
  r return.
else.
  logadd 'created for ' , (2 {:: sdgetpeername_jsocket_ sock) , ' at ' , , 'q</>r<0>5.0,q</>r<0>3.0,q< >r<0>3.0,q<:>r<0>3.0,q<:>r<0>3.0,r<0>6.3' 8!:2 tod NIL
end.
NB. Wait for data to move
0
)

destroy =: 3 : 0
logadd ifany y
destroy_sockmux_ f. ''
)

errhand =: 3 : 0
destroy 'Error ' , (":y) , ' during connection handshake'
)

NB. Check timeout.  Current time is in y.  If time has expired, signal ETIMEDOUT
NB. We just listen forever, no timeout
checkto =: 3 : 0
NB. If we have had socket activity, extend the timeout period
if. commactive do.
  errto =: SERVERTO + y
  commactive =: 0
end.
NB. After a period of inactivity, pull the plug
if. y > errto do.
  'rc d' =. sdrecv_jsocket_ sock,128 0
  destroy 'timed out' , ' at ' , , ('q</>r<0>5.0,q</>r<0>3.0,q< >r<0>3.0,q<:>r<0>3.0,q<:>r<0>3.0,r<0>6.3' 8!:2 tod NIL) , 'convstate=' , (":convstate) , ' recvdata=' , recvdata , 'final rd rc=' , (":rc) , ' final rd data=' , d
end.
''
)

NB. y is data line.  Add it to the execution log
logadd =: 3 : 0
((>coname''),': ',y,CRLF) 1!:3 filesystemroot ,&.> LOGFILE
NILRET
)

NB. send handler.  Called when our socket is allowed to send.  Send the data
NB. that we have calculated.
NB. Result is _1 0 1 to indicate (error-socket closed with callback)/(send finished)/(more to send)
send =: 3 : 0
if. #senddata do.
  'r l' =. senddata sdsend_jsocket_ sock,0
  if. r do.
    destroy 'send error'
    _1 return.
  else.
    commactive =: 1
    senddata =: l }. senddata
    NB. If we have finished sending our reply, we're done
    if. (convstate = 2) *. (0 = #senddata) do.
      NB. Normal completion - close the connection
      destroy 'finished'
      _1 return.   NB. Make sure this connection is off the readable list
    end.
  end.
end.
*#senddata
)

NB. recv handler.  Called when there is data for our socket.  We read the data and
NB. then inspect it depending on our transfer state
NB. State 0 - waiting for header
NB. State 1 - waiting for body
NB. State 2 - sending reply
recv =: 3 : 0
NB. Read the data
'r d' =. sdrecv_jsocket_ sock,30000 0
NB. The client should not be the first to close; but if it is, we should
NB. stop processing the socket.  We may be in the middle of sending something
NB.?lintonly 'rc msglen password compression' =: 0;10;'';0
if. 0 = #d do. destroy 'client closed connection'
else.
  commactive =: 1
  NB. Append to our inbound data buffer
  recvdata =: recvdata , d
  NB. Validate the request, depending on the receive state.  We read until
  NB. we get end-of-header; then until conn closes
  if. convstate = 0 do.
    NB. If we have the full header, examine it & move on to nextstate
    if. (#recvdata) > hlen =. (CRLF,CRLF) (#@[ + i.&1@:E.) recvdata do.
      'rc msglen password compression' =: fileserv_decreqhdr hlen {. recvdata
      if. rc ~: 0 do.
        destroy 'invalid hdr (rc=' , (": rc) , ') Data=(' , (hlen {. recvdata) , ')'
      else.
        NB. Discard header, advance to next state
        recvdata =: hlen }. recvdata
        convstate =: 1
      end.
    elseif. 100000 < #recvdata do.  NB. Long header must be spam
      destroy 'hdr too long, connection closed'
    end.
  end.
  NB. If we are waiting for end-of-data, advance if we get it
  if. convstate = 1 do.
    if. msglen <: #recvdata do.
      NB. The entire request has been received.  Process it.  The result
      NB. of processing is the return code and the return data
      NB. Get command
      cmdline =. CRLF dropafter recvdata
      cmdword =. toupper ' ' taketo cmdline
      if. (<cmdword) -.@e. cmdlist do.
        logadd _2 }. cmdline   NB. Log the command
        logadd 'Invalid command'
        'rc respdata' =. 500;'Invalid command ', cmdline
      else.
      NB. If command is valid, call the command processor
        try.
          NB. If we have #recvdata > msglen, and no CRLF found (i. e. ill-formed msg)
          NB. we could have negative len and startpos after the end; turn that into
          NB. 0-len request
          rembody =. (0 >. -~/\ (#cmdline),msglen) substr recvdata
          'rc respdata' =. ('cmdproc_',cmdword)~ cmdline;rembody
        catch.
          'rc respdata' =. 520;'Command crashed: ',cd =. 13!:12''
          logadd 'Crash: ',cd
        end.
      end.
      NB. Send the reply called for
      senddata =: rc fileserv_addrsphdr respdata
      convstate =: 2  NB. Go into reply state before we request send
      reqwrite''
    end.
  end.
end.
NB.?lintsaveglobals
''
)

NB. Command processors

NB. y is command line, ending with CRLF
NB. first word is command, others are quote-delimited operands
NB. return boxed list of operands, with quotes removed
parsecmd =: 3 : 0
NB. If it doesn't end with CRLF, it's an error
if. CRLF -.@-: _2 {. y do.
  0$a:
else.
  cmdwd =. ' ' taketo y
  ops =. ' ' takeafter y
  NB. return the command, and every other quoted string
  cmdwd ; _2 {.\ '"' (= <;._1 ]) ' ' takeafter y
end.
)

DEFAULTPWS =: ; ,&LF&.> 'Read:';'Write:';'Execute:'
NB. y is name of dir; password.  filesystemroot is assumed
NB. Result is highest level allowed (0=r, 1=w, 2=x)
checkpassword =: 3 : 0
'dir pw' =. y
dir =. fmtdirname dir  NB. clean and boxed, and ending with \
NB. Loop through the password files.  A password entry can be omitted, which matches nothing;
NB. or empty, which means inherit from the previous level.
NB. We stop looking when there is no inheritance
inheritkeys =. ;: 'Read Write Execute'
keyslist =. 0 2$a:
NB. Init authorized for nothing
authlevel =. _1
NB. Loop till we have examined all directories or there is no inheritance.
whilst. #inheritkeys do.
  NB. Read the password file
  pwfile =. 1!:1 :: (DEFAULTPWS"_) filesystemroot ,&.> dir ,&.> PASSWORDFN
  NB. Extract the keyword;value pairs
  pwkeys =. (':' (taketo ; takeafter) (CRLF,' ') -.~ ]);._2 pwfile , LF
  NB. Keep the keys that we are looking for (not the inheritance lines)
  keyslist =. keyslist , inheritkeys keepkl (<'') 1 delkl_colsu pwkeys
NB. obsolete   NB. If read/write keys omitted, increase auth level accordingly
NB. obsolete   authlevel =. authlevel >. <: 0 i:~ 0 , (;: 'Read Write') e. keyskl pwkeys
  NB. Keep any inheritance strings that have empty records here
  inheritkeys =. inheritkeys setintersect (<'') 1 allgetkl_colsuv 0 pwkeys
  NB. Look at the next directory up in the hierarchy.  If we are at the top now, quit looking
  if. 0=#>dir do. break. end.
  dir =. (}.~ i.&'\')&.|.@}:&.> dir
end.
NB. Find lines that match the given pw; take priority; return highest
authlevel >. >./ (;: 'Read Write Execute') i. (<pw) 1 allgetkl_colsuv 0 keyslist
)

NB. The list of valid commands
cmdlist =: ;: 'INCR GET PUT APPEND TS LS LSX RM MKDIR RMDIR EXE RENAME RESTART'
DIRCHARS =: ''',_-\ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '
FNCHARS =: DIRCHARS , '.'
WILDCHARS =: FNCHARS,'?*'

NB. INCR "directory" "filename" "offset" CRLF data
NB. The data is appended to the file; then all the file data after "offset" is returned as the result
NB. We do not log this command, for performance reasons
cmdproc_INCR =: 3 : 0
'cmd data' =. y
NB. parse & audit command line
if. 4 ~: # pcmd =. parsecmd cmd do.
 rcdl =. 510;'Parameter error'
else.
  NB. cmd, directory, filename, offset
  'cmd dir fn ofst' =. pcmd
  NB. If the requested file is the cached file, we can skip the validation of the file
  dirfn =. }: > fmtdirname ,&dir &.> filesystemroot
  fullfn =. (dirfn , '\')&, fn =. '/\'&xlatechars fn
  rcdl=.''  NB. init no error status
  if. fullfn -: incrfn_sockfileserver_ do.
  NB. Verify directory exists
  elseif. # DIRCHARS -.~ dir =. }: > fmtdirname '/\' xlatechars dir do.
    rcdl =. 511;'Invalid directory'
  elseif. 1 ~: #dirlist =. 1!:0 dirfn do.
    rcdl =. 512;'Directory not found'
  elseif. -. finfoisdir dirlist do.
    rcdl =. 513;'Not directory'
  elseif.
  # FNCHARS -.~ dirnameonly@((dir,'\')&,) fn do.
    rcdl =. 514;'Invalid filename: ' , ((dir,'\')&,) fn
  elseif. # WILDCHARS -.~ fn do.
    rcdl =. 515;'Invalid filename:' , fn
  end.
  if. 0=#rcdl do.
    if. 0 > authlevel =. checkpassword dir;password do.
      rcdl =. 516;'Invalid credentials'
    else.
NB. All audits OK, process the increment
NB. security elseif. 
NB. security NB. Remove password files
NB. security 0 = #flist =. HIDDENFILES (-.@e.~&:(toupper&.>) 0&{"1) usedtocull^:(authlevel<2) flist do.
NB. security   rcdl =. 201;''  NB. no files; return empty
NB. security NB. Also remove directories if we don't have execute privilege, or if this is not LS
NB. security elseif. 0 = #flist =. (-.@finfoisdir) usedtocull^:((ls~:1) +. authlevel<2) flist do.
NB. security   rcdl =. 202;''  NB. no files; return empty
      NB. If the file is not cached, read or create it
      if. fullfn -.@-: incrfn_sockfileserver_ do.
        incrdata_sockfileserver_ =: 1!:1 :: (''"_) <fullfn  NB. if nonexistent, call it empty
        incrfn_sockfileserver_ =: fullfn
      end.
      NB. Append the user's data, discard data the user already has
      if. #data do.
        incrdata_sockfileserver_ =: incrdata_sockfileserver_ , data
        (data) 1!:3 <fullfn  NB. would be better to wait till data has been sent, but we don't allow that
      end.
      rcdl =. 200 ; (0 ". offset) }. incrdata_sockfileserver_   NB. Return the data that's new to the user
    end.
  end.
end.
rcdl  NB. no log
)

NB. GET "directory" "filename"... CRLF
NB. filename may include wildcard at the lowest level
NB. read permission is required
NB. Returned data is sequence of fn<TAB>length<CRLF>data
cmdproc_GETLS =: 4 : 0
ls =. x
'cmd data' =. y
logadd _2 }. cmd   NB. Log the command
NB. parse & audit command line
if. 3 > # pcmd =. parsecmd cmd do.
 rcdl =. 510;'Parameter error'
NB. Verify directory exists
elseif.
NB. cmd, directory, list of filenames
'cmd dir' =. 2 {. pcmd
fn =. 2 }. pcmd
# DIRCHARS -.~ dir =. }: > fmtdirname '/\' xlatechars dir do.
  rcdl =. 511;'Invalid directory'
elseif. 1 ~: #dirlist =. 1!:0 dirfn =. }: > fmtdirname ,&dir &.> filesystemroot do.
  rcdl =. 512;'Directory not found'
elseif. -. finfoisdir dirlist do.
  rcdl =. 513;'Not directory'
elseif.
fullfn =. (dirfn , '\')&,&.> fn =. '/\'&xlatechars&.> fn
# FNCHARS -.~ ; dirnameonly@((dir,'\')&,)&.> fn do.
  rcdl =. 514;'Invalid filename: ' , ;:^:_1 ((dir,'\')&,)&.> fn
elseif. # WILDCHARS -.~ ; fn do.
  rcdl =. 515;'Invalid filename:' , ; fn
elseif. 0 > authlevel =. checkpassword dir;password do.
  rcdl =. 516;'Invalid credentials'
elseif. -. *./ (= {.) dirnameonly&.> fullfn do.
  rcdl =. 517;'Heterogeneous files'
NB. All audits OK, read the files and return them
elseif. 0 = #flist =. 1!:0"0 endtoend fullfn do.
  rcdl =. 203;''  NB. no files
elseif. 
NB. If we don't have execute privilege, remove password files
0 = #flist =. HIDDENFILES (-.@e.~&:(toupper&.>) 0&{"1) usedtocull^:(authlevel<2) flist do.
  rcdl =. 201;''  NB. no files; return empty
NB. Also remove directories if we don't have execute privilege, or if this is not LS
elseif. 0 = #flist =. (-.@finfoisdir) usedtocull^:((ls~:1) +. authlevel<2) flist do.
  rcdl =. 202;''  NB. no files; return empty
elseif. do.
  flist =. /:~ flist   NB. return files in sorted order
  select. ls
  case. 0 do.
    NB. GET - return data
    totalfn =. (dirnameonly > {. fullfn)&,&.> localfn =. 0 {"1 flist
    NB. First, the file table, each file fn<TAB>length<CRLF>
    NB. Then a CRLF to end the table, then all the files following
    rcdl =. 200 ; (;@:(localfn&((,   TAB , CRLF ,~ ":@#)&.>)) , CRLF , ;) <@(1!:1) totalfn
  case. 1 do.
    NB. LS - return directory info
    NB. Each file is fn<TAB>date<TAB>size<TAB>permissions<TAB>flags<CRLF>
    rcdl =. 200 ; CRLF tabfmt flist
  case. 2 do.
    NB. LSX - return directory info with checksum
    NB. Each file is fn<TAB>date<TAB>size<TAB>permissions<TAB>flags<TAB>checksum<CRLF>
    totalfn =. (dirnameonly > {. fullfn)&,&.> localfn =. 0 {"1 flist
    rcdl =. 200 ; CRLF tabfmt flist ,. <@":@fileserv_checksum@(1!:1) totalfn
  end.
end.
logadd 'Return code: ' , ":0{::rcdl
rcdl
)
cmdproc_GET =: 0&cmdproc_GETLS
cmdproc_LS =: 1&cmdproc_GETLS
cmdproc_LSX =: 2&cmdproc_GETLS

NB. PUT "directory" "filename" ["len" "filename" "len"...] CRLF filedata
NB. APPEND "directory" "filename" ["len" "filename" "len"...] CRLF filedata
NB. RM "directory" "filename" ["filename"...] CRLF
NB. TS "directory" "filename" CRLF filedata
NB. filename may not include wildcard
NB. write permission is required
NB. x encodes RM/TS/PUT/APPEND
cmdproc_PUTRM =: 4 : 0
rm =. x
'cmd data' =. y
logadd _2 }. cmd   NB. Log the command
NB. parse & audit command line
if. 3 > # pcmd =. parsecmd cmd do.
  rcdl =. 510;'Parameter error'
NB. Verify directory exists
elseif. 
'cmd dir' =. 2 {. pcmd
fnl =. 2 }. pcmd
# DIRCHARS -.~ dir =. }: > fmtdirname '/\' xlatechars dir do.
  rcdl =. 511;'Invalid directory'
elseif. 1 ~: #dirlist =. 1!:0 dirfn =. }: > fmtdirname ,&dir &.> filesystemroot do.
  rcdl =. 512;'Directory not found'
elseif. -. finfoisdir dirlist do.
  rcdl =. 513;'Not directory'
elseif.
NB. For PUT/APPEND/TS (i. e. anything with data) split the data into pieces and remove the length fields, and box
if. rm > 0 do.   NB. not RM
  if. 2 < #fnl do.   NB. Multiple files
    NB. Get fn, lengths
    'fnl len' =. <"1 |: _2 ]\ fnl
    data =. data <@substr~ (,.~ +/\@(|.!.0)) {.@(0&".)@> len
  else.   NB. Single file
    fnl =. 1 {. fnl  NB. If length given, ignore it, write all data
    data =. ,<data  NB. Match shape of fnl otherwise
  end.
end.
NB. Now fnl is filename(s), data is data (boxed)
fullfn =. (dirfn , '\')&,&.> fnl =. '/\'&xlatechars&.> fnl
# FNCHARS -.~ ; fnl do.
  rcdl =. 515;'Invalid filename: ' , ;:^:_1 fnl
elseif. 1 > authlevel =. checkpassword dir;password do.
  rcdl =. 516;'Invalid credentials'
elseif. 
NB. Verify that the file, if it exists, is not a directory
NB. J6.02 bug
t =. #flist =. 1!:0@> endtoend fullfn  NB. set result to 'file exists'
if. #flist do. t =. +./ finfoisdir flist end.
t do.  NB. and if 'directory' 
  rcdl =. 517;'Is directory'
elseif. 
NB. If we don't have execute privilege, don't allow password file
(authlevel < 2) *. +./ HIDDENFILES e.~&:(toupper&.>) filenameonly&.> fullfn do.
  rcdl =. 518;'Protected'
elseif. do.
  select. rm
  case. 0 do.   NB. RM
    NB. RM - erase the file(s).  OK if is doesn't exist.
    1!:55 :: 0:"0 fullfn
    rcdl =. 200;''
  case. 1 do.
    NB. TS - write the file only if nonexistent, error if multiple files
    if. 1 < #fnl do.
      rcdl =. 519 ; 'Multiple filespecs'
    elseif. 0 ~: #flist do.
      NB. TS for file that exists: return success with the file data, with leading '*'
      rcdl =. 200 ; '*' , 1!:1 {. fullfn
    elseif. do.
      NB. TS for nonexistent file, write the data
      data (>@[ 1!:2 ])"0 fullfn  NB. Write the file
      rcdl =. 200;''  NB. success
    end.
  case. do.   NB. PUT/APPEND
    data (>@[ 1!:rm ])"0 fullfn  NB. Write/append the file
    rcdl =. 200;''  NB. success
  end.
end.
logadd 'Return code: ' , ":0{::rcdl
rcdl
)
cmdproc_RM =: 0&cmdproc_PUTRM
cmdproc_TS =: 1&cmdproc_PUTRM
cmdproc_PUT =: 2&cmdproc_PUTRM
cmdproc_APPEND =: 3&cmdproc_PUTRM

NB. RENAME "directory" "fnfrom" "fnto" CRLF
NB. no wildcards allowed
NB. write permission is required
NB. nothing returned
cmdproc_RENAME =: 3 : 0
'cmd data' =. y
logadd _2 }. cmd   NB. Log the command
NB. parse & audit command line
if. 4 ~: # pcmd =. parsecmd cmd do.
  rcdl =. 510;'Parameter error'
NB. Verify directory exists
elseif.
NB. cmd, directory, fns
'cmd dir' =. 2 {. pcmd
fn =. 2 3 { pcmd
# DIRCHARS -.~ dir =. }: > fmtdirname '/\' xlatechars dir do.
  rcdl =. 511;'Invalid directory'
elseif. 1 ~: #dirlist =. 1!:0 dirfn =. }: > fmtdirname ,&dir &.> filesystemroot do.
  rcdl =. 512;'Directory not found'
elseif. -. finfoisdir dirlist do.
  rcdl =. 513;'Not directory'
elseif.
fullfn =. ((>dirfn) , '\')&,&.> fn =. '/\'&xlatechars&.> fn
# FNCHARS -.~ ; dirnameonly@((dir,'\')&,)&.> fn do.
  rcdl =. 514;'Invalid filename:' , ; ((dir,'\')&,)&.> fn
elseif. # FNCHARS -.~ ; fn do.
  rcdl =. 515;'Invalid filename:' , ; fn
elseif. 1 > authlevel =. checkpassword dir;password do.
  rcdl =. 516;'Invalid credentials'
elseif. -. *./ (= {.) dirnameonly&.> fullfn do.
  rcdl =. 517;'Heterogeneous files'
elseif. (1 , -:&toupper&>/ fullfn) -.@-: *@#@> dirf =. 1!:0&.> fullfn do.
  rcdl =. 518;'Existence error'
elseif. +./ finfoisdir ; dirf do.
  rcdl =. 519;'Is directory'
elseif. (authlevel<2) *. +./ HIDDENFILES (e.~&:(toupper&.>) 0&{"1) ; dirf do.
  rcdl =. 520;'Protected file'
elseif. do.
  NB. All audits OK, do the rename
  renamefile~/ fullfn  NB. y (from) to x (to)
  rcdl =. 200;''
end.
logadd 'Return code: ' , ":0{::rcdl
rcdl
)

NB. MKDIR "directory"
NB. We create the directory as long as it doesn't exist
NB. Requires execute privilege
cmdproc_MKDIR =: 3 : 0
'cmd data' =. y
logadd _2 }. cmd   NB. Log the command
NB. parse & audit command line
if. 2 ~: # pcmd =. parsecmd cmd do.
  rcdl =. 510;'Parameter error'
elseif. 
NB. Verify directory does not exist
'cmd dir' =. 2 {. pcmd
# DIRCHARS -.~ dir =. }: > fmtdirname '/\' xlatechars dir do.
  rcdl =. 511;'Invalid directory'
elseif. 0 ~: #dirlist =. 1!:0 dirfn =. }: > fmtdirname ,&dir &.> filesystemroot do.
  rcdl =. 512;'Exists'
elseif. 2 > authlevel =. checkpassword dir;password do.
  rcdl =. 516;'Invalid credentials'
elseif. do.
  1!:5 <dirfn
  rcdl =. 200;''
end.
logadd 'Return code: ' , ":0{::rcdl
rcdl
)

NB. RMDIR "directory"
NB. We delete the directory, recursively.
NB. Requires execute privilege
cmdproc_RMDIR =: 3 : 0
'cmd data' =. y
logadd _2 }. cmd   NB. Log the command
NB. parse & audit command line
if. 2 ~: # pcmd =. parsecmd cmd do.
  rcdl =. 510;'Parameter error'
elseif. 
NB. Verify directory exists
'cmd dir' =. 2 {. pcmd
# DIRCHARS -.~ dir =. }: > fmtdirname '/\' xlatechars dir do.
  rcdl =. 511;'Invalid directory'
elseif. 1 ~: #dirlist =. 1!:0 dirfn =. }: > fmtdirname ,&dir &.> filesystemroot do.
  rcdl =. 200;'Does not exist'
elseif. dirfn <:&# > filesystemroot do.
  rcdl =. 512;'Is root'
elseif. 2 > authlevel =. checkpassword dir;password do.
  rcdl =. 516;'Invalid credentials'
elseif. do.
  rmdashr <dirfn
  rcdl =. 200;''
end.
logadd 'Return code: ' , ":0{::rcdl
rcdl
)

NB. Recursive delete.  We recur on subdirectories, then delete all files, then
NB. delete this directory
rmdashr =: 3 : 0"0
files =. 1!:0 '\*' ,~ dir =. > y
rmdashr ifany (dir,'\')&,&.> 0 {"1 finfoisdir usedtocull files
1!:55 dir&,&.> a: ,~ '\'&,&.> 0 {"1 -.@:finfoisdir usedtocull files
NILRET
)

NB. RESTART
NB. We reload the app from the name we found it in, in the root directory
NB. Requires execute privilege in the root directory
NB. This does not rerun the startup verbs - it just reloads the executing code.
cmdproc_RESTART =: 3 : 0
'cmd data' =. y
logadd _2 }. cmd   NB. Log the command
NB. parse & audit command line
if. 2 > authlevel =. checkpassword '';password do.
  516;'Invalid credentials'
elseif. do.
  NB.?lintmsgsoff
  0!:0 ,&APPFILENAME_base_&.> filesystemroot
  NB.?lintmsgson
  200;''
end.
)

NB. Verbs to create and use the transfer format
NB. These verbs create a message or parse a message

NB. Add request header to a message
NB. y is message body
NB. x is parms:
NB. password;compression
NB. Result is header followed by message.  We always add a Content-Length field.
fileserv_addreqhdr =: 4 : 0
'pw comp' =. x default '';0
NB. Start with an HTTP request-type
h =. 'GET /index.html/ HTTP/1.1' , CRLF
NB. Continue with an HTTP header
h =. h , 'Content-Length: ' , (":#y) , CRLF
NB. Always send Password - it's our unique field
NB. obsolete if. #pw do.
h =. h , 'X-QBPassword: ' , pw , CRLF
NB. Append other things to pacify gateways
h =. h , 'Cache-Control: no-cache' , CRLF
h =. h , 'Content-Encoding: quizbowl' , CRLF
h =. h , 'Host: www.quizbowlmanager.com' , CRLF
NB. obsolete end.
NB. Our actual request data follows the double CRLF
h,CRLF,y
)

NB. Analyze request header
NB. y is header (ends with CRLFCRLF)
NB. Result is rc;length;password;compression
NB. rc is 0 if ok
fileserv_decreqhdr =: 3 : 0
NB. Assume good return
rc =. 0
NB. Split on LF; remove CRLF
lines =. (<'') -.~ <@(-.&CRLF);._2 y , LF
NB. Split each line into name;value
namval =. (({.~ ; (}.~ 2&+)) ': '&(i.&1@:E.))@> lines
NB. get password if any.  If none, reject the command
if. #pwfields =. (<'X-QBPassword') keepkl namval do.
  pw =. (<'X-QBPassword') '' getklu_defu_colsv (0;1) pwfields
else.
  'pw rc' =. '';1
end.
NB. No compression for now
comp =. 0
NB. Get length (required)
if. 0 = len =. {. 0 ". (<'Content-Length') '' getklu_defu_colsv (0;1) namval do.
  rc =. 1
end.
NB. To avoid spam, reject any message that uses headers we don't support
NB. No - we can't - proxies may insert header fields
NB. obsolete if. # (keyskl namval) -. ('Content-Length';'Password';'Compression') do.
NB. obsolete   rc =. 2
NB. obsolete end.
rc;len;pw;comp
)

NB. Add response header to a message
NB. x is retcode
NB. y is message body
NB. Result is nnn HTTP CRLF;hdr incl length;body
fileserv_addrsphdr =: 4 : 0
NB. The reason-phrase depends on the return value.  If the return-value is OK (200-205), use 'OK';
NB. otherwise use y
if. >/ x >: 200 206 do. rp =. ' OK'
else. rp =. ' ' , ({.~ CRLF&(i.&1@:E.)) y
end.
h =. 'Content-Length: ' , (":#y) , CRLF
'HTTP/1.1 ' , (":x) , rp , CRLF , h , CRLF , y
)

NB. Analyze response
NB. y is data read
NB. result is rc;data
NB. We check for length
fileserv_decrsphdr =: 3 : 0
NB. Strip header
msghdr =. ( {.~ (CRLF,CRLF)&(#@[ + (i.&1@:E.)) ) y
NB. Get rc line from header
msgrc =. 2 {. <;._1 ' ' , ({.~ CRLF&(i.&1@:E.)) msghdr
if. msgrc -.@e. (<'HTTP/1.1'),.('200';'201';'202';'203';'204';'205') do.
  NB. If not valid response, return error
  (({.!.999) 999 ". 1 {:: msgrc);y 
elseif.
  NB. Get the Content-Length from the header
  NB. Split on LF; remove CRLF
  lines =. <@(-.&CRLF);._2 msghdr
  NB. Split each line into name;value
  namval =. (({.~ ; (}.~ >:)) ': '&(i.&1@:E.))@> lines
  len =. {. 0 ". pw =. (<'Content-Length') '' getklu_defu_colsv (0;1) namval
  len ~: y -&# msghdr do.
  998 ; ''
elseif. do.
  0 ; (#msghdr) }. y
end.
)

NB. Calculate checksum for a file.
NB. y is string, result is checksum (numeric)
fileserv_checksum =: 3 : 0"1
128!:3 y
)
