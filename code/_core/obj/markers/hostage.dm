var/global/list/possible_hostage_spawns = list()


var/global/list/possible_hostage_types = list(
	/mob/living/advanced/npc/unique/hostage/bar_shaleez,
	/mob/living/advanced/npc/unique/hostage/diamond_with_flaw,
	/mob/living/advanced/npc/unique/hostage/marwani,
	/mob/living/advanced/npc/unique/hostage/assistant
)

/obj/marker/hostage_spawn
	name = "possible hostage spawn"

/obj/marker/hostage_spawn/New(var/desired_loc)
	possible_hostage_spawns += src
	return ..()


/obj/marker/hostage_spawn/proc/spawn_hostage()

	return TRUE