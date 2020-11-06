require 'socket'
require 'strings'
require'format/printf'
sdcleanup_jsocket_ =: 3 : '0[(sdclose ::0:"0@[ shutdownJ@(;&2)"0)^:(*@#)SOCKETS_jsocket_'

NB. Back end

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
AWAYSTATUS [012] name
TIMER {01} incr name  stop/start, adj
NEXTWORD {-1 0 1} {01}   score, count wd as played
PREVWORD
COMMIT
SCOREADJ incr name
START name
ACTOR name {01}  0 to undo
SCORER name {01}  0 to undo
LOGINREQ name gend by BE
LOGINREJ name gend by BE
TICK    gend by BE
SHOWWORD word  gend by BE
)


0 : 0
startgame 't1000';'1111111'
)
startgame =: 3 : 0
if. (,2) -.@-: $y do. 'Usage: startgame ''tourn-name'';''password''' return. end.
if. 32 ~: 3!:0 y do. 'Usage: startgame ''tourn-name'';''password''' return. end.
if. +./ 2 ~: 3!:0@> y do. 'Usage: startgame ''tourn-name'';''password''' return. end.
initstate''
'tourn password' =: y
sdcleanup_jsocket_''  NB. debugging
lsk =: 1 {:: sdsocket_jsocket_ ''  NB. listening socket
rc =. sdbind_jsocket_ lsk ; AF_INET_jsocket_ ; '' ; 8090  NB. listen on port 8090 
if. 0~:rc do. ('Error ',(":rc),'binding to 8090') 13!:8 (4) end.
NB. obsolete NB. Wait for hello
NB. obsolete sockloop lsk;tourn;password
wd 'timer 50'
waitstate =: 0   NB. no waitmsgs yet
sk =: 0  NB. No FE connection
ssk =: 0  NB. No host connection
gamehistory =: ''  NB. total of entire log
''
)

NB. Return non0 if error
sockpoll =: 3 : 0
NB. obsolete   'qbm sk tourn password' =. y
feconnlost=.0
if. sk e. 1 {:: sdselect_jsocket_ sk;'';'';0 do.
  NB. There is data to read.  Read it all, until we have the complete message(s).  First 4 bytes are the length
  hdr =. ''   NB. No data, no bytes of header
  cmdqueue =. 0$a:  NB. List of commands
  while. do.
    while. 4>#hdr do.
      'rc data' =. sdrecv_jsocket_ sk,(4-#hdr),00   NB. Read the length, from 2 (3!:4) #data
      if. (0~:rc) +. (0=#data) do. feconnlost=.1 break. end.
      hdr =. hdr , data
      if. 4=#hdr do. break. end.
      if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';5000 do. feconnlost=.4 break. end.
    end.
    if. feconnlost do. break. end.
    hlen =. _2 (3!:4) hdr   NB. Number of bytes to read - could be 0
    readdata =. ''
    while. hlen > 0 do.
      if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';5000 do. feconnlost=.2 break. end.
      'rc data' =. sdrecv_jsocket_ sk,(4+hlen),00   NB. Read the data, plus the next length
      if. rc~:0 do. rc return. end.
      if. 0=#data do. feconnlost=.3 break. end.
      readdata =. readdata , data
      hlen=.hlen-#data  NB. when we have all the data, plus possibly the next length
    end.
    if. feconnlost do. break. end.
    NB. If there is not another command, exit to process them
    cmdqueue =. cmdqueue , < hlen }. readdata
    if. hlen = 0 do. if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';0 do. break. end. end.  NB. if hlen<0, we have started reading a length; if 0, must check
    hdr =. hlen {. readdata  NB. transfer the length
    if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';5000 do. feconnlost=.5 break. end.
  end.
  if. feconnlost do. feconnlost [ smoutput 'fe connection lost'  return. end.
  NB. perform pre-sync command processing.
NB. obsolete   if. #;cmdqueue do. smoutput'cmd rcvd' end.  NB. scaf
  senddata =. (<password) fileserv_addreqhdr_sockfileserver_  ('MULTI "' , tourn , '" "bonlog" "' , (":incrhwmk) , '"',CRLF) , ; presync cmdqueue
  NB. Create a connection to the server and send all the data in an INCR command
  if. 0=ssk do.  NB. If we don't have an open connection, make one
    for_dly. 1 1 300 # 1000 2000 3000 do.
      NB.?lintloopbodyalways
      ssk =: 1 {:: sdsocket_jsocket_ ''  NB. listening socket
      sdioctl_jsocket_ ssk , FIONBIO_jsocket_ , 1  NB. Make socket non-blocking
      rc =. sdconnect_jsocket_ ssk;qbm,<8090
      if. ssk e. 2 {:: sdselect_jsocket_ '';ssk;'';dly do. break. end.
      sdclose_jsocket_ ssk
      smoutput 'Error ' , (":rc) , ' connecting to server'
      qbm2 =. }. sdgethostbyname_jsocket_ 'www.quizbowlmanager.com'  NB. In case the address changed
      if. _1 {:: qbm2 -.@-: '255.255.255.255' do. qbm =: qbm2 end.  NB. Save new address, if it is valid
      ssk =: 0
    end.
    if. ssk=0 do.  NB. uncorrectable server error
      7 return.
    end.
    hangoverdata =: ''
  end.
  NB. Send the data.  Should always go in one go
  while. #senddata do.
    rc =. senddata sdsend_jsocket_ ssk,0
    if. 0{::rc do. 0{::rc [ ssk =: 0 [ sdclose_jsocket_ ssk return. end.
    if. (#senddata) = 1{::rc do. break. end.
    senddata =. (1{::rc) }. senddata
    if. -. ssk e. 2 {:: sdselect_jsocket_ '';ssk;'';5000 do. rc =. 1;'' break. end.
  end.
  if. 0{::rc do. 8 [ ssk =: 0 [ sdclose_jsocket_ ssk  return. end.  NB. error sending - what's that about?  Abort
end.

NB. Read responses if any
'rc rsockl wsockl esockl' =. sdselect_jsocket_ ssk;'';ssk;0
if. (rc~:0) +. ssk e. esockl do. ssk =: 0 [ sdclose_jsocket_ ssk return. end.
if. ssk e. rsockl do.  NB. If there's read data, process it
  'rc readdata' =. sdrecv_jsocket_ ssk,10000,0  NB. read it
  if. rc do. rc [ ssk =: 0 [ sdclose_jsocket_ ssk return. end.  NB. error reading: close socket
  if. 0=#readdata do. 0 [ ssk =: 0 [ sdclose_jsocket_ ssk return. end.  NB. Host closes connection: close socket
  hangoverdata =: hangoverdata , readdata
  NB. Verify response validity.
  NB. If we don't get a valid response, the game is in an unknown state.  There's nothing good to do, so we
  NB. will ignore the response and continue, hoping that the host correctly logged our data
  NB. Process commands until we get to no data or incomplete command
  whilst. #hangoverdata do.
    'rc data xsdata' =. fileserv_decrsphdr_sockfileserver_ hangoverdata
    hangoverdata =: xsdata   NB. save extra data for next time
    if. rc>0 do. 9 [ ssk =: 0 [ sdclose_jsocket_ ssk  return. end.   NB. Invalid msg - abort the connection
    NB. Process the response
    if. rc<0 do. break. end.   NB. stop when we don't have a full command to process
NB. obsolete if. #data do. qprintf'data 'end.
    incrhwmk =: (0 >.incrhwmk) + #data  NB.Since we processed it, skip over this data in the future
gamehistory =: gamehistory , data
    if. #data do. postsync data end.
  end.
end.

NB. Send new state info to the front end - it might have come from pre- or post-sync actions
gbls =. ".&.> gblifnames  NB. current values
chgmsk =. gbls ~: Ggbls  NB. see what's different
diffs =. (chgmsk # gblifnames) ,. chgmsk # gbls
Ggbls =: gbls  NB. save current values to be old state next time
if. buttonresettime < 6!:1'' do. Gbuttonblink =: '' end.  NB. this is a one-shot; clear shortly after each change
Gturnblink =: 0  NB. Also a one-shot
NB. Return the changes; if none, return a 0-length heartbeat
if. #diffs do.
NB. obsolete       nwdiffs =. (#~   (<'Gwordstatus') ~: {."1) diffs   NB. scaf
NB. obsolete       qprintf'nwdiffs '
  chg =. 5!:5 <'diffs'  NB. Get data to send
else. chg=.''  NB. if no diffs, send heartbeat
end.
senddata =. (2 (3!:4) #chg) , chg   NB. prepend length
while. #senddata do.
  if. -. sk e. 2 {:: sdselect_jsocket_ '';sk;'';5000 do. 9 return.  end.
  rc =. senddata sdsend_jsocket_ sk,0
  if. 0{::rc do. 0{::rc return. end.
  if. (#senddata) = 1{::rc do. break. end.
  senddata =. (1{::rc) }. senddata
end.
NB. If we did not read a response, quietly discard it
0
)

NB. Loop forever reading/writing sockets. y is the socket we are listening on.
NB. We wait for the game to connect.  If it goes away, we wait again
sockloop =: 3 : 0
NB. obsolete 'lsk tourn password' =. y
while. do.   NB. loop here forever
  sk =: 0  NB. no socket yet
  if. waitstate=0 do. smoutput 'Waiting for connection from game display' end.
  waitstate =: 1   NB. Indicate 
  incrhwmk =: 0  NB. where we are in the host log
  qbm =: }. sdgethostbyname_jsocket_ 'www.quizbowlmanager.com'
  sdlisten_jsocket_ lsk,1
  rc =. sdselect_jsocket_ lsk;'';'';0   NB. Wait till front-end attaches
  if. lsk e. 1 {:: rc do.
    waitstate =: 0  NB.  If we lose FE, give another message
    rc =. sdaccept_jsocket_ lsk  NB. Create the clone
    if. 0=0{::rc do.
      sk =: 1 {:: rc   NB. front-end socket number
      NB. Main loop: read from frontend, INCR to the server, process the response
      if. 0 do.
        while. do.
          sockpoll '' NB. obsolete qbm;sk;tourn;password
        end.
        NB. connection lost, close socket and rewait
        sk =: 0 [ sdclose_jsocket_ sk
      else.
        NB. debug version using timer
    NB. obsolete   timerpms =: qbm;sk;tourn;password
        wd 'timer 50'
      end.
    end.
  end.
return.  NB. scaf
end.
)

sys_timer =: 3 : 0
try.
  if. 0 = sk do. sockloop''  NB. estab connection to fe
  else.
if. 1 do.
    NB. loop right here until we lose heartbeat
    while. do.
      'rc r w e' =. sdselect_jsocket_ ((] ; '' ; ]) 0 -.~ sk,ssk) , <2000   NB. should always wake up
      if. rc do. break. end.  NB. abort if 
      if. #e do. rc =. 10 break. end.  NB. abort if error on socket
      if. 0 = #r do. break. end.  NB. if nothing to process, exit timer without error to let keyboard in
      if. rc =. sockpoll '' do. break. end.  NB. if there's something to do, do it, stop only if error
wd 'msgs'
    end.
smoutput 'out of loop'
else. rc =. sockpoll '' end.
    if. rc do.  NB. if error, reset sockets
      sk =: 0 [ sdclose_jsocket_ sk  NB. close fe socket before we rewait
      ssk =: 0 [ sdclose_jsocket_ ssk  NB. close host socket before we rewait
      smoutput 'Error ' , (":rc) , ' on sockets'
      waitstate =: 0  NB. Give another msg
    end.
  end.
catch.
wd 'timer 0'
smoutput 'error in timer'
smoutput (<: 13!:11'') {:: 9!:8''
smoutput 13!:12''
end.
i. 0 0
)
sys_timer_z_ =: sys_timer_base_

NB. y is text to add, x is suffix (<br> if monad)
addtolog =: 3 : 0
'<br>' addtolog y
:
Glogtext =: Glogtext , y , x
''
)

gblifnames =: ;:'Gstate Gscore Gdqlist Gactor Gscorer Gteamup Gteams Gwordqueue Gwordundook Gtimedisp Groundno Groundtimes Gawaystatus Gwordstatus Glogtext Glogin Gturnwordlist Gbuttonblink Gturnblink Gbagstatus Gteamnames Gauditor Gswrev'

NB. Initial settings for globals shared with FE
initstate =: 3 : 0
Gstate =: GSWORDS
Gscore =: 0 0
Gactor =: ''
Gscorer =: ''
Gteamup =: 0
Gteams =: ,<0$a:
Gwordqueue =: 0 2$a:  NB. table of word ; dqlist
Gwordundook =: 0
Gtimedisp =: 0
Groundno =: _1
Groundtimes =: 60 60 60
Gawaystatus =: (<0$a:) , (<0$a:)  NB.  list ; list   status1 status2
Gwordstatus =: 0 2$a:  NB. Table of name; liast of boxed words
Glogtext =: ''
Glogin =: ''
inithwmk =: 0
ourloginname =: ''
rejcmd =: ''  NB. set to a LOGINREJ cmd if we need one
Ggbls =: 0:"0 gblifnames  NB. Init old copy = something that never matches a boxed value
Gdqlist =. 0 3$a:
Gturnwordlist =: 0 3$a:
Gbuttonblink =: ''
buttonresettime =: 0
Gturnblink =: 0
Gbagstatus =: 0 0 0
Gteamnames =: 2$a:  NB. empty team names
Gauditor =: ''
Gswrev =: 0
allretiredwds =: 0 3$a:
NB.?lintsaveglobals
)
initstate''

NB. Look at commands; handle HELLO, LOGIN, DEAL, TICK
NB. Result is any text to send to the server
presync =: 3 : 0&.>
cmd =. (y i. ' ') {. y
if. (<cmd) e. 'HELLO';'LOGIN';'DEAL';'' do. ('presyh',cmd)~ (>:#cmd)}.y  NB. y here is the uninterpreted part after the command
else. y , CRLF
end.
)

presyhHELLO =: 3 : 0
initstate''
Gteamnames =: 'Red';'Black'
if. 1 = 0 ". y do. incrhwmk =: _1 end.  NB. if parm 1, reset the game state to empty
''  NB. Nothing to send - functions as a tick
)

NB. y is the player logging in
presyhLOGIN =: 3 : 0
name =. ".y  NB. y has not been interpreted
login =. ''
NB. Empty name is Logout, ignore it
if. #name do.
  NB. If the game has started, the name must be on a team
  if. (Gstate e. GSHELLO,GSLOGINOK,GSAUTH,GSWORDS) +. ((<name) e. ; Gteams) do.
    ourloginname =: name   NB. Remember who we're logging in...
    ourlogintime =: 0   NB. wait for LOGINREQ
    login =. 'LOGINREQ ' , y , CRLF   NB. start the login sequence
    Glogin =: '*'  NB. Indicate login pending
  end.
else. Glogin =: ''  NB. not logged in now!
end.

NB.?lintsaveglobals
login
)

presyhDEAL =: 3 : 0
if. #Gteams do.
  draw =. (({~ ,&< ({~ <@<@<)) ((<.@-:@#) ? #)) ; Gteams
  'TEAMS ' , (5!:5<'draw') , CRLF
else. ''
end.
)

presyh =: 3 : 0  NB. tick
NB. If we are the actor, change the tick to a TICK
res =. rejcmd
rejcmd =: ''  NB. It's a one-shot
if. (Glogin -: Gactor) do.
  if. (Gstate = GSACTING) *. (Gtimedisp>0) do. res =. res , 'TICK 0',CRLF end.
end.
if. #ourloginname do. if. (ourlogintime~:0) *. (6!:1'')>ourlogintime+4 do.
  Glogin=:ourloginname
  ourloginname =: ''
  ourlogintime =: 0
end. end.
res
)

NB. Calculate bagstatus whenever wordqueue or wordbag changes
bagstatus =: 3 : 0
Gbagstatus =: <: #/.~ (<"0 i.3) , {."1 Gwordqueue , exposedwords , wordbag
''
)
NB. y is sequence of CRLF-delimited commands from the server.  We process them one by one,
NB. making changes to the globals as we go.  Then, we send the changed globals to the FE.
postsync =: 3 : 0
". :: (addtolog@('Failed: '&,)) @('postyh'&,);._2 y -. CR   NB. run em all
NB. Send the changed names
i. 0 0
)

NB. eclevel
postyhSWREV =: 3 : 0
Gswrev =: Gswrev >. y
''
)

postyhLOGINREQ =: 3 : 0
NB. If this the first request for our pending login, start our timer.
if. y -: ourloginname do.
  if. ourlogintime=0 do.
    ourlogintime =: 6!:1''
  else. rejcmd =: 'LOGINREJ ' , (5!:5<'y') , CRLF
  end.
NB. If this is a request for our current login, or a later request for our pending login, reject it
elseif. y -: Glogin do. rejcmd =: 'LOGINREJ ' , (5!:5<'y') , CRLF
end.
NB. If the game hasn't started, and this is the first time we've seen this name, remember it
NB. If teams have been drawn, invalidate them
if. Gstate=GSWORDS do. if. (<y) -.@e. ; Gteams do.
  Gteams =: < (<y) , ; Gteams
  addtolog 'Login: ' , y
end. end.
''
)

postyhLOGINREJ =: 3 : 0
if. y -: ourloginname do.  NB. Abort pending login if rejected anywhere (including here)
  ourloginname =: ''
  ourlogintime =: 0
  Glogin =: ''  NB. remove login-pending status
end.
''
)

NB. y is 2 boxes of names
postyhTEAMS =: 3 : 0
NB. Accept the teams if they embrace all players and we haven't started, otherwise discard.  There must be at least 4 players, and no multiple assignments
if. Gstate=GSWORDS do.
  if. (0=# (;Gteams) -.;y) *. (0=# (;y) -.;Gteams) do.
    if. 4 <: #;y do.
      Gteams =: y
    end.
  end.
end.
''
)

NB. Convert word to canonical form
canonword =: 3 : 0
(-.&' ''-,/')@:tolower y
)

NB. name ; 5!:5 'words' - audited in the FE
postyhWORDS =: 3 : 0
'name words' =. y
NB. Accept it if we haven't started
if. Gstate=GSWORDS do.
  otherwords =. (<name) (] #~ (~: {."1)) Gwordstatus
  NB. Remove matches for the word.  Could do plurals, Leveshtein, etc here
  canonnew =. canonword&.> words
  canonold =. canonword&.> ; 1 {"1 otherwords
  words =. words #~ canonnew -.@e. canonold
  Gwordstatus =: (name;<words) ,~ otherwords
  Gbagstatus =: # ; 1 {"1 Gwordstatus
end.
''
)

NB. rnd nsec
postyhRDTIME =: 3 : 0
'rd sec' =. y
NB. Accept at any time
Groundtimes =: sec rd} Groundtimes
''
)

NB. name [012]
postyhAWAYSTATUS =: 3 : 0
'name status' =. y
name =. <name
NB. Accept at any time.  Filtering is done by FE
Gawaystatus =: ((status = 1 2) <@#"0 name) ,&.> -.&name&.> Gawaystatus
''
)

NB. name - start the game phase
postyhSTART =: 3 : 0
NB. Ignore if game is underway or teams have not been assigned
if. (Gstate=GSWORDS) *. 2=#Gteams do.
NB.?lintonly Gteams =: (;:'Bob Carol'),&<(;:'Ted Alice')
  NB. Reset game, move to playing state
  Gteamup =: 0 [ actorhist =: 0 2$a:
  NB. Init the wordlist and history from prev round
  NB. wordbag is list of round;word where each round's words are put in pseudorandom order by CRC, but kept in group by round
  words =. /:~ ; 1 {"1 Gwordstatus   NB. All the words, in order
  wordbag =: ,/ 0 1 2 ([ ;"0 ;@:(<@(] /: (128!:3@,&> {&(;:'aV76 Gr83l H2df968'))~)))"0 _ words
NB.?lintonly wordbag =: ,: 1;'word'
  NB. exposedwords is the priority list that we must finish before going into the wordbag.  It is
  NB. round;word;score (where score of 0 0 means don't know)
  exposedwords =: 0 3$a:
NB.?lintonly exposedwords =: ,: 1;'word';1 1
  NB. Gdqlist is a list of round;word;name for every time a word is added to the exposedwords
  Gdqlist =: 0 3$a:
NB.?lintonly dqlist =: ,: 1;'word';'name'
  NB. Gwordqueue is a list of round;word;dqlist where each word is in Groundno.  These words are exposed to the actor
  Gwordqueue =: 0 3$a:
NB. Gwordqueue =: ,: '1';'word';< ,<'dq'
  Groundno =: 0
  Gstate=:GSWACTOR
  Gtimedisp =: 0
  bagstatus''  NB. Init display of # words per round left
  NB. Display the teams, removing the login list
  Glogtext =: ''
  '<br><br>' addtolog ; ,&'<br>'&.>  a: ,.~ Gteamnames  ,. > Gteams
NB.?lintsaveglobals
''
end.
)

NB. name do/undo  needscorer
postyhACTOR =: 3 : 0
NB. Accept if in WACTOR (if type=1) or WSCORER (do=0 and name matches Gactor) or CHANGEWACTOR (if do=1 and name matches Gactor)
'name do needscorer' =. y
if. do = (1 ,((name-:Gactor) { 2 2,:0 1),2) {~ (GSWACTOR,GSWSCORER,GSCHANGEWACTOR) i. Gstate do.
  if. do do.
    NB. We are accepting a name.  Save it and move to WSCORER or WAUDITOR
    if. Gstate=GSCHANGEWACTOR do.  NB. No name change in middle of round - looking for scorer/auditor
      Gstate =: needscorer { GSCHANGEWAUDITOR,GSCHANGEWSCORER 
    else.
      Gactor =: name
      NB. If we changing rounds, interpolate CHANGE state
      if. Groundno ~: nextroundno'' do.
        Groundno =: nextroundno''
        Gstate =: GSCHANGE
      else. Gstate =: needscorer { GSWAUDITOR,GSWSCORER
      end.
    end.
    Gscorer =: needscorer {:: name;''
    Gauditor =: ''
  elseif. Gstate e. GSWSTART,GSWSCORER do.
    NB. We are taking an undo, necessarily from START/SCORER to ACTOR.  Forget the actor's name, and the scorer's
    Gactor =: Gscorer =: ''
    Gstate =: GSWACTOR
  end.
end.
''
)

SCORERstates =: ".;._2 (0 : 0)
GSWSCORER , 1 0 0
GSWSCORER , 1 0 1
GSWSCORER , 1 1 0
GSWSCORER , 1 1 1
GSCHANGEWSCORER , 1 0 0
GSCHANGEWSCORER , 1 0 1
GSCHANGEWSCORER , 1 1 0
GSCHANGEWSCORER , 1 1 1
GSWSTART , 0 0 1
GSWSTART , 0 1 0
GSWSTART , 0 1 1
GSCHANGEWSTART , 0 0 1
GSCHANGEWSTART , 0 1 1
)
NB. name do/undo
postyhSCORER =: 3 : 0
NB. Accept if:
NB.  do in WSCORER or CHANGEWSCORER
NB.  undo in WSTART if actor or scorer
NB.  undo in CHANGEWSTART if scorer
'name do' =. y
if. (Gstate , do , (name-:Gactor) , (name-:Gscorer)) e. SCORERstates do.
  if. do do.
    Gscorer =: name
    Gstate =: (Gstate=GSWSCORER) { GSCHANGEWSTART,GSWSTART
  else.
    NB. It's an undo
    Gscorer =: ''
    Gstate =: (Gstate=GSWSTART) { GSCHANGEWSCORER,GSWSCORER
    if. (name-:Gactor) *. (Gstate=GSWSCORER) do.   NB. If actor quails, go back to WACTOR - not if CHANGE
      Gactor =: ''
      Gstate =: GSWACTOR
    end.
  end.
end.
''
)

NB. name, possibly empty
postyhAUDITOR =: 3 : 0
NB. Accept if WAUDITOR or CHANGEWAUDITOR
if. Gstate e. GSWAUDITOR,GSCHANGEWAUDITOR do.
  Gauditor =: y
  Gstate =: (Gstate=GSCHANGEWAUDITOR) { GSWSTART,GSCHANGEWSTART
end.
)

NB. nilad
postyhACT =: 3 : 0
NB. Accept in WSTART or CHANGEWSTART
if. Gstate e. GSWSTART,GSCHANGEWSTART do.
  NB. go ACTING state.  If we were in START, start the timer.  This starts the turn.
  if. Gstate = GSWSTART do.
    Gtimedisp =: Groundno { Groundtimes
    NB. Gturnwordlist is the list of round;word;score for words that have been moved off the wordqueue.  Taken together, turnwordhist and Gwordqueue
    NB. have all the words that were exposed this turn
    Gturnwordlist =: 0 3$a:
    NB.?lintonly Gturnwordlist =: ,: 1;'word';1 1
    NB. Clear the list of all words retired this turn (in all rounds)
    allretiredwds =: 0 3$a:
    NB. We save a copy of the exposedwords before we start so that we can delete words dismissed twice in a row
    prevexposedwords =: exposedwords
    NB. Move the acting player to the bottom of the priority list
    Gteams =: (< (Gteamup {:: Gteams) (-. , ]) <Gactor) Gteamup} Gteams
    NB.?lintonly prevexposedwords =: ,: 1;'word';1 1
    NB.?lintsaveglobals
  end.
  Gstate =: GSACTING
  getnextword''   NB. Prime the pipe
end.
''
)

NB. Add words to the word queue until it's full.  It holds 2 words
NB. We always take from the exposedwords if there is one.  Otherwise we draw from the bag.
NB. BUT: we never draw a word if it is a different round from the word on the stack
NB. This never affects bagstatus
getnextword =: 3 : 0
while. 2 > #Gwordqueue do.
  nextrdwd =. ''  NB. Indicate no word added
  NB. If there is a word in the queue, save its round to indicate we must match it; otherwise empty to match anything
  if. #exposedwords do. if. Groundno = (<0 0) {:: exposedwords do.
    NB. There is a valid exposed word.  Take it
    nextrdwd =. (<0;0 1) { exposedwords
    exposedwords =: }. exposedwords
  end. elseif. #wordbag do. if. Groundno = (<0 0) {:: wordbag do.
    NB. There is a valid word in the bag.  Take it
    nextrdwd =. (<0;0 1) { wordbag
    wordbag =: }. wordbag
  end. end.
  NB. If there is no word to add, exit
  if. 0=#nextrdwd do. break. end.
  NB. Expose the word, with no scoring
  Gwordqueue =: Gwordqueue , nextrdwd , a:
end.
''
)

NB. Return round# of the next word
nextroundno =: 3 : 0
if. # Gwordqueue do. (<0 0) {:: Gwordqueue
elseif. #exposedwords do. (<0 0) {:: exposedwords
elseif. #wordbag do. (<0 0) {:: wordbag
else. 3
end.
)

NB. Return true if the word queue is empty or the top word is not for our round.  Indicates change of round
NB. We have just called getnextword to fill the word queue
isnewround =: 3 : 0
if. -. *@# Gwordqueue do. 1 return. end.   NB. 1 if no words
Groundno ~: (<0 0) {:: Gwordqueue   NB. 1 if top word is for different round
)

NB.  {-1 0 1} {012}   score, count wd as played or foul
postyhNEXTWORD =: 3 : 0
'score retire' =. y
NB. Accept only if there is a word in the word queue, and if we are in a scorable state
if. (*@# Gwordqueue) *. Gstate e. GSACTING,GSPAUSE,GSSETTLE do.
  NB. Adjust the score
  Gscore =: (score + Gteamup { Gscore) Gteamup} Gscore
  NB. Move the word from the wordqueue to the Gturnwordlist
  Gturnwordlist =: Gturnwordlist , (<score,retire) 2} {. Gwordqueue  NB. put rd/wd/score onto turnlist
  NB. The word will be revealed to the scorer and auditor, if it is retired.  It might be unretired later, so DQ the scorer and auditor just in case
  if. retire >: 1 do. Gdqlist =: Gdqlist , (~. a: -.~ Gauditor;Gscorer) ,"1 0~ (<0;0 1) { Gwordqueue end.
  Gwordqueue =: }. Gwordqueue
  Gwordundook =: (<Groundno) e. 0 {"1 Gturnwordlist  NB. Allow undo if there's something to bring back
  NB. If we are still acting or paused, top up the qword queue
  if. Gstate e. GSACTING,GSPAUSE do. getnextword'' end.
  NB. If the word queue is still empty, that's a change of state: go to CONFIRM to accept the score and move on.  Keep the time
  NB.   on the timer
  if. isnewround'' do. Gstate =: GSCONFIRM end.
  NB. Blink the pressed button as an ack to the team
  Gbuttonblink =: score,retire  NB. This gets reset automatically...
  buttonresettime =: 1. + 6!:1''   NB. ... after this time
  bagstatus''  NB. Update count of words yet to do
end.
''
)

postyhPREVWORD =: 3 : 0
NB. If there is a word in the turnlist, and  we are acting or paused, or we are settling
if. Gwordundook *. (Gstate e. GSACTING,GSPAUSE,GSSETTLE,GSCONFIRM) do.
  NB. Move tail of turnwords to head of Gwordqueue.  Remove the disposition, since we are removing the score.  It never happened.
  tailwd =. {: Gturnwordlist
  Gwordqueue =: Gwordqueue ,~ a: 2} tailwd
  Gturnwordlist =: }: Gturnwordlist
  Gwordundook =:  (<Groundno) e. 0 {"1 Gturnwordlist  NB. Allow undo if there's something to bring back
  NB. Undo the score
  score =. (2;0) {:: tailwd  NB. score entered for the word
  Gscore =: (score -~ Gteamup { Gscore) Gteamup} Gscore
  NB. Handle changes of state.
  NB. If we are ACTING or PAUSED, and the new word is for a different round, go to CHANGE state for that round
  if. (Gstate e. GSACTING,GSPAUSE) *. Groundno ~: (<0 0) {:: Gwordqueue do.
    Groundno =: (<0 0) {:: Gwordqueue  NB. set new round before CHANGE
    Gstate =: GSCHANGE
  NB. If we are SETTLING or CONFIRM, go into SETTLE until the queue is empty
  elseif. Gstate = GSCONFIRM do. Gstate =: GSSETTLE
  end.
  bagstatus''  NB. Update count of words yet to do
end.
''
)

NB. nilad
postyhPROCEED =: 3 : 0
NB. Valid in CHANGE state.  If the timer is running, go to CHANGEWACTOR, otherwise WSCORER or WSTART
if. Gstate=GSCHANGE do.
  NB. At start, Gscorer is null if we need a scorer, otherwise set to same as Gactor
  Gstate =: (Gtimedisp=0) { GSCHANGEWACTOR,(*@#Gscorer){GSWSCORER,GSWAUDITOR
end.
''
)

NB. table of row;new score
postyhSCOREMOD =: 3 : 0
NB. Accept only if SETTLE or CONFIRM
if. Gstate e. GSSETTLE,GSCONFIRM do.
  edits =. y
  NB. This operates on the combined wordlist/queue.  Create that here and split again at the end
  wl =. Gturnwordlist , Gwordqueue
  NB. Save total score before change
  sc0 =. +/ {.@(2&{::)"1 wl
  NB. apply the edits
  wl =. ({:"1 edits) (<2 ;~ ; {."1 edits)} wl
  NB. Get total score after change
  sc1 =. +/ {.@(2&{::)"1 wl
  NB. Adjust the score
  Gscore =: ((sc1-sc0) + Gteamup { Gscore) Gteamup} Gscore
  NB. Split back into two lists, with wordqueue holding unscored words
  unscored =. a: = 2 {"1 wl
  Gturnwordlist =: (-. unscored) # wl
  Gwordqueue =: unscored # wl
  NB. If the wordqueue is not empty, go to SETTLE, otherwise stay in CONFIRM
  Gstate =: (*@# Gwordqueue) { GSCONFIRM,GSSETTLE
  bagstatus''  NB. Update count of words yet to do
end.
''
)

NB. nilad
postyhCOMMIT =: 3 : 0
NB. Accept if in CONFIRM state
if. Gstate = GSCONFIRM do.
  NB. If exposed and bag are empty, this actor gets no more words, so take the time away
  if. exposedwords +:&(*@#) wordbag do. Gtimedisp =: 0 end.
  NB. Display & Discard words that have been passed twice in a row
  oldpass =. ((0;0 _1) -:"1 (0 2) {"1 prevexposedwords) # 1 {"1 prevexposedwords
  newpass =. ((0;0 _1) -:"1 (0 2) {"1 Gturnwordlist) # 1 {"1 Gturnwordlist
  retired =. newpass (e. # [) oldpass  NB. words passed twice in a row in the first round
  '' addtolog ;@:(('discarded: ' , '<br>' ,~ ])&.>) retired
  Gturnwordlist =: (retired -.@e.~ 1 {"1 Gturnwordlist) # Gturnwordlist
  wordbag =: (retired -.@e.~ 1 {"1 wordbag) # wordbag
  Gdqlist =: (retired -.@e.~ 1 {"1 Gdqlist) # Gdqlist

  NB. show the player's score for this round
  rdscore =. +/ {."1 > 2 {"1 (<Groundno) (] #~ (= {."1)) Gturnwordlist
  addtolog Gactor , ': ' , (, '' 8!:2 rdscore) , ' pts ' , Groundno{::'(taboo)';'(charades)';'(password)'
  handledmsk =. 1 <: (2;1)&{::"1 Gturnwordlist  NB. words we finished
  Gdqlist =: ((2 {."1 Gdqlist) -.@e. (handledmsk # 2 {."1 Gturnwordlist)) # Gdqlist  NB. Remove dqs for words we are showing now
  NB. Keep running list of all words retired this turn
  allretiredwds =: allretiredwds , handledmsk # Gturnwordlist
  Gturnwordlist =: (-. handledmsk) # Gturnwordlist  NB. The  words have now passed on
  if. Gtimedisp=0 do.
    NB. if no time left, handle end-of-turn
    NB. Put the remaining turn words into the exposed list
    exposedwords =: Gturnwordlist
    NB. Also into the dqlist for the player who saw them
    Gdqlist =: Gdqlist , (<Gactor) (<a:;2)} Gturnwordlist
  end.
  NB. Figure next state:
  NB. GAMEOVER if the exposed and bag are still empty
  if. exposedwords +:&(*@#) wordbag do. Gstate =: GSGAMEOVER
  NB. CHANGE if it's a round change and there is time - change roundno first
  elseif. (Gtimedisp~:0) *. Groundno~:nextroundno''do.
    Gstate =: GSCHANGE
    Groundno =: nextroundno''  NB. set new round# before going to CHANGE state
  else.
    NB. This is where end-of-turn happens.
    NB. Should be out of time, since there are no words to act.  Clear time just in case, and go look for next actor, from the other team
    Gtimedisp =: 0 [ Gteamup =: -. Gteamup [ Gstate =: GSWACTOR [ Groundno =: nextroundno''
    NB. Going to ACTOR - repurpose Gturnwordlist to hold all the words exposed in the previous turn.  This is displayed until the acting starts
    Gturnwordlist =: allretiredwds
  end. 
  bagstatus''  NB. Update count of words yet to do
end.
''
)
postyhTICK =: 3 : 0
NB. Ignore if not ACTING
NB. Process through TIMERADJ
if. Gstate = GSACTING do. postyhTIMERADJ Gteamup;_1;'' end.
''
)

NB. Direct overrides of timer or score
NB. team incr name
postyhSCOREADJ =: 3 : 0
'team incr name' =. y
NB. Accept during SETTLE or CONFIRM only
if. Gstate e. GSSETTLE,GSCONFIRM do.
  Gscore =: (incr + team { Gscore) team} Gscore
  if. *@# name do. addtolog '<font color=red>' , name , ((incr>0){::' took away ';' added ') , (":|incr) , ' points' , ((incr>0){::' from ';' to ') , (team {:: Gteamnames) , '</font>' end.
end.
''
)

NB. stop/start  incr  name   if incr is 0, it's a start/stop
postyhTIMERADJ =: 3 : 0
'start incr name' =. y
NB. If start/stop, handle only in ACTING/PAUSED state
if. 0=incr do.
  NB. If start/stop, handle only in ACTING/PAUSED state
  if. Gstate e. GSACTING,GSPAUSE do. Gstate =: start { GSPAUSE,GSACTING end.
else.
  NB. Accept timer changes during ACTING/PAUSE/SETTLE/CONFIRM
  if. Gstate e. GSACTING,GSPAUSE,GSSETTLE,GSCONFIRM do.
    prevtime =. Gtimedisp   NB. Save time before change
    NB. Apply change
    Gtimedisp =: 0 >. Gtimedisp + incr
    NB. Log it
    if. *@# name do. addtolog '<font color=red>' , name , ((incr>0){::' took away ';' added ') , (":|incr) , ' seconds ' , '</font>' end.
    NB. Changing the clock-zero status is a change of state.
    if. prevtime ~:&* Gtimedisp do.
      if. Gtimedisp do.
        NB. Transitioning from no time to some time.  We must have been in SETTLE.  If there are no words to act, we'll just count the time.  We assume
        NB. everybody is ready to go
        getnextword''   NB. Charge the queue, in case we processed it all
        if. isnewround'' do.
          Groundno =: nextroundno''  NB. set new round when going into CHANGE
          Gstate =: GSCHANGE
        else.
          Gstate =: GSACTING  NB. continue acting
        end.
      else.
        NB. Transitioning from some time to no time, i. e. the buzzer sounds.  If nothing to be scored, CONFIRM, otherwise SETTLE
        Gturnblink =: 1  NB. Call for the buzzer
        Gstate =: (Gturnwordlist +.&(*@#) Gwordqueue) { GSCONFIRM,GSSETTLE
      end.
    end.
  end.
end.

''
)

0 : 0
(<'1111111') sendcmd 'INCR "t1000" "bonlog" "0"',CRLF,'a' [ getsk''
)


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
NB. x, if 1, means 'message must be self-contained' (default 0)
NB. y is data read
NB. result is rc;data;hangover data in next msg
NB. rc of _1 means 'incomplete msg, wait for more'
NB. We check for length
fileserv_decrsphdr =: 3 : 0
0 fileserv_decrsphdr y
:
NB. See if header is complete
if. (CRLF,CRLF)&(+./@:E.) y do.
  NB. Strip header
  msghdr =. ( {.~ (CRLF,CRLF)&(#@[ + (i.&1@:E.)) ) y
  NB. Get rc line from header
  msgrc =. 2 {. <;._1 ' ' , ({.~ CRLF&(i.&1@:E.)) msghdr
  if. msgrc -.@e. (<'HTTP/1.1'),.('200';'201';'202';'203';'204';'205') do.
    NB. If not valid response, return error
    (({.!.999) 999 ". 1 {:: msgrc);y;'' 
  elseif.
    NB. Get the Content-Length from the header
    NB. Split on LF; remove CRLF
    lines =. <@(-.&CRLF);._2 msghdr
    NB. Split each line into name;value
    namval =. (({.~ ; (}.~ >:)) ': '&(i.&1@:E.))@> lines
    len =. {. 0 ". pw =. (<'Content-Length') '' getklu_defu_colsv (0;1) namval
    len > y -&# msghdr do.  NB. Msg too short
    _1 ; '' ; y  NB. incomplete message, wait for more
  elseif. do.
    0 ; len ({. ; }.) (#msghdr) }. y
  end.
else. _1 ; '' ; y  NB. incomplete message, wait for more
end.
)

NB. Calculate checksum for a file.
NB. y is string, result is checksum (numeric)
fileserv_checksum =: 3 : 0"1
128!:3 y
)
