/ai/advanced/

	objective_delay = 10
	attack_delay = 1

	var/should_find_weapon = TRUE //Set to true if you want this AI to find a weapon if it has none.
	var/checked_weapons = FALSE

	var/obj/item/weapon/objective_weapon
	var/attack_delay_left
	var/attack_delay_right

	var/next_complex = 0

	var/resist_handcuffs = TRUE

/ai/advanced/Destroy()
	objective_weapon = null
	return ..()


/ai/advanced/on_life()

	if(is_advanced(owner))
		var/mob/living/advanced/A = owner
		if(resist_handcuffs && A.handcuffed && owner.next_resist <= world.time)
			owner.resist()

	return ..()

/ai/advanced/proc/handle_movement_weapon()

	if(!is_advanced(owner))
		return FALSE

	var/mob/living/advanced/A = owner
	if(A.right_item || A.left_item || !should_find_weapon)
		return FALSE

	var/list/possible_items = list()
	for(var/obj/item/I in A.held_objects)
		if(istype(I,/obj/item/weapon/))
			possible_items += I

	if(length(possible_items))
		var/obj/item/I = pick(possible_items)
		equip_weapon(I)
		return FALSE

	if(!objective_weapon || !isturf(objective_weapon.loc) || get_dist(A,objective_weapon.loc) > 6)
		var/list/possible_weapons = list()
		for(var/obj/item/weapon/W in view(6,A))
			if(istype(W,/obj/item/weapon/ranged/))
				var/obj/item/weapon/ranged/R = W
				if(!R.firing_pin || R.firing_pin != A.iff_tag)
					continue
			if(istype(W,/obj/item/weapon/ranged/bullet/))
				var/obj/item/weapon/ranged/bullet/B = W
				if(!B.chambered_bullet)
					continue
			if(!isturf(W.loc))
				continue
			possible_weapons[W] = max(1,(6 + 1) - get_dist(A,W.loc))
		if(!length(possible_weapons))
			return FALSE
		objective_weapon = pickweight(possible_weapons)

	if(get_dist(A,objective_weapon) > 1)
		A.move_dir = get_dir(owner,objective_weapon)
		return TRUE

	equip_weapon(objective_weapon)

	return FALSE

/ai/advanced/proc/handle_gunplay()

	var/mob/living/advanced/A = owner
	if(istype(A.left_item,/obj/item/weapon/ranged/))
		if(!handle_gun(A.left_item))
			return FALSE
	if(istype(A.right_item,/obj/item/weapon/ranged/))
		if(!handle_gun(A.right_item))
			return FALSE

	return TRUE

/ai/advanced/proc/handle_gun(var/obj/item/weapon/ranged/R)

	var/mob/living/advanced/A = owner

	if(istype(R,/obj/item/weapon/ranged/bullet/magazine/))
		var/obj/item/weapon/ranged/bullet/magazine/G = R
		if(!G.stored_magazine && !G.chambered_bullet) //Find one
			if(G.wielded) //We should unwield
				A.left_hand.wield_object(A,G) //Also unwields
			next_complex = world.time + 15
			var/obj/item/magazine/M
			var/obj/item/organ/O_groin = A.labeled_organs[BODY_GROIN]
			if(O_groin)
				M = recursive_find_item(O_groin,G,/obj/item/weapon/ranged/bullet/magazine/proc/can_fit_magazine)
			if(!M)
				unequip_weapon(G)
				return FALSE
			M.click_on_object(A,G)
			if(!G.stored_magazine)
				unequip_weapon(G)
				return FALSE
			if(G.can_wield && !G.wielded && A.left_hand && !A.left_item)
				A.left_hand.wield_object(A,G)
			return FALSE

		if(G.stored_magazine && !length(G.stored_magazine.stored_bullets) && !G.chambered_bullet)
			G.eject_magazine(A)
			next_complex = world.time + 10
			return FALSE

		if(!G.chambered_bullet || G.chambered_bullet.is_spent)
			G.click_self(A)
			if(!G.chambered_bullet)
				unequip_weapon(G)
				return FALSE
			next_complex = world.time + 5
			return FALSE

	return TRUE




/ai/advanced/handle_movement()

	if(handle_movement_weapon())
		return TRUE

	return ..()


/ai/advanced/do_attack(var/atom/target,var/left_click=FALSE)

	if(!is_advanced(owner))
		return ..()

	if(next_complex > world.time)
		return FALSE

	var/mob/living/advanced/A = owner

	if(!handle_gunplay())
		return FALSE

	var/list/params = list(
		PARAM_ICON_X = num2text(pick(target_distribution_x)),
		PARAM_ICON_Y = num2text(pick(target_distribution_y)),
		"left" = 0,
		"right" = 0,
		"middle" = 0,
		"ctrl" = 0,
		"shift" = 0,
		"alt" = 0
	)

	var/atom/defer_left_click = A.left_hand?.defer_click_on_object(null,null,params)
	var/atom/defer_right_click = A.right_hand?.defer_click_on_object(null,null,params)

	var/list/possible_attacks = list()

	if(defer_right_click && owner.can_attack(target,defer_right_click,params,null))
		possible_attacks += defer_right_click

	if(defer_left_click && owner.can_attack(target,defer_left_click,params,null))
		possible_attacks += defer_left_click

	if(!length(possible_attacks))
		return FALSE

	var/atom/W = pick(possible_attacks)
	W.click_on_object(A,target,null,null,params)

	return TRUE



/*
/ai/advanced/can_attack(var/atom/target,var/left_click=FALSE)

	ranged_attack_cooldown = max(0,ranged_attack_cooldown - 1)

	if(!is_advanced(owner))
		return ..()

	var/mob/living/advanced/A = owner
	if(!left_click)
		if(A.left_item && is_ranged_gun(A.left_item) && !can_fire_gun(A.left_item,target))
			return FALSE
	else
		if(A.right_item && is_ranged_gun(A.right_item) && !can_fire_gun(A.right_item,target))
			return FALSE

	return ..()

/ai/advanced/proc/can_fire_gun(var/obj/item/weapon/ranged/R,var/atom/target)

	if(ranged_attack_cooldown > 0)
		return FALSE

	var/distance_mod = get_dist(owner,target)
	var/heat_limit = max(0,(1 - (distance_mod * 0.01)) * R.heat_max)

	return R.heat_current <= heat_limit


/ai/advanced/do_attack(var/atom/target,var/left_click=FALSE)

	. = ..()

	if(.)
		ranged_attack_cooldown = pick(TRUE,FALSE,FALSE,FALSE,FALSE) ? rand(10,20) : 0

	return .
*/

/ai/advanced/proc/find_best_weapon()

	var/mob/living/advanced/A = owner

	var/obj/item/weapon/best_weapon
	var/best_weapon_value = -1

	for(var/obj/item/weapon/W in A.worn_objects)
		if(istype(W,/obj/item/weapon/ranged/bullet/magazine/))
			var/obj/item/weapon/ranged/bullet/magazine/M = W
			if(!M.stored_magazine)
				continue
		if(!best_weapon || !best_weapon_value)
			best_weapon = W
			best_weapon_value = W.calculate_value() * (istype(W,/obj/item/weapon/ranged) ? 3 : 1)
			continue

		var/weapon_value = W.calculate_value() * (istype(W,/obj/item/weapon/ranged) ? 3 : 1)
		if(weapon_value > best_weapon_value)
			best_weapon = W
			continue

	for(var/obj/item/weapon/W in A.held_objects)
		if(istype(W,/obj/item/weapon/ranged/bullet/magazine/))
			var/obj/item/weapon/ranged/bullet/magazine/M = W
			if(!M.stored_magazine)
				continue
		if(!best_weapon || !best_weapon_value)
			best_weapon = W
			best_weapon_value = W.calculate_value() * (istype(W,/obj/item/weapon/ranged) ? 3 : 1)
			continue

		var/weapon_value = W.calculate_value() * (istype(W,/obj/item/weapon/ranged) ? 3 : 1)
		if(weapon_value > best_weapon_value)
			best_weapon = W
			continue

	return best_weapon

/ai/advanced/proc/equip_weapon(var/obj/item/weapon/W)

	var/mob/living/advanced/A = owner

	. = FALSE

	if(A.right_hand && !A.right_item)
		A.right_hand.add_held_object(W,FALSE)
		. = TRUE
		if(W.can_wield && !W.wielded && A.left_hand && !A.left_item)
			A.left_hand.wield_object(A,W)

	else if(A.left_hand && !A.left_hand.parent_inventory && !A.left_item)
		A.left_hand.add_held_object(W,FALSE)
		. = TRUE

	if(. && istype(W,/obj/item/weapon/melee/energy))
		var/obj/item/weapon/melee/energy/E = W
		if(!E.enabled) E.click_self(A)

	return .

/ai/advanced/proc/unequip_weapon(var/obj/item/weapon/W)
	var/mob/living/advanced/A = owner
	if(istype(W,/obj/item/weapon/melee/energy))
		var/obj/item/weapon/melee/energy/E = W
		if(E.enabled) E.click_self(A)
	if(!W.quick_equip(A))
		W.drop_item(get_turf(owner))
	return TRUE

/ai/advanced/on_alert_level_changed(var/old_alert_level,var/new_alert_level,var/atom/alert_source)

	if(!is_advanced(owner))
		return ..()

	var/mob/living/advanced/A = owner

	if(new_alert_level == ALERT_LEVEL_COMBAT || new_alert_level == ALERT_LEVEL_CAUTION)
		if(!A.left_item && !A.right_item)
			var/obj/item/weapon/W = find_best_weapon()
			if(W) equip_weapon(W)
	else
		if(A.right_item)
			unequip_weapon(A.right_item)
		if(A.left_item)
			unequip_weapon(A.left_item)

	return ..()

/ai/advanced/handle_attacking()

	if(!is_advanced(owner))
		return ..()

	var/mob/living/advanced/A = owner

	distance_target_min = 1
	distance_target_max = 1
	attack_distance_min = 1
	attack_distance_max = 1

	if(A.right_item && A.left_item)
		left_click_chance = 50
		if(is_ranged_gun(A.right_item))
			distance_target_min = VIEW_RANGE * 0.5
			distance_target_max = VIEW_RANGE + ZOOM_RANGE
			attack_distance_min = 1
			attack_distance_max = 8
			if(!is_ranged_gun(A.left_item))
				left_click_chance = 100
		else if(is_ranged_gun(A.left_item))
			distance_target_min = VIEW_RANGE * 0.5
			distance_target_max = VIEW_RANGE + ZOOM_RANGE
			attack_distance_min = 1
			attack_distance_max = 8
			left_click_chance = 0
	else if(A.right_item)
		left_click_chance = 100
		if(is_ranged_gun(A.right_item))
			distance_target_min = VIEW_RANGE * 0.5
			distance_target_max = VIEW_RANGE + ZOOM_RANGE
			attack_distance_min = 1
			attack_distance_max = 8
	else if(A.left_item)
		left_click_chance = 0
		if(is_ranged_gun(A.left_item))
			distance_target_min = VIEW_RANGE * 0.5
			distance_target_max = VIEW_RANGE + ZOOM_RANGE
			attack_distance_min = 1
			attack_distance_max = 8

	return ..()