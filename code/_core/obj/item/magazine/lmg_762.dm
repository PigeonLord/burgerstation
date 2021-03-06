/obj/item/magazine/lmg_762
	name = "\improper 7.62mm drum magazine."
	icon = 'icons/obj/items/magazine/762_lmg.dmi'
	icon_state = "lmg"
	bullet_count_max = 40

	weapon_whitelist = list(
		/obj/item/weapon/ranged/bullet/magazine/rifle/nt_lmg = TRUE
	)

	ammo = /obj/item/bullet_cartridge/rifle_308/nato

	bullet_length_min = 46
	bullet_length_best = 51
	bullet_length_max = 52

	bullet_diameter_min = 7.6
	bullet_diameter_best = 7.62
	bullet_diameter_max = 7.7

	size = SIZE_3
	weight = WEIGHT_3

/obj/item/magazine/lmg_762/update_icon()
	icon_state = "[initial(icon_state)]_[length(stored_bullets) ? 1 : 0]"
	return ..()