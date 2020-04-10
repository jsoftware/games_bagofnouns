require 'socket'
require 'strings'
sdcleanup_jsocket_ =: 3 : '0[(sdclose ::0:"0@[ shutdownJ@(;&2)"0)^:(*@#)SOCKETS_jsocket_'

NB. Game states
GSHELLO =: 0  NB. Initial login at station: clear username, clear incrhwmk
GSLOGINOK =: 1  NB. OK to log in
GSAUTH =: 2  NB. Authenticating credentials
NB. All the rest require a login to enable any buttons
GSWORDS =: 3  NB. waiting for words to be entered
GSWACTOR =: 4  NB. waiting for an actor.  Time has not started
GSWSCORER =: 5   NB. Waiting for a scorer.  Time may have started
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
'tourn password' =: y
sdcleanup_jsocket_''  NB. debugging
lsk =: 1 {:: sdsocket_jsocket_ ''  NB. listening socket
rc =. sdbind_jsocket_ lsk ; AF_INET_jsocket_ ; '' ; 8090  NB. listen on port 8090 
if. 0~:rc do. ('Error ',(":rc),'binding to 8090') 13!:8 (4) end.
NB. Wait for hello
sockloop lsk;tourn;password
)

NB. Loop forever reading/writing sockets. y is the socket we are listening on.
NB. We wait for the game to connect.  If it goes away, we wait again
sockloop =: 3 : 0
'lsk tourn password' =. y
while. do.   NB. loop here forever
  smoutput 'Waiting for connection'
  incrhwmk   =: 0  NB. where we are in the host log
  qbm =. }. sdgethostbyname_jsocket_ 'www.quizbowlmanager.com'
  sdlisten_jsocket_ lsk,1
  sdselect_jsocket_ lsk;'';'';6000000   NB. Wait till front-end attaches
  rc =. sdaccept_jsocket_ lsk  NB. Create the clone
  if. 0~:0{::rc do. ('Error ',(":0{::rc),'connecting to frontend') 13!:8 (4) end.
  sk =. 1 {:: rc   NB. front-end socket number
  NB. Main loop: read from frontend, INCR to the server, process the response
  feconnlost=.0
  while. do.
   NB. Wait for a pulse from the front end
    if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';1000 do.  NB. scaf 5000
      smoutput 'heartbeat lost' return. break.  NB. scaf 
    end.
    NB. There is data to read.  Read it all, until we have the complete message(s).  First 4 bytes are the length
    hdr =. ''   NB. No data, no bytes of header
    cmdqueue =. 0$a:  NB. List of commands
    while. do.
      while. do.
        'rc data' =. sdrecv_jsocket_ sk,(4-#hdr),00   NB. Read the length, from 2 (3!:4) #data
        if. 0{::rc do. 'Error ',(":0{::rc),' reading from frontend' 13!:8 (4) end.
        if. 0=#data do. feconnlost=.1 break. end.
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
        if. rc~:0 do. 'Error ',(":0{::rc),' reading from frontend' 13!:8 (4) end.
        if. 0=#data do. feconnlost=.3 break. end.
        readdata =. readdata , data
        hlen=.hlen-#data  NB. when we have all the data, plus possibly the next length
      end.
      if. feconnlost do. break. end.
      NB. If there is not another command, exit to process them
      cmdqueue =. cmdqueue , < hlen }. readdata
      if. hlen >: 0 do. break. end.  NB. >0 only if error
      hdr =. hlen {. readdata  NB. transfer the length
      if. -. sk e. 1 {:: sdselect_jsocket_ sk;'';'';5000 do. feconnlost=.5 break. end.
    end.
    if. feconnlost do. break. end.
    NB. perform pre-sync command processing
    senddata =. (<password) fileserv_addreqhdr_sockfileserver_  ('INCR "' , tourn , '" "bonlog" "' , (":incrhwmk) , '"',CRLF) , ; presync cmdqueue
    NB. Create a connection to the server and send all the data in an INCR command
    NB.?lintonly ssk =. 0
    for_dly. 1000 1000 1000 do.
      ssk =. 1 {:: sdsocket_jsocket_ ''  NB. listening socket
      sdioctl_jsocket_ ssk , FIONBIO_jsocket_ , 1  NB. Make socket non-blocking
      rc =. sdconnect_jsocket_ ssk;qbm,<8090
      if. ssk e. sds   =. 2 {:: sdselect_jsocket_ '';ssk;'';dly do. break. end.
      sdclose_jsocket_ ssk
      smoutput 'Error ' , (":rc) , ' connecting to server'
      qbm =. }. sdgethostbyname_jsocket_ 'www.quizbowlmanager.com'  NB. In case the address changed
      ssk =. 0
    end.
    if. ssk=0 do.  NB. uncorrectable server error
      'Unable to reach game server.  Check your Internet.' 13!:8 (4)
    end.
    NB. Send the data.  Should always go in one go
    while. #senddata do.
      rc =. senddata sdsend_jsocket_ ssk,0
      if. 0{::rc do. 'Error ',(":0{::rc),' in sdsend to server' 13!:8 (4) end.
      if. (#senddata) = 1{::rc do. break. end.
      senddata =. (1{::rc) }. senddata
      if. -. ssk e. 2 {:: sdselect_jsocket_ '';ssk;'';5000 do. rc =. 1;'' break. end.
    end.
    if. 0{::rc do. sdclose_jsocket_ ssk break. end.  NB. error sending - what's that about?  Abort
    NB. Read the response, until the server closes
    readdata =. ''
    while. do.
      for. i. 3 do.
        rsockl =. 1 {:: sdselect_jsocket_ ssk;'';ssk;4000
        if. ssk e. rsockl do. break. end.  NB. should respond quickly
        smoutput '4s timeout from server'
      end.
      if. -. ssk e. rsockl do. readdata =. '' break. end.  NB. Exit with empty data as error flag
      'rc data' =. sdrecv_jsocket_ ssk,10000,0
      if. rc do. 'Error ',(":rc),' in sdrecv from server' 13!:8 (4) end.
      if. 0=#data do. break. end.  NB. Normal exit: host closes connection
      readdata =. readdata , data  NB. Accumulate reply
    end.
    sdclose_jsocket_ ssk
qprintf'readdata '
    if. #readdata do.
      NB. Verify response validity.
      NB. If we don't get a valid response, the game is in an unknown state.  There's nothing good to do, so we
      NB. will ignore the response and continue, hoping that the host correctly logged our data
      'rc data' =. fileserv_decrsphdr_sockfileserver_ readdata
qprintf'rc data '
      NB. Process the response
      if. rc=0 do.
        incrhwmk   =: (0 >.incrhwmk) + #data  NB.Since we processed it, skip over this data in the future
        postsync data
        NB. Send new state info to the front end
        gbls =. ".&.> gblifnames  NB. current values
        chgmsk =. gbls ~: Ggbls  NB. see what's different
        diffs =. (chgmsk # gblifnames) ,. chgmsk # gbls
        Ggbls =: gbls  NB. save old state
        if. #diffs do.
          chg =. 5!:5 <'diffs'  NB. Get data to send
          senddata =. (2 (3!:4) #chg) , chg   NB. prepend length
          while. #senddata do.
            if. -. sk e. 2 {:: sdselect_jsocket_ '';sk;'';5000 do. 'Timeout sending to frontend' 13!:8 (4) end.
            rc =. senddata sdsend_jsocket_ sk,0
            if. 0{::rc do. 'Error ',(":0{::rc),' in sdsend to frontend' 13!:8 (4) end.
            if. (#senddata) = 1{::rc do. break. end.
            senddata =. (1{::rc) }. senddata
          end.
        end.
      end.
    end.
    NB. If we did not read a response, quietly discard it
  end.
  NB. connection lost, close socket and rewait
  sdclose_jsocket_ sk
return.  NB. scaf
end.
)

gblifnames =: ;:'Gstate Gscore Gactor Gscorer Gteamup Gteams Gwordqueue Gwordundook Gtimedisp Groundno Groundtimes Gawaystatus Gwordstatus Glogtext Glogin'

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
if. 1 = 0 ". y do. incrhwmk =: _1 end.  NB. if parm 1, reset the game state to empty
''  NB. Nothing to send - functions as a tick
)

presyhLOGIN =: 3 : 0
ourloginname =: ".y   NB. Remember who we're logging in... (y is uninterpreted here)
ourlogintime =: 0   NB. wait for LOGINREQ
Glogin =: ''  NB. not logged in now!
'LOGINREQ ' , y , CRLF   NB. start the login sequence
)

presyhDEAL =: 3 : 0
if. #Gteams do.
  draw =. Gteams ({~ ,&< ({~ <@<@<)) ((<.@-:@#) ? #) ; Gteams
  'TEAMS ' , (5!:5<'draw') , CRLF
else. ''
end.
)

presyh =: 3 : 0  NB. tick
NB. If we are the actor, change the tick to a TICK
res =. rejcmd
rejcmd =: ''  NB. It's a one-shot
if. (Glogin -: Gactor) do.
  if. (Gstate = GSACTING) *. (Gtimedisp>0) do. res =. res , 'TICK',CRLF end.
end.
if. #ourloginname do. if. (ourlogintime~:0) *. (6!:1'')>ourlogintime+4 do.
  Glogin=:ourloginname
  ourloginname =: ''
  ourlogintime =: 0
end. end.
res
)

NB. y is sequence or CRLF-delimited commands from the server.  We process them one by one,
NB. making changes to the globals as we go.  Then, we send the changed globals to the FE.
postsync =: 3 : 0
Glogtext =: Glogtext , y  NB. scaf
".@('postyh'&,);._2 y -. CR   NB. run em all
NB. Send the changed names
i. 0 0
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
if. Gstate=GSWORDS do. if. (<y) -.@e. ; Gteams do. Gteams =: < (<y) , ; Gteams end. end.
''
)

postyhLOGINREJ =: 3 : 0
if. y -: ourloginname do.  NB. Abort pending login if rejected anywhere (including here)
  ourloginname =: ''
  ourlogintime =: 0
end.
''
)

NB. y is 2 boxes of names
postyhTEAMS =: 3 : 0
NB. Accept the teams if they embrace all players and we haven't started, otherwise discard
if. Gstate=GSWORDS do. if. 0=# (;Gteams) -. ;y do. Gteams =: y end. end.
''
)

NB. name ; 5!:5 'words' - audited in the FE
postyhWORDS =: 3 : 0
'name words' =. y
NB. Accept it if we haven't started
if. Gstate=GSWORDS do.
  otherwords =. (<name) (] #~ (~: {."1)) Gwordstatus
  NB. Remove matches for the word.  Could do plurals, Leveshtein, etc here
  words =. words -. ; 1 {"1 otherwords
  Gwordstatus =: (name;<words) ,~ otherwords
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
Gawaystatus =: ((status = 1 2) <@# name) ,&.> -.&name&.> Gawaystatus
''
)

NB. name - start the game phase
postyhSTART =: 3 : 0
NB. Ignore if game is underway or teams have not been assigned
if. (Gstate=GSWORDS) *. 2=#Gteams do.
  NB. Reset game, move to playing state
  Gteamup =: 0 [ actorhist =: 0 2$a:
  NB. Init the wordlist and history from prev round
  NB. wordbag is list of round;word where each round's words are put in pseudorandom order by CRC, but kept in group by round
  words =. /:~~ ; 1 {"1 wordstatus   NB. All the words, in order
  wordbag =: ,/ 0 1 2 ([ ;"0 ;@:(<@(] /: (128!:3@,&> {&(;:'aV76 Gr83l H2df968'))~)))"0 _ words
  NB. exposedwords is the priority list that we must finish before going into the wordbag.  It is
  NB. round;word;score (where score of 0 0 means don't know)
  exposedwords =: 0 3$a:
  NB. dqlist is a list of round;word;name for every time a word is added to the exposedwords
  dqlist =: 0 3$a:
  NB. Gwordqueue is a list of round;word;dqlist where each word is in Groundno.  These words are exposed to the actor
  Gwordqueue =: 0 3$a:
  Gstate=:GSWACTOR
''
end.
)

NB. name do/undo  needscorer
postyhACTOR =: 3 : 0
NB. Accept if in WACTOR (if type=1) or WSCORER (do=0 and name matches Gactor) or CHANGE (if do=1 and name matches Gactor)
'name do needscorer' =. y
if. do = (1 ,((name-:Gactor) { 2 2,:0 1),2) {~ (GSWACTOR,GSWSCORER,GSCHANGE) i. Gstate do.
  if. do do.
    NB. We are accepting a name.  Save it and move to WSCORER or WSTART
    if. Gstate=GSCHANGE do.
      Gstate =: needscorer { GSCHANGEWSTART,GSCHANGEWSCORER 
    else.
      Gactor =: name
      NB. If we changing rounds, interpolate CHANGE state
      if. Groundno ~: nextroundno'' do.
        Groundno = nextroundno''
        Gstate =: GSCHANGE
      else. Gstate =: needscorer { GSWSTART,GSWSCORER
      end.
    end.
    if. -. needscorer do. Gscorer =: name end.
  elseif. Gstate e. GSWSTART,GSWSCORER do.
    NB. We are taking an undo, necessarily from SCORER to ACTOR.  Forget the actor's name
    Gactor =: ''
    Gstate =: GSWACTOR
  end.
end.
''
)

NB. name do/undo
postyhSCORER =: 3 : 0
NB. Accept if in WSCORER or CHANGEWSCORER (type=1) or WSTART or CHANGEWSTART (type=0 & name match)
'name do' =. y
if. do = (1 0 ,((name-:Gscorer) { 2 2,:0 0),2) {~ (GSWSCORER,GSWCHANGESCORER,GSWSTART,GSWCHANGEWSTART) i. Gstate do.
  if. do do.
    Gscorer =: name
    Gstate =: (Gstate=GWSCORER) { GSWCHANGEWSTART,GSWSTART
  else.
    NB. It's an undo
    Gscorer =: ''
    Gstate =: (Gstate=GSWSTART) { GSWCHANGESCORER,GSWSCORER
  end.
end.
''
)

NB. nilad
postyhACT =: 3 : 0
NB. Accept in WSTART or CHANGEWSTART
if. Gstate e. GSWSTART,GSWCHANGESTART do.
  NB. go ACTING state.  If we were in START, start the timer.  This starts the turn
  if. Gstate = GSWSTART do.
    Gtimedisp =: Groundno { Groundtimes
    NB. turnwordlist is the list of round;word;score for words that have been moved off the wordqueue.  Taken together, turnwordhist and Gwordqueue
    NB. have all the words that were exposed this turn
    turnwordlist =: 0 3$a:
    NB. We save a copy of the exposedwords before we start so that we can delete words dismissed twice in a row
    prevexposedwords =: exposedwords
  end.
  Gstate =: GSACTING
  getnextword''   NB. Prime the pipe
end.
''
)

NB. Add words to the word queue until it's full.  It holds 2 words
NB. We always take from the exposedwords if there is one.  Otherwise we draw from the bag.
NB. BUT: we never draw a word if it is a different round from the word on the stack
getnextword =: 3 : 0
while. 2 > #Gwordqueue do.
  nextword =. ''  NB. Indicate no word added
  NB. If there is a word in the queue, save its round to indicate we must match it; otherwise empty to match anything
  if. #exposedwords do. if. Groundno = (<0 0) {:: exposedwords do.
    NB. There is a valid exposed word.  Take it
    nextrdwd =. (<0;0 1) { exposedwords [ exposedwords =: }. exposedwords
  end. elseif. #wordbag do. if. Groundno = (<0 0) {:: wordbag do.
    NB. There is a valid word in the bag.  Take it
    nextrdwd =. (<0;0 1) { wordbag [ wordbag =: }. wordbag
  end. end.
  NB. If there is no word to add, exit
  if. 0=#nextrdwd do. break. end.
  NB. Expose the word.  Add the actor to the dqlist for the word
  thisdq =. ((nextrdwd -:"1 (2 {."1 dqlist)) # (2 {"1 dqlist)) -. (-.Gteamup) {:: Gteams
  Gwordqueue =: Gwordqueue , nextrdwd , < thisdq
  dqlist =: dqlist , nextrdwd , < Gactor
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

NB.  {-1 0 1} {01}   score, count wd as played
postyhNEXTWORD =: 3 : 0
'score retire' =. y
NB. Accept only if there is a word in the word queue, and if we are in a scorable state
if. (*@# Gwordqueue) *. Gstate e. GSACTING,GSPAUSE,GSSETTLE do.
  NB. Adjust the score
  Gscore =: (score + Gteamup { score) Gteamup} Gscore
  NB. Move the word from the wordqueue to the turnwordlist
  turnwordlist =: turnwordlist , ({. Gwordqueue) , <score,retire  NB. put rd/wd/score onto turnlist
  Gwordqueue =: }. Gwordqueue
  Gwordundook =: *@# turnwordlist  NB. Allow undo if there's something to bring back
  NB. If we are still acting or paused, top up the qword queue
  if. Gstate e. GSACTING,GSPAUSE do. getnextword'' end.
  NB. If the word queue is still empty, that's a change of state: go to CONFIRM to accept the score and move on.  Keep the time
  NB.   on the timer
  if. isnewround'' do. Gstate =: GSCONFIRM end.
end.
''
)

postyhPREVWORD =: 3 : 0
NB. If there is a word in the turnlist, and  we are acting or paused, or we are settling and there is time on the clock, accept this command
if. Gwordundook *. (Gstate e. GSACTING,GSPAUSE) +. (Gstate e, GSSETTLE,GSCONFIRM) *. Gtimedisp>0 do.
  NB. Move tail of turnwords to head to Gwordqueue, adding in the dq info
  tailwd =. {: turnwordlist
  thisdq =. (((2{.tailwd) -:"1 (2 {."1 dqlist)) # (2 {"1 dqlist)) -. (-.Gteamup) {:: Gteams
  Gwordqueue =: Gwordqueue , (1 { nextrdwd) , < thisdq
  turnwordlist =: }: turnwordlist
  Gwordundook =: *@# turnwordlist  NB. Allow undo if there's something to bring back
  NB. Undo the score
  score =. (2;0) {:: tailwd  NB. score entered for the word
  Gscore =: (score -~ Gteamup { score) Gteamup} Gscore
  NB. Handle changes of state.
  NB. If we are ACTING or PAUSED, and the new word is for a different round, go to CHANGE state for that round
  NB. If we are SETTLING or CONFIRM, stay in that state until the queue is empty
  if. (Gstate e. GSACTING,GSPAUSED) *. Groundno ~: (<0 0) {:: Gwordqueue do. Gstate =: GSCHANGE end.
end.
''
)

NB. nilad
postyhPROCEED =: 3 : 0
NB. Valid only in CHANGE state.  If the timer is running, go to CHANGEWACTOR, otherwise WSCORER of WSTART
if. Gstate=GSCHANGE do.
  Gstate =: (Gtimedisp=0) { GSCHANGEWACTOR,(*@#Gscorer){GSWSCORER,GSWSTART
end.
''
)
NB. nilad
postyhCOMMIT =: 3 : 0
NB. Accept if in CONFIRM state
if. Gstate = GSCONFIRM do.
  NB. If exposed and bag are empty, this actor gets no more words, so take the time away
  if. exposedwords +:&(*@#) wordlist do. Gtimedisp =. 0 end.
  if. Gtimedisp=0 do.
    NB. if no time left, handle end-of-turn
    NB. Display & Discard words that have been passed twice in a row
    oldpass =. ((0;0 0) -:"1 (0 2) {"1 prevexposedwords) # 1 {"1
    newpass =. ((0;0 0) -:"1 (0 2) {"1 turnwordlist) # 1 {"1
    retired =. newpass (e. # [) oldpass  NB. words passed twice in a row in the first round
    Glogtext =: Glogtext , ;@:(('discarded: ' , LF ,~ ])&.>) retired
    turnwordlist =. (retired -.@e.~ 1 {"1 turnwordlist) # turnwordlist
    wordbag =. (retired -.@e.~ 1 {"1 wordbag) # wordbag

    NB. Display & Discard words that have been marked as retired
    handledmsk =. (2;1)&{::"1 turnwordlist  NB. words we finished
    Glogtext =: Glogtext , (2;0)&{::"1 turnwordlist ;@:(({::&('guessed late: ';'guessed: ')@[ , LF ,~ ])&.>) 1 {"1 turnwordlist
    NB. Put the reamining turn words into the exposed list
    exposedwords =: (-. handledmsk) # turnwordlist
  end.
  NB. Figure next state:
  NB. GAMEOVER if the exposed and bag are still empty
  if. exposedwords +:&(*@#) wordlist do. Gstate =: GSGAMEOVER
  NB. CHANGE if it's a round change and there is time - change roundno first
  elseif. (Gtimedisp~:0) *. Groundno~:nextroundno''do.
    Gstate =: GSCHANGE
    Groundno =: nextroundno''  NB. set new round# before going to CHANGE state
  else.
    NB. Should be out of time, since there are no words to act.  Clear time just in case, and go look for next actor, from the other team
    Gtimedisp =: 0 [ Gteamno =: -. Gteamno [ Gstate =: GSWACTOR
  end. 
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
  if. *@# name do. Glogtext =: Glogtext , name , ((incr>0){::' took away ';' added ') , (":|incr) , ' points' , ((incr>0){::' from ';' to ') , 'team ' , (":team) , LF end.
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
    if. *@# name do. Glogtext =: Glogtext , name , ((incr>0){::' took away ';' added ') , (":|incr) , ' seconds ' , LF end.
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
        NB. Transitioning from some time to no time, i. e. the buzzer sounds.  If the queue is empty, CONFIRM, otherwise SETTLE
        Gstate =: (*@#Gwordqueue) { GSCONFIRM,GSSETTLE
      end.
    end.
  end.
end.

''
)


getsk =: 3 : 0
)
sendcmd =: 4 : 0
senddata =. x fileserv_addreqhdr_sockfileserver_ y
rc =. sdconnect_jsocket_ sk;(}.qbm),<8090
qprintf'rc '
while. #senddata do.
rc =. senddata sdsend_jsocket_ sk,0
qprintf'rc '
senddata =. (1{::rc) }. senddata
recvdata =. ''
end.
for. i. 20 do.
  rsockl =. 1 {:: sdselect_jsocket_ sk;'';sk;1000
qprintf 'rsockl '
  if. sk e. rsockl do.
    'r data' =. sdrecv_jsocket_ sk,10000,0
qprintf'r data '
    if. 0=#data do. break. end.
    recvdata =. recvdata , data
  end.
end.
recvdata
)
0 : 0
(<'1111111') sendcmd 'INCR "t1000" "bonlog" "0"',CRLF,'a' [ getsk''
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
