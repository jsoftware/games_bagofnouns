require 'socket'
require 'strings'
sdcleanup_jsocket_ =: 3 : '0[(sdclose ::0:"0@[ shutdownJ@(;&2)"0)^:(*@#)SOCKETS_jsocket_'
NB. Game states
GSHELLO =: 0  NB. Initial login at station: clear username, clear incrhwmk
GSLOGINOK =: 1  NB. OK to log in
GSAUTH =: 2  NB. Authenticating credentials
NB. All the rest require a login to enable any buttons
GSWORDS =: 3  NB. waiting for words to be entered
GSWACTOR =: 4  NB. waiting for an actor
GSWSCORER =: 5   NB. Waiting for a scorer
GSWSTART =: 6   NB. Waiting for Start button
GSACTING =: 7  NB. Acting words
GSPAUSE =: 8   NB. Clock stopped during a round
GSSETTLE =: 9  NB. Final scoring actions
GSCONFIRM =: 10  NB. last chance to go back
GSCHANGE =: 11   NB. Changing the round
GSCHANGEWACTOR =: 12  NB. Waiting for actor to decide whether they want a scorer
GSCHANGEWSCORER =: 13   NB. Changing the round in the middle of a turn, waiting for scorer
GSCHANGEWSTART =: 14   NB. Changing the round in the middle of a turn, waiting to restart
GSGAMEOVER =: 15

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
pc formbon escclose closeok;
menupop Teams;
menu fmteamshow "Show teams";
menupopz;
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
menupop "Time for charades";
menu fmcharades60 "60 seconds";
menu fmcharades90 "90 seconds";
menupopz;
menupopz;
bin g;
grid shape 1 2;
grid colwidth 0 500; grid colwidth 1 100;
grid colstretch 0 5; grid colstretch 1 1;
 rem left side: the display;
 bin g;
 grid shape 6 1;
 grid rowheight 0 100; grid rowheight 1 50; grid rowheight 2 200; grid rowheight 3 200; grid rowheight 4 200; grid rowheight 5 50;
 grid rowstretch 0 1; grid rowstretch 1 1; grid rowstretch 2 2; grid rowstretch 3 2; grid rowstretch 3 2; grid rowstretch 5 1;
  rem top row: scores & login;
  bin h;
   bin h;
    bin s1;cc fmscoreadj0 edit center;set fmscoreadj0 inputmask #d;set fmscoreadj0 wh 20 20;bin s1;
    cc fmscore0 static center;set fmscore0 minwh 40 40;set fmscore0 sizepolicy expanding;set fmscore0 font "Courier New" 128 bold;
   bin z;
   bin s;
   bin v;
     cc fmlogin combobox;set fmlogin minwh 200 20;
     cc fmloggedin static center;set fmloggedin minwh 300 30;;set fmloggedin sizepolicy expanding fixed;set fmloggedin font "Courier New" 16 bold;
   bin z;
   bin s;
   bin h;
    cc fmscore1 static center;set fmscore1 minwh 40 40;set fmscore1 sizepolicy expanding;set fmscore1 font "Courier New" 128 bold;
    bin s1;cc fmscoreadj1 edit center;set fmscoreadj1 inputmask #d;set fmscoreadj1 wh 20 20;bin s1;
   bin z;
  bin z;
  rem row 2: progress bar;
  cc fmprogress progressbar 0 60 60;set fmprogress minwh 200 10;set fmprogress sizepolicy ignored fixed;
  rem row 3: general display;
  cc fmgeneral edith;set fmgeneral edit 0;set fmgeneral sizepolicy expanding;set fmgeneral font "Courier New" 32 bold;
  rem row 4: move to the next word;
  bin h;
   cc fmretire0 button;set fmretire0 sizepolicy expanding;set fmretire0 font "Courier New" 64 bold;set fmretire0 text "Don't Know It"; 
   cc fmretire1 button;set fmretire1 sizepolicy expanding;set fmretire1 font "Courier New" 64 bold;set fmretire1 text "Pass";
   cc fmretire2 button;set fmretire2 sizepolicy expanding;set fmretire2 font "Courier New" 64 bold;set fmretire2 text "Got It";
  bin z;
  rem row 5: general purpose buttons;
  bin h;
   cc fmsieze0 button;set fmsieze0 sizepolicy expanding;set fmsieze0 font "Courier New" 32 bold;set fmsieze0 text ""; 
   cc fmsieze1 button;set fmsieze1 sizepolicy expanding;set fmsieze1 font "Courier New" 32 bold;set fmsieze1 text ""; 
  bin z;
  rem row 6: status line;
  cc fmstatus static;set fmstatus sizepolicy ignored fixed;set fmstatus font "Courier New" 32 bold;
 bin z;
 rem right side: event log;
 cc fmlog edith;set fmlog wrap;set fmlog sizepolicy expanding;
bin z;
pas 0 0;
)
cleargame=:0
formbon_run =: 3 : 0
NB. Connect to the background
sk =: 1 {:: sdsocket_jsocket_ ''
thismachine =: sdgethostbyname_jsocket_ 'localhost'
NB. sdioctl_jsocket_ sk , FIONBIO_jsocket_ , 1  NB. Make socket non-blocking
rc =. sdconnect_jsocket_ sk;(}.thismachine),<8090  NB. start connecting
qprintf'sk '
if. -. sk e. 2 {:: sdselect_jsocket_ '';sk;'';4000 do. 'Error connecting to background' 13!:8 (4) end.
NB. Start with a message to say we arrived.  The response must set all our globals
backcmd 'HELLO ',":cleargame
cleargame=:0  NB. Don't do it again accidentally
wd FORMBON
wd 'set fmretire0 text *Don''t',LF,'Know It'
wd 'set fmretire2 text *Got',LF,'It'
wd 'pshow'
NB. Start a heartbeat
nextheartbeat =: 6!:1''
wd 'ptimer 50'
)

formbon_close =: 3 : 0
wd 'pclose'
)
formbon_cancel =: formbon_close

formbon_timer =: 3 : 0
try.
if. nextheartbeat < 6!:1'' do.
  backcmd ''   NB. Send heartbeat msg every second
  nextheartbeat =: nextheartbeat + 1.   NB. schedule next heartbeat
end.
if. sk e. 1 {:: sdselect_jsocket_ sk;'';'';0 do.
smoutput'data from BE '
  cmdqueue =. 0$a:   NB. list of commands in this batch
  hdr =. ''   NB. No data, no bytes of header
  while. do.   NB. Read all the commands that are queued
    NB. There is data to read.  Read it all, until we have the complete message.  First 4 bytes are the length
    while. do.
      'rc data' =. sdrecv_jsocket_ sk,(4-#hdr),00   NB. Read the length, from 2 (3!:4) #data
      if. rc~:0 do. 'Error reading from background' 13!:8 (4) end.
      if. 0=#data do. 'Connection closed by background, restart' 13!:8 (5) end.
      hdr =. hdr , data
      if. 4=#hdr do. break. end.
      if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';4000 do. 'Error reading from background' 13!:8 (4) end.
    end.
    hlen =. _2 (3!:4) hdr   NB. Number of bytes to read
    readdata =. ''
    while. do.
      'rc data' =. sdrecv_jsocket_ sk,(4+hlen),00   NB. Read the data
      if. rc~:0 do. 'Error reading from background' 13!:8 (4) end.
      if. 0=#data do. 'Connection closed by background, restart' 13!:8 (5) end.
      hlen =. hlen-#data  NB. decr count left
      if. hlen <: 0 do. cmdqueue =. cmdqueue , < readdata , hlen }. data break. end.
      readdata =. readdata , data
      if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';4000 do. 'Error reading from background' 13!:8 (4) end.
    end.
    if. hlen=0 do. break. end.
    hdr =. hlen {. data
  end.
  wd 'psel formbon'
  proccmds cmdqueue
end.
catch.
  wd'psel formbon;ptimer 0'
  smoutput'error in timer handler'
  sdclose_jsocket_ sk  NB. If the background closed the socket, let it close properly
end.
i. 0 0
)

NB. Send the command in y, prefixed by length
backcmd =: 3 : 0
senddata =. (2 (3!:4) #y) , y   NB. prefix the data with 4-byte length
while. #senddata do.
  if. -. sk e. 2 {:: sdselect_jsocket_ '';sk;'';1000 do. 'Error writing to background' 13!:8 (4) end.
  rc =. senddata sdsend_jsocket_ sk,0
  if. 0~:0{::rc do. ('Error ',(":0{::rc),'writing to background') 13!:8 (4) end.
  if. 0=byteswritten =. 1 {:: rc do. ('No data written to background') 13!:8 (4) end.
  senddata =. byteswritten }. senddata
end.
i. 0 0
)

NB. Order of processing state info
statepri =: (;: 'Glogin Groundtimes Gstate Gteams Groundno Gactor Gscorer Gteamup Gawaystatus Gwordstatus Glogtext Gwordqueue Gwordundook Gscore Gtimedisp')
NB. Process the command queue, which is a list of boxes.  Each box contains
NB. the 5!:5 of a table of state information, as
NB. infotype ; value
NB. We convert the values to internal form and assign them to the names Ginfotype; then
NB. we drive handlers for all the changed values.  We visit the handlers in a priority order.
NB. We collect all the changed values for all commands before we drive any of the handlers
NB. y cannot be empty
proccmds =: 3 : 0
qprintf'y '
NB. Turn each input into a boxed table of name ; value
NB. Run the tables together, keep the latest of each
cmds =. ((~.@[ ,. ({:/. {:"1))~ {."1) ; ".&.> y
NB. Assign values to names
({."1 cmds) =: {:"1 cmds
NB. Start with the lowest modified state, and then all handlers till the end
wd 'psel formbon'
for_h. statepri (<./@:i. }. [) {."1 cmds do. ('hand',>h)~ '' end.
''
)
NB. The handlers, in priority order.  They all return empty
handGlogin =: 3 : 0
loggedin =: *@#Glogin
wd 'set fmloggedin text *', ('nobody'&[^:(0=#) Glogin) , ' is logged in'
)

handGroundtimes =: 3 : 0
wd 'set fmcharades60 checked ' , ": 60 = 1 { Groundtimes
wd 'set fmcharades90 checked ' , ": 90 = 1 { Groundtimes
''
)

Gteamnames =: 'Team 0';'Team 1'

NB. Button-enable based on state
NB. rows are buttons, columns are state. c1 is always 1, l1 only if logged in
NB.             HELLO LOGINOK AUTH WORDS WACTOR WSCORER WSTART ACTING PAUSE SETTLE CONFIRM CHANGE CHANGEWACTOR CHANGEWSCORER CHANGEWSTART GAMEOVER
statetoenable =: ;:;._2 (0 : 0)
fmteamshow       l0     l0     l0   l1     l1     l1      l1     l1    l1     l1     l1     l1      l1             l1             l1         c0
fmawaybrb        l0     l0     l0   l1     l1     l1      l1     l1    l1     l1     l1     l1      l1             l1             l1         c0
fmawaygone       l0     l0     l0   l1     l1     l1      l1     l1    l1     l1     l1     l1      l1             l1             l1         c0
fmtimerp5        l0     l0     l0   l0     l0     l0      l0     l1    l1     l1     l0     l0      l0             l0             l0         c0
fmtimerp15       l0     l0     l0   l0     l0     l0      l0     l1    l1     l1     l0     l0      l0             l0             l0         c0
fmtimerm5        l0     l0     l0   l0     l0     l0      l0     l1    l1     l1     l0     l0      l0             l0             l0         c0
fmtimerm15       l0     l0     l0   l0     l0     l0      l0     l1    l1     l1     l0     l0      l0             l0             l0         c0
fmteamdeal       l0     l0     l0   l1     l0     l0      l0     l0    l0     l0     l0     l0      l0             l0             l0         c0
fmcharades60     l0     l0     l0   l1     l0     l0      l0     l0    l0     l0     l0     l0      l0             l0             l0         c0
fmcharades90     l0     l0     l0   l1     l0     l0      l0     l0    l0     l0     l0     l0      l0             l0             l0         c0
fmscoreadj0      l0     l0     l0   l0     l0     l0      l0     l0    l0     l1     l1     l0      l0             l0             l0         c0
fmlogin          c0     l1     l1   c1     c1      a       as     as    as     as    as     as      as              a              a         c0
fmscoreadj1      l0     l0     l0   l0     l0     l0      l0     l0    l0     l1     l1     l0      l0             l0             l0         c0
fmretire0        l0     l0     l0   l0     l0     l0      l0      S     S      S     l0     l0      l0             l0             l0         c0
fmretire1        l0     l0     l0   l0     l0     l0      l0      S     S      S     l0     l0      l0             l0             l0         c0
fmretire2        l0     l0     l0   l0     l0     l0      l0      S     S      S     l0     l0      l0             l0             l0         c0
fmsieze0         l0     l0     l0   l1      T     A       S     l1     S      A      A      A       A              A               S         c0
fmsieze1         l0     l0     l0   l0      T     l1      AS     Sw    Sw     Aw     Aw     l0      A              l1             AS         c0
)

handGstate =: 3 : 0
NB. Set conditional enables
'c0 c1 l0 l1' =. ":"0 , (1,loggedin) *./ 0 1
'a s as A S AS' =. ":"0 (3 # 1,loggedin) *. (Glogin -: Gactor) (-.@[ , -.@] , +: , [ , ] , +.) (Glogin -: Gscorer)
T =. ":"0 (<Glogin) e. Gteamup {:: Gteams
NB. Select the column; get mask to discard 'Sw', which we do later
EM   =: enmsk =. ('Sw';'Aw') -.@:e.~ EV   =: envals =. (>:Gstate) {"1 statetoenable
NB. Set all the enables
({."1 statetoenable) ([: wd 'set ',[,' enable ',".@])&>&(enmsk&#) envals
NB. Set display for the variable buttons
wd 'set fmsieze0 text *' , (1;((0{::buttoncaptions0) i. Gstate)) {:: buttoncaptions0
wd 'set fmsieze1 text *' , (1;((0{::buttoncaptions1) i. Gstate)) {:: buttoncaptions1
NB. Display the status line
select. Gstate
case. GSHELLO do. text =. 'Catching up'
case. GSLOGINOK do. text =. 'OK to login'
case. GSAUTH do. text =. 'Waiting for authorization'
case. GSWORDS do. text =. 'Players are entering words'
case. GSACTOR do. text =. 'Need actor for ' (Groundno {:: 'Taboo';'Charades';'Password'), ' from ' , Gteamup {:: Gteamnames
case. GSWSCORER do. text =. 'Need someone to score for ' , Gactor
case. GSWSTART do. text =. 'Waiting for ' , Gscorer , ' to start the clock'
case. GSACTING do. text =. Gactor , ' is acting ' , (Groundno {:: 'Taboo';'Charades';'Password') , ' and ' , ((Gactor -.@-: Gscorer) # Gscorer , ' is ') , 'scoring'
case. GSPAUSE do. text =. 'Clock is stopped while ' , Gactor , ' is acting ' , (Groundno {:: 'Taboo';'Charades';'Password')
case. GSSETTLE do. text =. Gactor , ' is entering scores for the last words'
case. GSCONFIRM do. text =. 'Last chance to change the scores and words for this round'
case. GSCHANGE do. text =. 'End of round.  Changing to ' , Groundno {:: 'Taboo';'Charades';'Password';'Scotch'
case. GSCHANGEWACTOR do. text =. 'Is a scorer needed?' 
case. GSCHANGEWSCORER do. text =. 'Need someone to score for ' , Gactor
case. GSCHANGEWSTART do. text =. 'Waiting for ' , Gscorer , ' to start the clock'
case. GSGAMEOVER do. text =. 'Game Over'
case. do. text =. ''
end.
wd 'set fmstatus text *', text
''
)
buttoncaptions0 =: (<@;)`(<@(,&a:))`(<@(,&a:))"1 ".&.> |: ;:@(LF&(('*'&(I.@:=)@])}));._2 DD   =: (0 : 0)
GSWORDS 'Enter Words*From Clipboard' ''
GSWACTOR 'I will act*and score' 'ACTOR '';1;0'
GSWSCORER 'Undo'    'ACTOR '';0;0'
GSWSTART 'Start the clock'  'ACT 0'
GSACTING 'Stop the clock'  'TIMERADJ 0;0;'''
GSPAUSE 'Start the clock'  'TIMERADJ 1;0;'''
GSSETTLE 'Guessed late:*retire word'   'NEXTWORD 0 1'
GSCONFIRM 'Irrevocably*enter*this score'   'COMMIT 0'
GSCHANGE 'Proceed' 'PROCEED 0'
GSCHANGEWACTOR 'I don''t need*a scorer'   'ACTOR '';1;0'
GSCHANGEWSCORER ''    ''
GSCHANGEWSTART 'Start the clock'  'ACT 0'
)
buttoncaptions1 =: (<@;)`(<@(,&a:))`(<@(,&a:))"1 ".&.> |: ;:@(LF&(('*'&(I.@:=)@])}));._2 DD   =: (0 : 0)
GSWACTOR 'I will act*but I need*a scorer' 'ACTOR '';1;1'
GSWSCORER 'I will score'  'SCORER '';1'
GSWSTART 'Undo'  'SCORER '';0'
GSACTING 'Undo last word' 'PREVWORD 0'
GSPAUSE 'Undo last word'  'PREVWORD 0'
GSSETTLE 'Undo last word'  'PREVWORD 0'
GSCONFIRM 'Undo last word'  'PREVWORD 0'
GSCHANGE '' ''
GSCHANGEWACTOR 'I need*a scorer'   'ACTOR '';1;1'
GSCHANGEWSCORER 'I will score'  'SCORER '';1'
GSCHANGEWSTART 'Undo'  'SCORER '';0'
)

handGteams =: 3 : 0
wd 'set fmlogin items' , ;@:((' "' , ,&'"')&.>) (/: tolower&.>) ; Gteams
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

handGawaystatus =: 3 : 0
if. Gstate=GSWSTART do.
  wd 'set fmgeneral text *' , ; ('BRB: ';'Away: ') (*@#@] # '<br>' ,~ [ , ])&.> Gawaystatus ;:^:_1@-.&.> (-. Gteamup) { Gteams 
end.
wd 'set fmawaybrb value ' , ": loggedin *. (<Glogin) e. 0 {:: Gawaystatus
wd 'set fmawaygone value ' , ": loggedin *. (<Glogin) e. 1 {:: Gawaystatus
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

handGwordqueue =: 3 : 0
if. Gstate e. GSACTING,GSPAUSE,GSSETTLE,GSCONFIRM do.
  if. Glogin -: Gactor do.
    if. #Gwordqueue do.
      wd 'set fmgeneral text *', ; ,&'<br>'&.> {."1 Gwordqueue
    else.
      wd 'set fmgeneral text *No more words'
    end.
  else.
    if. #Gwordqueue do. text =. 'DQ: ' , ;:^:_1 (<0 1) {:: Gwordqueue else. text =. '' end.
    wd 'set fmgeneral text *' , text
  end.
end.
''
)

handGwordundook =: 3 : 0
if. Gstate e. GSACTING,GSPAUSE,GSSETTLE,GSCONFIRM do.
  en =. (*@# Gwordqueue) *. ((Gstate e. GSACTING,GSPAUSE) *. Glogin-:Gscorer) +. ((Gstate e. GSSETTLE,GSCONFIRM) *. Glogin-:Gactor)
  wd 'set fmsieze1 enable ',":loggedin*.en
end.
''
)

handGscore =: 3 : 0
wd 'set fmscore0 text ',(":0 { Gscore),';set fmscore1 text ',":1 { Gscore
''
)

handGtimedisp =: 3 : 0
if. Gstate e. GSWSTART,GSACTING,GSPAUSE,GSSETTLE,GSCHANGE do. wd 'set fmprogress value *',": Gtimedisp end.
''
)


NB. Button processors
formbon_fmlogin_select =: 3 : 0
smoutput 'fmlogin'
smoutput fmlogin
smoutput fmlogin_select
backcmd 'LOGIN ''',fmlogin,''''
i. 0 0
)
formbon_fmscoreadj0_button =: 3 : 0
adj =. ": adjn =. {.!.0 (0)".fmscoreadj0
if. adjn do. backcmd 'SCOREADJ 0;',adj,';''',Glogin'''' end.
i. 0 0
)
formbon_fmscoreadj1_button =: 3 : 0
adj =. ": adjn =. {.!.0 (0)".fmscoreadj1
if. adjn do. backcmd 'SCOREADJ 1;',adj,';''',Glogin'''' end.
i. 0 0
)
formbon_fmteamshow_button =: 3 : 0
i. 0 0
)
formbon_fmawaybrb_button =: 3 : 0
wd 'set fmawaygone value 0'
backcmd 'AWAYSTATUS ''' , Glogin , ''';' , ": fmawaybrb  NB. 0=here, 1=brb, 2=away
i. 0 0
)
formbon_fmawaygone_button =: 3 : 0
wd 'set fmawaybrb value 0'
backcmd 'AWAYSTATUS ''' , Glogin , ''';' , 2 * ": fmawaybrb
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
formbon_fmcharades60_button =: 3 : 0
backcmd 'RDTIME 1 60'  NB. rd#, # seconds
i. 0 0
)
formbon_fmcharades90_button =: 3 : 0
backcmd 'RDTIME 1 90'
i. 0 0
)
formbon_fmretire0_button =: 3 : 0
backcmd 'NEXTWORD 0 0'   NB. score, retirewd
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
formbon_fmsieze0_button =: 3 : 0
if. #capt =. buttoncaptions0 {::~ 2 ; (0{::buttoncaptions0) i. Gstate do.
  NB. Replace ' with 'login'
  backcmd (({.~ , ('''' , Glogin) , }.~) i.&'''')^:(''''&e.) capt
else.
  if. Gstate=GSWORDS do. formbon_words'' end.   NB. empty string means words
end.
i. 0 0
)
formbon_fmsieze1_button =: 3 : 0
NB. Replace ' with 'login'
backcmd (({.~ , ('''' , Glogin) , }.~) i.&'''')^:(''''&e.) buttoncaptions1 {::~ 2 ; (0{::buttoncaptions1) i. Gstate
i. 0 0
)

NB. Get words from clipboard
DIRCHARS =: ''',-/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '
formbon_words =: 3 : 0
try.
  wds =. , wd'clippaste'
  wds =. <;._2 LF ,~ wds -. CR
catch.
  wds =. 0$a:
end.
wds =. deb&.> (e.&DIRCHARS # ])&.> wds  NB. Remove weird characters, excess blanks
wds =. wds -. a:  NB. Remove empty words
if. 0=#wds do. wd'mb info mb_ok "No words" "You didn''t put any words on the clipboard."' return. end.
if. 15<#wds do. wd'mb info mb_ok "Too many words" "You have too many words."' return. end.
if. 30 < >./ #@> wds do. wd'mb info mb_ok "Too long" "One of your words is too long."' return. end.
if. 'ok' -: wd'mb query mb_ok "Is this word list OK?" *', ; ,&LF&.> wds do.
  backcmd 'WORDS ''',Glogin,''' ,&< ' , 5!:5 <'wds'
end.
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
