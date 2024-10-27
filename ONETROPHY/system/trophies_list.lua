--[[ 
	----------Trophy Manager------------
	Create and organize your direct adrenaline bubbles.
	
	Licensed by GNU General Public License v3.0
	
	Designed By:
	- Gdljjrod (https://twitter.com/gdljjrod).
]]

--[[
"groupid"			Group ID
"trophyid"  		id
"unlocked",			Unlocked/locked
"type",				trophy grade
"hidden"			1/0
"title","details"	Title and description of the trophies

]]

local trophyL,gid = {},-1

trophies_type = {
	name = {STRINGS_TROPHY_PLATINUM, STRINGS_TROPHY_GOLD, STRINGS_TROPHY_SILVER, STRINGS_TROPHY_BRONZE },
	num = {	0,1,2,3,4,5 },
	win = {STRINGS_TROPHY_LOCKED, STRINGS_TROPHY_UNLOCKED },
	hid = {STRINGS_HIDDEN_NO, STRINGS_HIDDEN_YES }
}

function get_trophiesL(obj)

	if obj.group > 0 then gid = obj.group end
	local tmp = trophy.list(obj.npcommid, gid)

	if tmp and #tmp> 0 then

		game.umount()
		buttons.homepopup(0)
		game.mount(DATA_TROPHY..obj.npcommid.."/")
		local fp = io.open(DATA_TROPHY..obj.npcommid.."/TRPTITLE.DAT","r")
		fp:seek("set", 0)
		trptitle = fp:read("*a")

		for i=1, #tmp do
			tmp[i].trophyid = tonumber(tmp[i].trophyid)
			tmp[i].groupid = tonumber(tmp[i].groupid)
			tmp[i].unlocked = tonumber(tmp[i].unlocked)
			tmp[i].type = tonumber(tmp[i].type)
			tmp[i].hidden = tonumber(tmp[i].hidden)
			if tmp[i].hidden == 1 then
				if tmp[i].unlocked == 1 then tmp[i].view = true else tmp[i].view = false end
			else
				tmp[i].view = true
			end

			local trophy_offset2 = readBE4(trptitle, BASETROP2) + (tmp[i].trophyid * TRPBLOCK2)
			local trophyblock2 = string.sub(trptitle, trophy_offset2 + 1, trophy_offset2 + TRPBLOCK2)

			--# Checks if trophy is already unlocked and synced
			tmp[i].unlocked = trophyblock2:byte(TROPHYSTATE+1)
			tmp[i].synced = trophyblock2:byte(TROPHYSSYNC+1)

			-- Obtain unlocktime and synced time from trophy block 1 for later use
			tmp[i].unlocktime = string.sub(trophyblock2, TROPHYDATE1 + 1, TROPHYDATE1 + 8)
			tmp[i].synctime = string.sub(trophyblock2, TROPHYDATE2 + 1, TROPHYDATE2 + 8)

			tmp[i].pathicon = ICONS_TROPHY..obj.npcommid.."/TROP"..string.rep("0", 3 - string.len(tmp[i].trophyid))..tmp[i].trophyid..".PNG"
			table.insert(trophyL,tmp[i])
		end
		game.umount()

		buttons.homepopup(1)
	end

end

function trophies_list(obj)

	--Clean
	trophyL,gid,icon,icon_lock = {},-1,nil,nil

	get_trophiesL(obj)

	if trophyL and #trophyL > 0 then

		if gid == -1 then
			icon = image.load(CONF_TROPHY..obj.npcommid.."/ICON0.PNG")
		else
			icon = image.load(CONF_TROPHY..obj.npcommid.."/GR"..string.rep("0", 3 - string.len(gid))..gid..".PNG")
		end
		if icon then icon:resize(960,544) end

		table.sort(trophyL, function (a,b) return a.trophyid<b.trophyid end)
	end

	local maxim,inter,d_scroll,t_scroll,init_scroll,sort_L = 5,55,25,25,25,1
	local scroll = newScroll(trophyL,maxim)
	local splits = {" ", "-", "-", " ", ":", ":", ""}

	buttons.interval(12,5)
	while true do
		buttons.read()
		if back then back:blit(0,0) end
		if icon then icon:blit(0,0,85) end

		local selectx, selecty
		---------------------------Impresion en pantalla-----------------------------------
		if screen.textwidth(obj.title,1) > 870 then
			init_scroll = screen.print(init_scroll,35,obj.title,1,color.white,color.black,__SLEFT,860)
		else
			screen.print(25,35,obj.title,1,color.white,color.black)
		end
		screen.print(955,10,"("..scroll.maxim..")",1,color.red,color.black, __ARIGHT)

		if scroll.maxim > 0 and trophyL then

			local y=85
			for i=scroll.ini, scroll.lim do

				if i == scroll.sel then
					if scroll.maxim >= maxim then
						draw.offsetgradrect(20,y-3,870,60,color.shine:a(75),color.shine:a(135),0x0,0x0,21)
					else
						draw.offsetgradrect(5,y-3,885,60,color.shine:a(75),color.shine:a(135),0x0,0x0,21)
					end

					if trophyL[scroll.sel].view then
						if screen.textwidth( trophyL[scroll.sel].details,1) > 945 then
							d_scroll = screen.print(d_scroll,510,trophyL[scroll.sel].details,1,color.white,color.black, __SLEFT,920)
						else
							screen.print(480,510,trophyL[scroll.sel].details,1,color.white,color.black, __ACENTER)
						end

					else
						screen.print(480,510,STRINGS_TROPHY_WARNING_HIDDEN,1.5,color.yellow,color.black, __ACENTER)
					end

				end

				--Bar Scroll
				if scroll.maxim >= maxim then
					local ybar,h=83, (maxim*(inter + 15))-5
					draw.fillrect(5, ybar-2, 8, h, color.shine:a(50))
					--if scroll.maxim >= maxim then -- Draw Scroll Bar
						local pos_height = math.max(h/scroll.maxim, maxim)
						draw.fillrect(5, ybar-2 + ((h-pos_height)/(scroll.maxim-1))*(scroll.sel-1), 8, pos_height, color.green:a(125))
					--end
				end

				--Title
				if screen.textwidth( string.rep("0", 3 - string.len(trophyL[i].trophyid + 1))..(trophyL[i].trophyid + 1).."   "..trophyL[i].title,1) > 800 then
					t_scroll = screen.print(t_scroll,y+2,string.rep("0", 3 - string.len(trophyL[i].trophyid + 1))..(trophyL[i].trophyid + 1).."   "..trophyL[i].title,1,color.white,color.blue,__SLEFT,790)
				else
					screen.print(25,y+2,string.rep("0", 3 - string.len(trophyL[i].trophyid + 1))..(trophyL[i].trophyid + 1).."   "..trophyL[i].title,1,color.white,color.blue)
				end

				if trophyL[i].unlocked == 0 then cc=color.white else cc=color.green:a(200) end
				local textL = screen.print(25, y + (inter/2), STRINGS_TROPHY_TYPE.." "..trophies_type.name[trophyL[i].type]..",  "..STRINGS_TROPHY_HIDDEN.."  "..trophies_type.hid[trophyL[i].hidden+1]..", "..STRINGS_TROPHY_STATUS.."  ",1,cc,color.blue:a(85))
				if editing.status == true and i == scroll.sel then
					-- print the editing
					local ey = y + (inter/2)
					local ex = textL + 27
					textw = screen.textwidth(table.concat(editing.values)..table.concat(splits)) + 8
					draw.fillrect(ex-4,  ey-6 , textw, 28, color.blue:a(125))
					for p, v in pairs(editing.values) do
						local ox = screen.print(ex, ey, v,1,cc,color.red:a(85))
						if p == editing.position then
							draw.fillrect(ex,  ey -6, ox, 28, color.green:a(125))
							screen.print(ex, ey, v,1,cc,color.red:a(85))
						end
						ex = ex + ox + screen.print(ex+ox, ey, splits[p],1,cc,color.red:a(85))
					end
				else
					screen.print(25+textL+2, y + (inter/2), trophies_type.win[trophyL[i].unlocked + 1].." "..formatTimestamp(decodeTimestamp(trophyL[i].unlocktime)),1,cc,color.blue:a(85))
				end

				--Blit icon
				if not trophyL[i].icon then
					trophyL[i].icon = image.load(trophyL[i].pathicon)

					if trophyL[i].icon then
						trophyL[i].icon:resize(60,60)
						trophyL[i].icon:center()
					end
				end

				--Show Trophies
				if trophyL[i].view then
					if trophyL[i].icon then
						trophyL[i].icon:blit(955 - (trophyL[i].icon:getw()/2), y + (inter/2))
					else
						draw.fillrect(895, y-2,60,60,color.shine:a(75))
					end
				else
					if img_trophies then img_trophies:blitsprite(895,y-2, 5)
					else draw.fillrect(895, y-2,60,60,color.shine:a(75)) end
				end

				if trophyL[i].unlocked == 0 then
					if img_trophies then img_trophies:blitsprite(830,y-2,4)
					else draw.fillrect(830, y-2,60,60,color.shine:a(75)) end
				else
					--Trophy Grade
					if img_trophies then
						img_trophies:blitsprite(830,y-2, trophies_type.num[trophyL[i].type])
					else
						draw.fillrect(830, y-2,60,60,color.shine:a(75))
					end
				end

				y+=inter + 15

			end --for

			if editing.status == false then
				if trophyL[scroll.sel].hidden == 1 then
					if buttonskey then buttonskey:blitsprite(10,447,2) end                     		--[]
					screen.print(40,450,STRINGS_SHOW_DETAILS,1,color.white,color.black,__ALEFT)
				end

				if buttonskey2 then buttonskey2:blitsprite(5,467,0) end
				screen.print(40,470,STRINGS_SORT.._SORT_L[sort_L],1,color.white,color.black,__ALEFT)

				if buttonskey then buttonskey:blitsprite(940,467,accept_p) end                     --Accept to modify
				screen.print(935,470,STRINGS_MODIFY_TROPHY,1,color.white,color.black,__ARIGHT)
			else
				-- modify trophy
				if buttonskey3 then buttonskey3:blitsprite(5,447,0) end                            --Arrow left & right
				if buttonskey3 then buttonskey3:blitsprite(25,447,1) end
				screen.print(50,447,STRINGS_SWITCH_MODIFY,1,color.white,color.black,__ALEFT)
				if buttonskey3 then buttonskey3:blitsprite(5,467,2) end                            --Arrow up & down
				if buttonskey3 then buttonskey3:blitsprite(25,467,3) end
				screen.print(50,470,STRINGS_MODIFY_VALUE,1,color.white,color.black,__ALEFT)

				if buttonskey then buttonskey:blitsprite(940,447,accept_p) end                     --Accept to apply modify
				screen.print(935,450,STRINGS_APPLY_MODIFY,1,color.white,color.black,__ARIGHT)

				if buttonskey then buttonskey:blitsprite(940,467,cancle_p) end                     --Cancel
				screen.print(935,470,STRINGS_CANCLE_MODIFY,1,color.white,color.black,__ARIGHT)
			end

		else
			screen.print(480,272,STRINGS_EMPTY,1.5,color.yellow,color.black,__ACENTER)
		end

		screen.flip()

		----------------------------------Controls-------------------------------
		if scroll.maxim > 0 and trophyL then

			if editing.status then
				-- Button controls for modify values
				modify_control(obj, trophyL[scroll.sel])

			else
				-- buttons controls when not in editing mode

				if buttons[accept] then modify_start(trophyL[scroll.sel]) end -- Accept button to start modify

				if (buttons.up or buttons.held.l or buttons.analogly<-60) then
					if scroll:up() then d_scroll,t_scroll,init_scroll = 25,25,25 end
				end

				if (buttons.down or buttons.held.r or buttons.analogly>60) then 
					if scroll:down() then d_scroll,t_scroll,init_scroll = 25,25,25 end
				end

				if buttons.square then
					if trophyL[scroll.sel].unlocked == 0 then
						if trophyL[scroll.sel].hidden == 1 then
							trophyL[scroll.sel].view = not trophyL[scroll.sel].view
						end
					end
				end

				if buttons.select then
					if sort_L == 1 then
						sort_L = 2
						table.sort(trophyL, function (a,b) return sortTimestamp(a.unlocktime, b.unlocktime) end)
					elseif sort_L == 2 then
						sort_L = 3
						table.sort(trophyL, function (a,b) return a.hidden>b.hidden end)
					elseif sort_L == 3 then
						sort_L = 1
						table.sort(trophyL, function (a,b) return a.trophyid<b.trophyid end)
					end
				end

--[[
			if buttons[accept] and obj.exist then
				game.umount()
					game.mount("ux0:/app/"..obj.ID)
					os.message(tostring(trophy.init(obj.npcommid, obj.commsign, trophyL[scroll.sel].trophyid)))
				game.umount()
			end
]]
			end
		end

		if buttons[cancel] then
			trophyL = {}

			collectgarbage("collect")
			os.delay(250)

			buttons.read()
			break
		end

	end
end
