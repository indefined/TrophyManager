--[[
	----------Trophy Manager------------
	Tool to preview or modify your psvita trophies

	Licensed by GNU General Public License v3.0

	Designed By:
	- Gdljjrod (https://twitter.com/gdljjrod).

	trophies_modify.lua: Lock & unlocked trophy by modify files
	Origin by @ AnalogMan151 (https://github.com/AnalogMan151/PSVTrophyIsGreat)
	Port by @ indefined (https://github.com/indefined)
]]

editing = {status = false, position = 1, value = {}}

function unlock_trophy(obj, trop, timestamp)

	local dir = DATA_TROPHY..obj.npcommid
	buttons.homepopup(0)
	game.umount()
	game.mount(dir.."/")
	local fptitle = io.open(dir.."/TRPTITLE.DAT","rw+b")
	local fptrans = io.open(dir.."/TRPTRANS.DAT","r+b")
	local result = false

	if fptitle and fptrans then
		fptitle:seek("set", 0)
		trptitle = fptitle:read("*a")
		fptrans:seek("set", 0)
		trptrans = fptrans:read("*a")

		id = trop.trophyid

		-- obtain trophy nums and total progress
		local trophynum = trptitle:byte(NUMOFTROPHY + 1)
		local progress_offset = readBE4(trptitle, BASEPROGRESS) + GROUPSIZE
		local trophy_baseoffset1 = readBE4(trptitle, BASETROP1)
		local trophy_baseoffset2 = readBE4(trptitle, BASETROP2)

		local trophy_offset1 = trophy_baseoffset1 + (id * TRPBLOCK1)
		local trophy_offset2 = trophy_baseoffset2 + (id * TRPBLOCK2)

		local trophyblock1 = string.sub(trptitle, trophy_offset1 + 1, trophy_offset1 + TRPBLOCK1)
		local trophyblock2 = string.sub(trptitle, trophy_offset2 + 1, trophy_offset2 + TRPBLOCK2)

		--# Checks if trophy is already unlocked and synced
		--trop.unlocked = trophyblock2:byte(TROPHYSTATE+1)
		trop.synced = trophyblock2:byte(TROPHYSSYNC+1)

		-- Write unlock state
		fptitle:seek("set", trophy_offset2 + TROPHYSTATE)
		fptitle:write(string.char(UNLOCKED))

		-- Write unlock timestamp
		fptitle:seek("set", trophy_offset2 + TROPHYDATE1)
		fptitle:write(encodeTimestamp(timestamp))

		-- Write main progress
		local main_progress = trptitle:byte(progress_offset + math.floor(id/8) + 1)
		fptitle:seek("set", progress_offset + math.floor(id/8))
		fptitle:write(string.char(setbit(main_progress, id % 8)))

		-- get group progress
		local group_progress_offset = 0
		if trop.groupid == -1 then
			group_progress_offset = progress_offset + GROUPSIZE
		else
			group_progress_offset = progress_offset + (GROUPSIZE * (trop.groupid + 2))
		end

		-- Write group progress date
		fptitle:seek("set", group_progress_offset-0x10)
		fptitle:write(encodeTimestamp(timestamp))

		-- Write group progress
		local group_progress = trptitle:byte(group_progress_offset + math.floor(id/8) + 1)
		fptitle:seek("set", group_progress_offset + math.floor(id/8))
		fptitle:write(string.char(setbit(group_progress, id % 8)))
		--print(string.format("trophy group: %d, 0x%X, 0x%02X", trop.groupid, group_progress_offset, group_progress))

		-- # Gets offsets for how many trophies are in the file and where the trophy blocks are
		local trans_num_offset = readBE4(trptrans, 0x84) + 0x24
		local trans_trp_offset = readBE4(trptrans, 0xA4)

		-- Gets number of trophies in file and increases it for added trophy
		trans_num = readBE4(trptrans, trans_num_offset)

		-- increase the unlocked trophy if the trophy is not unlocked before
		if trop.unlocked == LOCKED then
			trans_num = trans_num + 1
			fptrans:seek("set", trans_num_offset)
			fptrans:write(toBE4(trans_num))
		end

		-- # Move to the next available empty block and write trophy data
		fptrans:seek("set", trans_trp_offset + (TRANBLOCK * (trans_num-1)))
		fptrans:seek("cur", 0x14)
		fptrans:write(toBE4(0X02))
		fptrans:seek("cur", 0x18)
		fptrans:write(toBE4(id))
		fptrans:write(toBE4(trop.type))
		fptrans:write(toBE4(0x2000))
		fptrans:seek("cur", 0x4)
		fptrans:write(encodeTimestamp(timestamp))

		trop.unlocked = UNLOCKED
		trop.unlocktime = encodeTimestamp(timestamp)
		trop.synced = NOTSYNCED

		result = true
	end

	if fptitle then fptitle:close()
	else os.message("no fptitle") end
	if fptrans then fptrans:close()
	else os.message("no fptrans") end

	game.umount()
	buttons.homepopup(1)

	return result
end

function lock_trophy(obj, trop)

	local dir = DATA_TROPHY..obj.npcommid
	game.umount()
	buttons.homepopup(0)
	game.mount(dir.."/")
	local fptitle = io.open(dir.."/TRPTITLE.DAT","rw+b")
	local fptrans = io.open(dir.."/TRPTRANS.DAT","r+b")
	local result = false

	if fptitle and fptrans then

		fptitle:seek("set", 0)
		trptitle = fptitle:read("*a")
		fptrans:seek("set", 0)
		trptrans = fptrans:read("*a")

		-- obtain trophy nums and total progress
		local trophynum = trptitle:byte(NUMOFTROPHY + 1)
		local progress_offset = readBE4(trptitle, BASEPROGRESS) + GROUPSIZE
		local trophy_baseoffset1 = readBE4(trptitle, BASETROP1)
		local trophy_baseoffset2 = readBE4(trptitle, BASETROP2)

		--print(tmp.ID, "trophy num:", trophynum, "total progress: ", toHex(tmp.progress))

		id = trop.trophyid

		local trophy_offset1 = trophy_baseoffset1 + (id * TRPBLOCK1)
		local trophy_offset2 = trophy_baseoffset2 + (id * TRPBLOCK2)

		local trophyblock1 = string.sub(trptitle, trophy_offset1 + 1, trophy_offset1 + TRPBLOCK1)
		local trophyblock2 = string.sub(trptitle, trophy_offset2 + 1, trophy_offset2 + TRPBLOCK2)

		--# Obtain trophy type (Bronze, Silver, Gold, Platinum)
		trop.trophy_type = trophyblock1:byte(TROPTYPE+1)

		--# Obtain group IDs of the trophies from trophy block 1 for later use
		trop.group_id = readBE4(trophyblock1, TROPGROUP)

		--# Checks if trophy is already unlocked and synced
		trop.unlocked = trophyblock2:byte(TROPHYSTATE+1)
		trop.synced = trophyblock2:byte(TROPHYSSYNC+1)

		-- Write unlock state
		fptitle:seek("set", trophy_offset2 + TROPHYSTATE)
		fptitle:write(string.char(LOCKED))
		-- Write synced state
		fptitle:seek("set", trophy_offset2 + TROPHYSSYNC)
		fptitle:write(string.char(NOTSYNCED))
		-- Write unlock timestamp & synced timestamp
		fptitle:seek("set", trophy_offset2 + TROPHYDATE1)
		fptitle:write(EMPTYDATE)
		fptitle:write(EMPTYDATE)
		-- Write main progress
		local main_progress = trptitle:byte(progress_offset + math.floor(id/8) + 1)
		fptitle:seek("set", progress_offset + math.floor(id/8))
		fptitle:write(string.char(clearbit(main_progress, id % 8)))

		-- Checks for group IDs and updates those progress bars and update dates separately
		local group_progress_offset = 0
		if trop.group_id == -1 then
			group_progress_offset = progress_offset + GROUPSIZE
		else
			group_progress_offset = progress_offset + (GROUPSIZE * (trop.group_id + 2))
		end
		local group_progress = trptitle:byte(group_progress_offset + math.floor(id/8) + 1)
		print(string.format("group progress: %x, %x, %x", trop.group_id, group_progress_offset, group_progress))
		-- Write group progress date
		fptitle:seek("set", group_progress_offset-0x10)
		fptitle:write(EMPTYDATE)
		fptitle:write(EMPTYDATE)
		-- Write group progress
		fptitle:seek("cur", math.floor(id/8))
		fptitle:write(string.char(clearbit(group_progress, id % 8)))

		-- Only process the trans if target is unlocked before
		if trop.unlocked == UNLOCKED then
			print("try lock trans")
			-- # Set offsets for how many trophies are in the file and where the trophy blocks are
			local trans_num_offset = readBE4(trptrans, 0x84) + 0x24
			local trans_trp_offset = readBE4(trptrans, 0xA4)

			print(string.format("trans offset: 0x%X, 0x%X", trans_num_offset, trans_trp_offset))
			-- Gets number of trophies in file and increases it for added trophy
			local trans_num = readBE4(trptrans, trans_num_offset)
			local trans_synced = readBE4(trptrans, trans_num_offset + 0x4)

			print(string.format("trans num: 0x%02X, 0x%02X", trans_num, trans_synced))

			-- decrease the unlocked trophy
			trans_num = trans_num - 1
			fptrans:seek("set", trans_num_offset)
			fptrans:write(toBE4(trans_num))

			-- # If there's only one trophy, prevent last synced trophy from reducing
			if trans_synced > 1 then fptrans:write(toBE4(trans_synced - 1)) end

			-- # Loop through trophy blocks looking for trophy ID to remove
			for i = 0, trans_num do
				-- # If trophy block does not match, continue loop
				--print(string.format("trans id: 0x%X, 0x%X", trans_trp_offset + (TRANBLOCK * i) + 0x30, readBE4(trptrans, trans_trp_offset + (TRANBLOCK * i) + 0x30)))
				if readBE4(trptrans, trans_trp_offset + (TRANBLOCK * i) + 0x30) == id then
					-- # When found, move each remaining entry up to prevent blank spaces
					local trans_target_offset = trans_trp_offset + (TRANBLOCK * i) + 0x15
					print(string.format("found match trans id: 0x%02X", trans_target_offset))
					fptrans:seek("set", trans_target_offset + TRANBLOCK)
					while i <= trans_num do
						local blk = fptrans:read(0x3B)
						fptrans:seek("cur", TRANBLOCK * -1 - 0x3B)
						fptrans:write(blk)
						fptrans:seek("cur", TRANBLOCK * 2 - 0x3B)
						i = i + 1
					end
					break
				end
			end

			-- # Cleanup final block to ensure it's empty
			fptrans:write(EMPTYDATE)
		end

		trop.unlocked = LOCKED
		trop.unlocktime = EMPTYDATE
		trop.synced = NOTSYNCED

		result = true
	end

	if fptitle then fptitle:close()
	else os.message("no fptitle") end
	if fptrans then fptrans:close()
	else os.message("no fptrans") end

	game.umount()
	buttons.homepopup(1)
	return result
end

function modify_start(trop)
	editing.status = true
	editing.position = 1
	local stime = decodeTimestamp(trop.unlocktime)
	local ptime = stime and os.date("*t", stime) or os.date("*t")
	editing.values = {
		trophies_type.win[trop.unlocked + 1],
		ptime.year,
		ptime.month,
		ptime.day,
		ptime.hour,
		ptime.min,
		ptime.sec
	}
end

function modify_control(obj, trop)

	if buttons[accept] then
		editing.status = false
		if editing.values[1] == trophies_type.win[2] then
			-- unlock trophy (or edit timestamp)
			if os.message(STRING_CONFIRM_UNLOCK, 1) == 1 then
				local ts = os.time({
					year = editing.values[2],
					month = editing.values[3],
					day = editing.values[4],
					hour = editing.values[5],
					min = editing.values[6],
					sec = editing.values[7]
				})
				if (unlock_trophy(obj, trop, ts)) then
					files.delete(TROP_TROPHY)
					os.message(STRING_UNLOCKED)
				end
			end
		else
			-- lock
			if trop.unlocked == 1 and os.message(STRING_CONFIRM_LOCK, 1) == 1 then
				if (lock_trophy(obj, trop)) then
					files.delete(TROP_TROPHY)
					os.message(STRING_LOCKED)
				end
			end
		end
	elseif buttons[cancel] then
		-- cancel editing
		editing.status = false
		buttons.read()
	elseif buttons.left then
		-- move editing position
		editing.position = editing.position - 1
		if editing.position == 0 then editing.position = 7 end
	elseif buttons.right then
		-- move editing position
		editing.position = editing.position + 1
		if editing.position == 8 then editing.position = 1 end
	elseif buttons.up then
		-- change values
		if editing.position == 1 then
			-- lock / unlock
			if editing.values[1] == trophies_type.win[2] then
				editing.values[1] = trophies_type.win[1]
			else editing.values[1] = trophies_type.win[2] end
		else
			-- date
			local value = editing.values[editing.position] + 1
			if editing.position ==2 then
				-- year, limit to prevent convert overflow
				if value > 2400 then value = 1980 end
			elseif editing.position ==3 then
				-- month
				if value > 12 then value = 1 end
			elseif editing.position ==4 then
				-- day
				local maxd = maxDayOfMonth(editing.values[2], editing.values[3])
				if (value > maxd) then value = 1 end
			elseif editing.position ==5 then
				if value > 23 then value = 0 end
			else
				if value > 59 then value = 0 end
			end
			editing.values[editing.position] = value
		end
	elseif buttons.down then
		-- change values
		if editing.position == 1 then
			-- lock / unlock
			if editing.values[1] == trophies_type.win[2] then
				editing.values[1] = trophies_type.win[1]
			else editing.values[1] = trophies_type.win[2] end
		else
			-- date
			local value = editing.values[editing.position] - 1
			if editing.position ==2 then
				-- year, limit to prevent convert overflow
				if value < 1980 then value = 2400 end
			elseif editing.position ==3 then
				-- month
				if value == 0 then value = 12 end
			elseif editing.position ==4 then
				-- day
				if (value == 0) then value = maxDayOfMonth(editing.values[2], editing.values[3]) end
			elseif editing.position ==5 then
				if value < 0 then value = 23 end
			else
				if value < 0 then value = 59 end
			end
			editing.values[editing.position] = value
		end
	end
end