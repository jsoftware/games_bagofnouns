require 'socket'
require 'strings'
require 'pacman'
sdcleanup_jsocket_ =: 3 : '0[(sdclose ::0:"0@[ shutdownJ@(;&2)"0)^:(*@#)SOCKETS_jsocket_'
'update' jpkg 'games/bagofnouns'  NB. Get new info
'upgrade' jpkg 'games/bagofnouns'  NB. Get any updates
3 : 0 ''
sdcleanup_jsocket_''  NB. debugging
lsk =. 1 {:: sdsocket_jsocket_ ''  NB. listening socket
rc =. sdbind_jsocket_ lsk ; AF_INET_jsocket_ ; '' ; 8090  NB. listen on port 8090
sdcleanup_jsocket_''  NB. stop listening
if. 0~:rc do.
  NB. socket already bound - load the gui
  load '~addons/games/bagofnouns/bagofnounsgui.ijs'
  formbon_run''
else.
  NB. socket not bound - reset & start the backend
  load '~addons/games/bagofnouns/bagofnounsbe.ijs'
  startgame 't1000';'1111111'
end.
)
