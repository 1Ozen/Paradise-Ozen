/client/proc/cmd_admin_say(msg as text)
	set name = "Asay" //Gave this shit a shorter name so you only have to time out "asay" rather than "admin say" to use it --NeoFite
	set hidden = 1
	if(!check_rights(R_ADMIN))	return

	msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
	if(!msg)	return

	msg = handleDiscordEmojis(msg)

	var/datum/asays/asay = new(usr.ckey, usr.client.holder.rank, msg, world.timeofday)
	GLOB.asays += asay
	log_adminsay(msg, src)

	if(check_rights(R_ADMIN,0))
		for(var/client/C in GLOB.admins)
			if(R_ADMIN & C.holder.rights)
				// Lets see if this admin was pinged in the asay message
				if(findtext(msg, "@[C.ckey]") || findtext(msg, "@[C.key]")) // Check ckey and key, so you can type @AffectedArc07 or @affectedarc07
					SEND_SOUND(C, 'sound/misc/ping.ogg')
					msg = replacetext(msg, "@[C.ckey]", "<font color='red'>@[C.ckey]</font>")
					msg = replacetext(msg, "@[C.key]", "<font color='red'>@[C.key]</font>") // Same applies here. key and ckey.

				msg = "<span class='emoji_enabled'>[msg]</span>"
				to_chat(C, "<span class='admin_channel'>ADMIN: <span class='name'>[key_name(usr, 1)]</span> ([admin_jump_link(mob)]): <span class='message'>[msg]</span></span>", MESSAGE_TYPE_ADMINCHAT, confidential = TRUE)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Asay") //If you are copy-pasting this, ensure the 4th parameter is unique to the new proc!

/client/proc/get_admin_say()
	if(check_rights(R_ADMIN, FALSE))
		var/msg = input(src, null, "asay \"text\"") as text|null
		cmd_admin_say(msg)
	else if(check_rights(R_MENTOR))
		var/msg = input(src, null, "msay \"text\"") as text|null
		cmd_mentor_say(msg)

/client/proc/cmd_mentor_say(msg as text)
	set name = "Msay"
	set hidden = 1

	if(!check_rights(R_ADMIN|R_MOD|R_MENTOR))
		return

	msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
	log_mentorsay(msg, src)

	if(!msg)
		return

	msg = handleDiscordEmojis(msg)

	for(var/client/C in GLOB.admins)
		if(check_rights(R_ADMIN|R_MOD|R_MENTOR, 0, C.mob))
			var/display_name = key
			if(holder.fakekey)
				if(C.holder && C.holder.rights & R_ADMIN)
					display_name = "[holder.fakekey]/([key])"
				else
					display_name = holder.fakekey
			msg = "<span class='emoji_enabled'>[msg]</span>"
			to_chat(C, "<span class='[check_rights(R_ADMIN, 0) ? "mentor_channel_admin" : "mentor_channel"]'>MENTOR: <span class='name'>[display_name]</span> ([admin_jump_link(mob)]): <span class='message'>[msg]</span></span>", MESSAGE_TYPE_MENTORCHAT, confidential = TRUE)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Msay") //If you are copy-pasting this, ensure the 4th parameter is unique to the new proc!

/client/proc/get_mentor_say()
	if(check_rights(R_MENTOR | R_ADMIN | R_MOD))
		var/msg = input(src, null, "msay \"text\"") as text|null
		cmd_mentor_say(msg)

/client/proc/toggle_mentor_chat()
	set category = "Server"
	set name = "Toggle Mentor Chat"
	set desc = "Toggle whether mentors have access to the msay command"

	if(!check_rights(R_ADMIN))
		return

	var/enabling
	var/msay = /client/proc/cmd_mentor_say

	if(msay in GLOB.admin_verbs_mentor)
		enabling = FALSE
		GLOB.admin_verbs_mentor -= msay
	else
		enabling = TRUE
		GLOB.admin_verbs_mentor += msay

	for(var/client/C in GLOB.admins)
		if(check_rights(R_ADMIN|R_MOD, 0, C.mob))
			continue
		if(!check_rights(R_MENTOR, 0, C.mob))
			continue
		if(enabling)
			add_verb(C, msay)
			to_chat(C, "<b>Mentor chat has been enabled.</b> Use 'msay' to speak in it.")
		else
			remove_verb(C, msay)
			to_chat(C, "<b>Mentor chat has been disabled.</b>")

	log_and_message_admins("toggled mentor chat [enabling ? "on" : "off"].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggle Msay")
