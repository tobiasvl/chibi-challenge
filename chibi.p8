pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- chibi challenge
-- by tobiasvl

stock_print=print
function print(s,x,y,col)
  col=col or peek(0x5f25)
  x=x or peek(0x5f26)
  y=y or peek(0x5f27)
  s=tostr(s)
  local d=""
  local l,c,t=false,false
  for i=1,#s do
    local a=sub(s,i,i)
    if a=="~" then
      if(t) d=d..a
      t,l=not t,not l
    else
      if c==l and a>="a" and a<="z" then
        for j=1,26 do
          if a==sub("abcdefghijklmnopqrstuvwxyz",j,j) then
            a=sub("\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90\91\92",j,j)
            break
          end
        end
      end
      d=d..a
      c,t=false,false
    end
  end
  stock_print(d,x,y,col)
  poke(0x5f27,y+5)
end

modes={
  title_screen=1,
  play=2,
  win=3,
  game_over=4,
  tutorial=5,
  custom=7,
  custom_play=8,
  win_custom=9,
  game_over_custom=10,
}

function _init()
  poke(0x5f2c,3)
  mode=modes.title_screen
  menu_selection=1
  score=0
  run=0
  last_mouse,last_x,last_y=0,0,0
  cartdata("tobiasvl_chibi_challenge")
  poke(0x5f2d,1)
  title_dir=true
  emulated=stat(102)!=0
  keyboard=stat(102)!=0 and stat(102)!="www.lexaloffle.com" and stat(102)!="www.playpico.com"
  buttons={o=keyboard and "z" or "🅾️",x=keyboard and "x" or "❎"}
  kill=false
  mouse_pointer=0
  fred=0
  music(0)
end

menu={
  {function() init_board() mode=modes.play music(-1) end, "play"},
  {function() init_board(true) page=1 mode=modes.tutorial music(-1) end, "tutorial"},
  {function() init_board(true,true) mode=modes.custom music(-1) end, "custom"}
}

keys={
  [1]=function(x,y) return x>1 and x>patrick.x-1 and x-1 or x,y end,
  [2]=function(x,y) return x<7 and x<patrick.x+1 and x+1 or x,y end,
  [4]=function(x,y) return x,y>1 and y>patrick.y-1 and y-1 or y end,
  [8]=function(x,y) return x,y<4 and y<patrick.y+1 and y+1 or y end,
}

kls=cls
function cls()
  if (not kill) kls()
end

function _update()
  if (run>63 or fred>7) kill=true
  local button=btnp()
  local mouse=stat(34)==1
  local temp_mouse=mouse
  mouse=mouse!=last_mouse and mouse or false
  last_mouse=temp_mouse
  if mode==modes.title_screen then
    menuitem(1)
    if (button==4) menu_selection=menu_selection==1 and #menu or menu_selection-1
    if (button==8) menu_selection=(menu_selection%#menu)+1
    if (button==0x10) menu[menu_selection][1]()
    local x,y=stat(32),stat(33)
    if (emulated) x/=2 y/=2
    cursor(10,25)
    if x!=old_x or y!=old_y or mouse then
      old_x,old_y=x,y
      if x>=10 and x<=34 and y>=25 and y<=29 then
        menu_selection=1
      elseif x>=10 and x<=48 and y>=31 and y<=35 then
        menu_selection=2
      elseif x>=10 and x<=42 and y>=37 and y<=41 then
        menu_selection=3
      end
    end
    if mouse then
      if x>=2 and x<=4 and y>=2 and y<=4 then
        fred+=1
      else
        menu[menu_selection][1]()
      end
      mouse=false
    end
  elseif mode==modes.play or mode==modes.custom_play then
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
    if (mode==modes.play and button==0x20 and destroyed==0) init_board()
    if destroyed==27 then
      sfx(25)
      mode=mode==modes.play and modes.win or modes.win_custom
    elseif get_tile(patrick.x-1,patrick.y)==-1 and get_tile(patrick.x+1,patrick.y)==-1 and get_tile(patrick.x-1,patrick.y-1)==-1 and get_tile(patrick.x,patrick.y-1)==-1 and get_tile(patrick.x+1,patrick.y-1)==-1 and get_tile(patrick.x-1,patrick.y+1)==-1 and get_tile(patrick.x,patrick.y+1)==-1 and get_tile(patrick.x+1,patrick.y+1)==-1 then
      sfx(8)
      mode=mode==modes.play and modes.game_over or modes.game_over_custom
    end
    new_highlight={}
    new_highlight.x,new_highlight.y=highlight.x,highlight.y
    if button!=0 then
      for mask in all({1,2,4,8}) do
        if band(button,mask)!=0 then
          new_highlight.x,new_highlight.y=keys[mask](new_highlight.x,new_highlight.y)
        end
      end
    else
      local x,y=stat(32),stat(33)
      if (emulated) x/=2 y/=2
      if x!=old_x or y!=old_y or mouse then
        old_x,old_y=x,y
        x,y=ceil(x/9),ceil(y/9)
        new_highlight.x=(x==patrick.x-1 or x==patrick.x or x==patrick.x+1) and x or 0
        new_highlight.y=(y==patrick.y-1 or y==patrick.y or y==patrick.y+1) and y or 0
      end
    end
    if get_tile(new_highlight.x,new_highlight.y)>=0 then
      highlight=new_highlight
    end
    if (button==0x10 or mouse) and not (highlight.x==patrick.x and highlight.y==patrick.y) then
      steps+=1
      mouse=false
      destroy_tile(patrick.x,patrick.y)
      patrick.x,patrick.y=highlight.x,highlight.y
      local tile=get_tile(highlight.x,highlight.y)
      if tile>0 then
        sfx(33)
        if tile==7 or tile==2 then
          destroy_tile(highlight.x-1,highlight.y-1)
          destroy_tile(highlight.x,highlight.y-1)
          destroy_tile(highlight.x+1,highlight.y-1)
        end
        if tile==3 or tile==2 then
          destroy_tile(highlight.x-1,highlight.y+1)
          destroy_tile(highlight.x,highlight.y+1)
          destroy_tile(highlight.x+1,highlight.y+1)
        end
        if tile==4 or tile==5 then
          destroy_tile(highlight.x-1,highlight.y-1)
          destroy_tile(highlight.x-1,highlight.y)
          destroy_tile(highlight.x-1,highlight.y+1)
        end
        if tile==6 or tile==5 then
          destroy_tile(highlight.x+1,highlight.y-1)
          destroy_tile(highlight.x+1,highlight.y)
          destroy_tile(highlight.x+1,highlight.y+1)
        end
        set_tile(highlight.x,highlight.y,0)
      elseif destroyed!=27 then
        sfx(60)
      end
    end
  elseif mode==modes.win then
    if btnp(4) or mouse then
      score+=60-steps
      run+=1
      if (score>high_score) dset(1,score) dset(2,run)
      init_board()
      mode=modes.play
      mouse=false
    end
  elseif mode==modes.game_over then
    if btnp(4) or mouse then
      score=max(0,score-60+steps)
      run+=1
      if (score>high_score) dset(1,score) dset(2,run)
      init_board()
      mode=modes.play
      mouse=false
    end
  elseif mode==modes.win_custom or mode==modes.game_over_custom then
    if btnp(4) or mouse then
      board=backup.board
      patrick=backup.patrick
      balls=backup.balls
      mode=modes.custom
      mouse=false
    end
  elseif mode==modes.tutorial then
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
    if btnp(4) or mouse then
      page+=1
      if (page==7) init_board()
      if (page==13) mode=modes.play
    end
    if page==6 then
      for y=1,4 do
        for x=1,7 do
          if (not (patrick.x==x and patrick.y==y)) board[y][x]=-1
        end
      end
    elseif page==4 then
      local new_patrick={x=patrick.x,y=patrick.y}
      mask=flr(rnd(15))+1
      for i in all({band(mask,1),band(mask,2)}) do
        local should_break=false
        for j in all({band(mask,4),band(mask,8)}) do
          if (i!=0) new_patrick.x,new_patrick.y=keys[i](patrick.x,patrick.y)
          if (j!=0) new_patrick.x,new_patrick.y=keys[j](new_patrick.x,new_patrick.y)
          if get_tile(new_patrick.x,new_patrick.y)==0 then
            if (not (new_patrick.x==patrick.x and new_patrick.y==patrick.y)) destroy_tile(patrick.x,patrick.y) patrick=new_patrick should_break=true break
          end
        end
        if (should_break) break
      end
    end
  elseif mode==modes.custom then
    menuitem(1,"title screen",function() mode=modes.title_screen music(0) end)
    if patrick.x>0 and btnp(4) then
      highlight.x,highlight.y=patrick.x,patrick.y
      mode=modes.custom_play
      steps=0
      destroyed=0
      backup={}
      backup.board,backup.balls,backup.patrick={},{},{}
      backup.patrick.x,backup.patrick.y=patrick.x,patrick.y
      for y=1,4 do
        backup.board[y]={}
        for x=1,7 do
          backup.board[y][x]=board[y][x]
        end
      end
      for i=1,7 do
        backup.balls[i]={}
        backup.balls[i].id=balls[i].id
        backup.balls[i].color=balls[i].color
        backup.balls[i].pos=balls[i].pos
      end
    end
    if mouse then
      local x,y=stat(32),stat(33)
      if (emulated) x/=2 y/=2
      if old_x!=x or old_y!=y or mouse then
        old_x,old_y=x,y
        local cell_x,cell_y=ceil(x/9),ceil(y/9)
        if mouse_pointer!=0 and get_tile(cell_x,cell_y)==-1 then
          mouse_pointer=0
        elseif patrick.x==-1 and x>=1 and x<=9 and y>=44 and y<=53 then
          mouse_pointer=1
        elseif patrick.x==cell_x and patrick.y==cell_y then
          patrick={x=-1,y=-1}
          balls[1].pos=0
          mouse_pointer=1
        elseif balls[2].pos==0 and x>=11 and x<=11+5 and y>=39+2 and y<=39+5+2 then
          mouse_pointer=2
        elseif balls[3].pos==0 and x>=11+7 and x<=11+5+7 and y>=39+2 and y<=39+5+2 then
          mouse_pointer=3
        elseif balls[4].pos==0 and x>=11+7+7 and x<=11+5+7+7 and y>=39+2 and y<=39+5+2 then
          mouse_pointer=4
        elseif balls[5].pos==0 and x>=11 and x<=11+5 and y>=39+7+2 and y<=39+7+5+2 then
          mouse_pointer=5
        elseif balls[6].pos==0 and x>=11+7 and x<=11+5+7 and y>=39+7+2 and y<=39+7+5+2 then
          mouse_pointer=6
        elseif balls[7].pos==0 and x>=11+7+7 and x<=11+5+7+7 and y>=39+7+2 and y<=39+7+5+2 then
          mouse_pointer=7
        elseif get_tile(cell_x,cell_y)==0 and mouse_pointer>0 then
          if mouse_pointer==1 then
            patrick.x,patrick.y=cell_x,cell_y
          elseif mouse_pointer>0 then
            set_tile(cell_x,cell_y,balls[mouse_pointer].id)
          end
          balls[mouse_pointer].pos=cell_x+(7*(cell_y-1))
          mouse_pointer=0
        elseif get_tile(cell_x,cell_y)>0 then
          local pick_up=get_tile(cell_x,cell_y)
          set_tile(cell_x,cell_y,0)
          balls[pick_up].pos=0
          if (pick_up==1) patrick.x,patrick.y=-1,-1
          if mouse_pointer==1 then
            patrick.x,patrick.y=cell_x,cell_y
            balls[mouse_pointer].pos=cell_x+(7*(cell_y-1))
          elseif mouse_pointer>0 then
            set_tile(cell_x,cell_y,balls[mouse_pointer].id)
            balls[mouse_pointer].pos=cell_x+(7*(cell_y-1))
          end
          mouse_pointer=pick_up
        end
      end
    end
  end
end

function _draw()
  if mode==modes.title_screen then
    local x,y=stat(32),stat(33)
    if (emulated) x/=2 y/=2
    cls()
    if (fred==1) print("hello\nfred",0,13)
    if (fred==2) print("how are\nthe kids?",0,13)
    cursor(0,1)
    center("chibi",3)
    center("challenge",3)
    cursor(10,25)
    for i=1,3 do
      color(menu_selection==i and 7 or 6)
      if (menu_selection==i) then
        stock_print("> "..menu[i][2])
      else
        stock_print("  "..menu[i][2])
      end
    end
    color()
    high_score=dget(1)
    high_run=dget(2)
    cursor(0,64-12)
    center("hiscore: "..high_score,7)
    center("(run: "..high_run.." levels)",7)
    cursor(0,107)
    center("by",5)
    center("tobiasvl",5)
    if x>=15 and x<=18 and y>=3 and y<=6 then
      spr(15,x,y,1,2)
    else
      if (not emulated) spr(16,x,y)
    end
  elseif mode==modes.tutorial then
    print_board()
    cursor(1,38)
    color(7)
    if page==1 then
      print("the object of")
      print("the game is to")
      print("remove all 28")
      print("squares.")
    elseif page==2 then
      print("patrick can move")
      print("to any adjacent")
      print("square (also")
      print("diagonally)")
    elseif page==3 then
      print("          ⬆️")
      print("select: ⬅️⬇️➡️")
      print("move:     "..(keyboard and " " or "")..buttons.o)
      print("      (or mouse)")
    elseif page==4 then
      print("each time pat-")
      print("rick moves, the")
      print("square he was on")
      print("will disappear.")
    elseif page==5 then
      spr(17,(8*(patrick.x-1)+1*(patrick.x)),(8*(patrick.y-1)+1)+1*(patrick.y-1))
      print("you will lose if")
      print("patrick can't")
      print("move to any")
      print("square.")
    elseif page==6 then
      spr(5,(8*(patrick.x-1)+1*(patrick.x)),(8*(patrick.y-1)+1)+1*(patrick.y-1))
      print("if all squares")
      print("disappear, you")
      print("win. either way,")
      print("a new level will")
      print("be generated.")
    elseif page==7 then
      print("moving")
      print("to a ball")
      print("destroys")
      print("squares")
      print("around it. see^")
      print_legend()
    elseif page==8 then
      print("win: gain 60 pts")
      print("minus number of")
      print("steps.")
    elseif page==9 then
      print("lose: lose 60")
      print("pts plus number")
      print("of steps.")
    elseif page==10 then
      print("maybe some are")
      print("unsolvable?")
      print("you can skip a")
      print("level with "..buttons.x)
      print("(don't move).")
    elseif page==11 then
      cursor(0,37)
      print("each level has a")
      print("numbered code.")
      print("use the \"custom\"")
      print("mode to input.")
      print_code()
    elseif page==12 then
      print("share the codes")
      print("with friends!")
      print("good luck now!")
      print_code()
    end
  elseif mode==modes.play or mode==modes.win or mode==modes.game_over or mode==modes.custom_play then
    print_board()
    if mode!=modes.custom_play then
      print("level"..(kill and "-" or " ")..run+1,1,38,7)
      print("score "..score,1,44,7)
    end
    if (mode==modes.play) print("steps "..steps,1,50,5)
    print_legend()
    print_code()
    if (not emulated) spr(16,stat(32),stat(33))
  end
  if mode==modes.win then
    local s=buttons.o..": next"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..score,1,44,5)
    print("+  60-"..steps,1,50,11)
  elseif mode==modes.game_over then
    spr(17,(8*(patrick.x-1)+1*(patrick.x)),(8*(patrick.y-1)+1)+1*(patrick.y-1))
    local s=buttons.o..": next"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..score,1,44,5)
    print("-  60+"..steps,1,50,8)
  elseif mode==modes.win_custom then
    local s=buttons.o..": edit"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("score "..60-steps,0,100,11)
  elseif mode==modes.game_over_custom then
    local s=buttons.o..": edit"
    print(s,128-((keyboard and 7 or 8)*4),0,7)
    print("lose -"..60+steps,0,106,8)
  elseif mode==modes.custom then
    cls()
    print_board()
    print_code()
    print_legend()
    local mouse_x,mouse_y=stat(32),stat(33)
    if (emulated) mouse_x/=2 mouse_y/=2
    if mouse_pointer==1 then
      spr(1,mouse_x,mouse_y)
    elseif patrick.x==-1 then
      spr(1,1,44)
    else
      spr(1,(8*(patrick.x-1)+1*(patrick.x)),8*(patrick.y-1)+1+1*(patrick.y-1))
    end
    local x,y=9,39
    for i=2,7 do
      if mouse_pointer==i then
        rectfill(mouse_x+2,mouse_y+3,mouse_x+7,mouse_y+6,balls[i].color) rectfill(mouse_x+3,mouse_y+2,mouse_x+6,mouse_y+7,balls[i].color)
      elseif balls[i].pos==0 then
        rectfill(x+2,y+3,x+7,y+6,balls[i].color) rectfill(x+3,y+2,x+6,y+7,balls[i].color)
      end
      x+=7
      if (x==9+(3*7)) x,y=9,y+7
    end
    if (not emulated) spr(16,mouse_x,mouse_y)
  end
  cursor()
end

function center(str,c)
  local x=peek(0x5f26)
  poke(0x5f26,32-(#str*2))
  c=c or 7
  color(c)
  stock_print(str)
  poke(0x5f26,x)
end

function print_board()
  cls()
  if (destroyed==0 and mode==modes.play) local s=buttons.x..": skip" print(s,128-((keyboard and 7 or 8)*4),0,7)
  local offset=0
  for y=1,4 do
    for x=1,7 do
      local tile=get_tile(x,y)
      if tile>=0 then
        local x_tlc=8*(x-1)+1*(x-1)
        local y_tlc=8*(y-1)+1*(y-1)
        rect(x_tlc,offset+y_tlc,x_tlc+9,offset+y_tlc+9,7)
        local bg=5
        if ((mode==modes.play or mode==modes.custom_play or (mode==modes.tutorial and (page==2 or page==3))) and not kill and (x==patrick.x-1 or x==patrick.x or x==patrick.x+1) and (y==patrick.y-1 or y==patrick.y or y==patrick.y+1)) bg=6
        if (patrick.x==x and patrick.y==y) bg=0
        if (highlight.x==x and highlight.y==y) bg=14
        if mode==modes.play or mode==modes.custom_play then
          local highlighted_tile=get_tile(highlight.x,highlight.y)
          if not kill and highlighted_tile>0 then
            if highlighted_tile==7 or highlighted_tile==2 then
              if (y==highlight.y-1 and (x==highlight.x-1 or x==highlight.x or x==highlight.x+1)) bg=0
            end
            if highlighted_tile==3 or highlighted_tile==2 then
              if (y==highlight.y+1 and (x==highlight.x-1 or x==highlight.x or x==highlight.x+1)) bg=0
            end
            if highlighted_tile==4 or highlighted_tile==5 then
              if (x==highlight.x-1 and (y==highlight.y-1 or y==highlight.y or y==highlight.y+1)) bg=0
            end
            if highlighted_tile==6 or highlighted_tile==5 then
              if (x==highlight.x+1 and (y==highlight.y-1 or y==highlight.y or y==highlight.y+1)) bg=0
            end
          end
        end
        rectfill(x_tlc+1,offset+y_tlc+1,x_tlc+8,offset+y_tlc+8,bg)
        if (tile>0) rectfill(x_tlc+2,offset+y_tlc+3,x_tlc+7,y_tlc+6,balls[tile].color) rectfill(x_tlc+3,offset+y_tlc+2,x_tlc+6,y_tlc+7,balls[tile].color)
      end
    end
  end
  spr(1,(8*(patrick.x-1)+1*(patrick.x)),offset+(8*(patrick.y-1)+1)+1*(patrick.y-1))
end

function print_code()
  local x=0
  print(balls[1].pos,x,58,7)
  x+=(#(tostr(balls[1].pos))*4)+1
  for i=7,2,-1 do
    stock_print(balls[i].pos,x,58,balls[i].color)
    x+=(#tostr(balls[i].pos)*4)+1
  end
end

function print_legend()
  print("legend",40,37,6)
  spr(2,40,43)
  spr(3,48,43)
  spr(4,56,43)
  spr(18,40,51)
  spr(19,48,51)
  spr(20,56,51)
end

function init_board(skip_balls,skip_patrick)
  balls={
    {id=1,color=7,pos=0},
    {id=2,color=9,pos=0},
    {id=3,color=8,pos=0},
    {id=4,color=11,pos=0},
    {id=5,color=1,pos=0},
    {id=6,color=12,pos=0},
    {id=7,color=10,pos=0}
  }
  if not skip_balls then
    for ball in all(balls) do
      ball.pos=flr(rnd(28))+1
    end
  end
  if (not skip_patrick) balls[1].pos=flr(rnd(28))+1 else patrick={x=-1,y=-1}
  steps=0
  destroyed=0
  board={}
  highlight={}
  local location=0
  for y=1,4 do
    add(board,{})
    for x=1,7 do
      location+=1
      add(board[y],0)
      for ball in all(balls) do
        if (location==ball.pos) then
          if (ball.id==1) patrick={x=x,y=y} else set_tile(x,y,ball.id)
          break
        end
      end
    end
  end
  if (not skip_patrick) highlight.x,highlight.y=patrick.x,patrick.y
end

function get_tile(x,y)
  if x>=1 and x<=7 and y>=1 and y<=4 then
    return board[y][x]
  else
    return -1
  end
end

function set_tile(x,y,val)
  if x>=1 and x<=7 and y>=1 and y<=4 and board[y][x]!=val then
    board[y][x]=val
    return true
  else
    return false
  end
end

function destroy_tile(x,y)
  if (set_tile(x,y,-1)) destroyed+=1
end

__gfx__
00000000003333006666666066666660666666600033330000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333336060606065656560606060603333333300000000000000000000000000000000000000000000000000000000000000000000000000000000
007007004ffffff46666666066666660666666604ffffff400000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffcffcff656a65606568656065696560ffcffcff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffffffff666666606666666066666660ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700f8ffff8f656565606060606060606060f888888f00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000f8888f06666666066666660666666600f8888f000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ffff0000000000000000000000000000ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000000003333006666666066666660666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33000000333333336065656065656060606560600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333000004ffffff46666666066666660666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33330000ffcffcff606b6560656c6060606160600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333000ffffffff6666666066666660666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33300000fff88fff6065656065656060606560600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300000000f8ff8f06666666066666660666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
